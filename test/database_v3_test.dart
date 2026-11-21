// v1.1.0: Database migration + fee/marks logic ki ASLI database test.
//
// Yeh sqflite_common_ffi se asal SQLite DB banata hai (in-memory nahi, temp
// file pe), taake `_onUpgrade` ka har qadam verify ho — pichla bug bilkul
// yahin tha (onUpgrade maujood hi nahi tha, is liye purani install pe kuch
// nahi badla).
//
// path_provider ko mock kiya gaya hai kyunke plain Dart test mein platform
// channel nahi hota.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';

/// Temp directory jo path_provider ki jagah return hoti hai.
late Directory _docDir;

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // path_provider ka channel mock — DatabaseHelper isi se DB path banata hai.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      if (call.method == 'getApplicationDocumentsDirectory' ||
          call.method == 'getApplicationSupportDirectory') {
        return _docDir.path;
      }
      return null;
    },
  );

  setUp(() async {
    _docDir = await Directory.systemTemp.createTemp('sms_db_test_');
    await DatabaseHelper().close();
  });

  tearDown(() async {
    await DatabaseHelper().close();
    if (await _docDir.exists()) await _docDir.delete(recursive: true);
  });

  group('Fresh install (v3)', () {
    test('DB v3 pe banti hai aur nayi tables maujood hain', () async {
      final db = await DatabaseHelper().db;
      expect(await db.getVersion(), 3);

      for (final t in [
        'classes',
        'class_subjects',
        'exam_subjects',
        'fee_payments',
      ]) {
        final exists = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            [t]);
        expect(exists, isNotEmpty, reason: '$t table honi chahiye');
      }
    });

    test('classes seed hoti hain (Nursery se 10th), fee 0', () async {
      final db = await DatabaseHelper().db;
      final rows = await db.query('classes');
      expect(rows.length, 12);
      final names = rows.map((r) => r['name'] as String).toSet();
      expect(names, containsAll(['Nursery', 'KG', '1st', '10th']));
      for (final r in rows) {
        expect(((r['monthly_fee'] ?? 0) as num).toDouble(), 0,
            reason: 'Fee jaan boojh kar khaali chhori gayi hai');
      }
    });

    test('purana seed data barkarar: 5 teachers, 40 students', () async {
      final db = await DatabaseHelper().db;
      final t = await db.rawQuery('SELECT COUNT(*) FROM teachers');
      final s = await db.rawQuery('SELECT COUNT(*) FROM students');
      expect(Sqflite.firstIntValue(t), 5);
      expect(Sqflite.firstIntValue(s), 40);
    });
  });

  group('v2 -> v3 migration (purani install)', () {
    /// Purani (v2) DB banate hain — sirf woh tables jo migration chhedti hai.
    Future<void> makeV2Db() async {
      final path = '${_docDir.path}/school_management.db';
      final db = await openDatabase(path, version: 2, onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE students(
            id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
            roll_no TEXT, class_name TEXT, section TEXT, phone TEXT,
            parent_name TEXT, parent_phone TEXT, address TEXT,
            admission_date TEXT, photo_path TEXT,
            is_active INTEGER NOT NULL DEFAULT 1)
        ''');
        await d.execute('''
          CREATE TABLE exams(
            id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
            class_name TEXT, start_date TEXT, end_date TEXT)
        ''');
        await d.execute('''
          CREATE TABLE marks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL, exam_id INTEGER NOT NULL,
            subject TEXT, marks_obtained REAL DEFAULT 0,
            total_marks REAL DEFAULT 100)
        ''');
        await d.execute('''
          CREATE TABLE fees(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL, month TEXT, amount REAL DEFAULT 0,
            due_date TEXT, amount_paid REAL DEFAULT 0,
            status TEXT DEFAULT 'Pending', paid_date TEXT)
        ''');
        // Purana data
        await d.insert('students', {
          'name': 'Purana Student',
          'roll_no': '900',
          'class_name': '5th',
          'section': 'A',
          'parent_name': 'P',
          'parent_phone': '0300',
          'admission_date': '2024-04-01',
        });
        await d.insert('exams', {
          'name': 'Mid Term 2025',
          'class_name': '5th',
          'start_date': '2025-10-01',
          'end_date': '2025-10-05',
        });
        await d.insert('fees', {
          'student_id': 1,
          'month': '2025-09',
          'amount': 1500,
          'amount_paid': 1500,
          'status': 'Paid',
          'paid_date': '2025-09-05',
        });
        await d.insert('fees', {
          'student_id': 1,
          'month': '2025-10',
          'amount': 1500,
          'amount_paid': 0,
          'status': 'Pending',
        });
      });
      await db.close();
    }

    test('onUpgrade chalta hai: version 2 se 3', () async {
      await makeV2Db();
      final db = await DatabaseHelper().db;
      expect(await db.getVersion(), 3);
    });

    test('exams mein exam_type column add hota hai (default Mid Term)',
        () async {
      await makeV2Db();
      final db = await DatabaseHelper().db;
      final info = await db.rawQuery('PRAGMA table_info(exams)');
      expect(info.any((r) => r['name'] == 'exam_type'), isTrue);
      final rows = await db.query('exams');
      expect(rows.first['exam_type'], 'Mid Term');
    });

    test(
        'students mein fee_start_month add hota hai aur IS mahine se set hota '
        'hai (backfill nahi — user ki pasand)', () async {
      await makeV2Db();
      final db = await DatabaseHelper().db;
      final info = await db.rawQuery('PRAGMA table_info(students)');
      expect(info.any((r) => r['name'] == 'fee_start_month'), isTrue);

      final now = DateTime.now();
      final expected = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final rows = await db.query('students');
      expect(rows.first['fee_start_month'], expected,
          reason: 'Admission 2024-04 tha magar hisaab is mahine se shuru hoga');
    });

    test('purani fees ki jama raqam fee_payments mein migrate hoti hai',
        () async {
      await makeV2Db();
      final db = await DatabaseHelper().db;
      final payments = await db.query('fee_payments');
      // Sirf woh row migrate honi chahiye jis mein amount_paid > 0 tha.
      expect(payments.length, 1);
      expect(payments.first['month'], '2025-09');
      expect(((payments.first['amount']) as num).toDouble(), 1500);
      expect(payments.first['note'], 'Purane record se migrate hua');
    });

    test('purana data (students/exams) ghayab nahi hota', () async {
      await makeV2Db();
      final db = await DatabaseHelper().db;
      final s = await db.query('students', where: "roll_no = '900'");
      expect(s.length, 1);
      expect(s.first['name'], 'Purana Student');
      final e = await db.query('exams');
      expect(e.length, 1);
      expect(e.first['name'], 'Mid Term 2025');
    });

    test('migration dobara chalane pe duplicate nahi banti (idempotent)',
        () async {
      await makeV2Db();
      final db = await DatabaseHelper().db;
      expect(await db.getVersion(), 3);
      await DatabaseHelper().close();

      // Dobara kholo — onUpgrade dobara nahi chalega, magar seed idempotent hai.
      final db2 = await DatabaseHelper().db;
      final classes = await db2.query('classes');
      expect(classes.length, 12, reason: 'Classes duplicate nahi honi chahiye');
      final payments = await db2.query('fee_payments');
      expect(payments.length, 1);
    });
  });

  group('Class settings CRUD', () {
    test('class add, fee set, subjects add/update/delete', () async {
      final db = await DatabaseHelper().db;
      await db.update('classes', {'monthly_fee': 2500}, where: "name = '10th'");

      final c = await DatabaseHelper().getSchoolClassByName('10th');
      expect(c, isNotNull);
      expect(c!.monthlyFee, 2500);

      await DatabaseHelper().upsertClassSubject(ClassSubject(
        className: '10th',
        subject: 'Math',
        totalMarks: 100,
        midMarks: 50,
        finalMarks: 100,
      ));
      // Upsert: dobara save pe duplicate nahi, update ho jata hai.
      await DatabaseHelper().upsertClassSubject(ClassSubject(
        className: '10th',
        subject: 'Math',
        totalMarks: 100,
        midMarks: 60,
        finalMarks: 100,
      ));
      var subs = await DatabaseHelper().getClassSubjects('10th');
      expect(subs.length, 1);
      expect(subs.first.midMarks, 60);

      await DatabaseHelper().upsertClassSubject(
          ClassSubject(className: '10th', subject: 'Physics', totalMarks: 75));
      subs = await DatabaseHelper().getClassSubjects('10th');
      expect(subs.length, 2);

      await DatabaseHelper().deleteClassSubject(subs.last.id!);
      subs = await DatabaseHelper().getClassSubjects('10th');
      expect(subs.length, 1);
    });

    test('getClasses union hai: classes table + students ki asal classes',
        () async {
      final db = await DatabaseHelper().db;
      // Ek aisi class jo students mein hai magar classes table mein nahi.
      await db.insert('students', {
        'name': 'Extra',
        'roll_no': '999',
        'class_name': 'Special Batch',
        'parent_name': 'P',
        'parent_phone': '0300',
      });
      final classes = await DatabaseHelper().getClasses();
      expect(classes, contains('1st'));
      expect(classes, contains('Special Batch'));
      // Tarteeb: Nursery pehle, 10th us ke baad, na-maloom sab se aakhir.
      expect(classes.indexOf('Nursery'), lessThan(classes.indexOf('1st')));
      expect(classes.indexOf('1st'), lessThan(classes.indexOf('10th')));
      expect(classes.last, 'Special Batch');
    });
  });

  group('Marks upsert', () {
    test('dobara save pe duplicate row nahi banti, value update hoti hai',
        () async {
      final db = await DatabaseHelper().db;
      final mark = Mark(
          studentId: 1,
          examId: 1,
          subject: 'Math',
          marksObtained: 40,
          totalMarks: 100);
      await DatabaseHelper().upsertMark(Mark(
          studentId: 1,
          examId: 1,
          subject: 'Math',
          marksObtained: 40,
          totalMarks: 100));
      await DatabaseHelper().upsertMark(mark);
      await DatabaseHelper().upsertMark(Mark(
          studentId: 1,
          examId: 1,
          subject: 'Math',
          marksObtained: 55,
          totalMarks: 100));

      final rows = await db.query('marks');
      expect(rows.length, 1, reason: 'Sirf ek row honi chahiye');
      expect(((rows.first['marks_obtained']) as num).toDouble(), 55);
    });

    test('getMarksByStudentForExam student ke hisaab se group karta hai',
        () async {
      await DatabaseHelper().upsertMark(Mark(
          studentId: 1,
          examId: 7,
          subject: 'Math',
          marksObtained: 40,
          totalMarks: 100));
      await DatabaseHelper().upsertMark(Mark(
          studentId: 1,
          examId: 7,
          subject: 'English',
          marksObtained: 30,
          totalMarks: 100));
      await DatabaseHelper().upsertMark(Mark(
          studentId: 2,
          examId: 7,
          subject: 'Math',
          marksObtained: 50,
          totalMarks: 100));
      await DatabaseHelper().upsertMark(Mark(
          studentId: 3,
          examId: 8,
          subject: 'Math',
          marksObtained: 10,
          totalMarks: 100));

      final byStudent = await DatabaseHelper().getMarksByStudentForExam(7);
      expect(byStudent.keys.toSet(), {1, 2});
      expect(byStudent[1]!.length, 2);
      expect(byStudent[2]!.length, 1);
    });
  });

  group('Exam subjects', () {
    test('replaceExamSubjects poori list replace karta hai', () async {
      final examId = await DatabaseHelper().insertExam(Exam(
        name: 'Mid 2026',
        className: '10th',
        startDate: '2026-11-01',
        endDate: '2026-11-10',
        examType: 'Mid Term',
      ));
      await DatabaseHelper().replaceExamSubjects(examId, [
        ExamSubject(examId: examId, subject: 'Math', totalMarks: 50),
        ExamSubject(examId: examId, subject: 'English', totalMarks: 50),
      ]);
      var subs = await DatabaseHelper().getExamSubjects(examId);
      expect(subs.length, 2);

      // Ab sirf ek subject — purane hat jayenge.
      await DatabaseHelper().replaceExamSubjects(examId, [
        ExamSubject(examId: examId, subject: 'Math', totalMarks: 60),
      ]);
      subs = await DatabaseHelper().getExamSubjects(examId);
      expect(subs.length, 1);
      expect(subs.first.subject, 'Math');
      expect(subs.first.totalMarks, 60);
    });
  });

  group('Fee ledger (asli DB se)', () {
    Future<Student> addStudent({
      String name = 'Fee Wala',
      String roll = '700',
      String className = '5th',
      String feeStart = '',
      String admission = '',
    }) async {
      final id = await DatabaseHelper().insertStudent(Student(
        name: name,
        rollNo: roll,
        className: className,
        parentName: 'P',
        parentPhone: '0300',
        admissionDate: admission,
        feeStartMonth: feeStart,
      ));
      return (await DatabaseHelper().getStudentById(id))!;
    }

    test('naye student ka fee start month admission se set hota hai', () async {
      final s = await addStudent(admission: '2026-08-15');
      expect(s.feeStartMonth, '2026-08');
    });

    test('arrears: 3 mahine, ek paid, ek partial', () async {
      final db = await DatabaseHelper().db;
      await db.update('classes', {'monthly_fee': 2000}, where: "name = '5th'");
      final s = await addStudent(feeStart: '2026-09');

      await DatabaseHelper().insertFeePayment(
          FeePayment(studentId: s.id!, month: '2026-09', amount: 2000));
      await DatabaseHelper().insertFeePayment(
          FeePayment(studentId: s.id!, month: '2026-10', amount: 1000));

      final l = await DatabaseHelper().feeLedgerFor(s);
      final now = FeeLedger.currentMonth();
      final expectedMonths = FeeLedger.monthsBetween('2026-09', now);

      expect(l.monthlyFee, 2000);
      expect(l.months.length, expectedMonths.length);
      expect(l.totalPayable, 2000 * expectedMonths.length);
      expect(l.totalPaid, 3000);
      expect(l.statusFor('2026-09'), 'Paid');
      expect(l.statusFor('2026-10'), 'Partial');
    });

    test('installments: ek hi month mein 3 payments jama hoti hain', () async {
      final db = await DatabaseHelper().db;
      await db.update('classes', {'monthly_fee': 3000}, where: "name = '5th'");
      final s = await addStudent(feeStart: '2026-11');

      for (final a in [1000.0, 1000.0, 500.0]) {
        await DatabaseHelper().insertFeePayment(FeePayment(
            studentId: s.id!, month: '2026-11', amount: a, note: 'inst'));
      }
      final l = await DatabaseHelper().feeLedgerFor(s);
      expect(l.paidFor('2026-11'), 2500);
      expect(l.balanceFor('2026-11'), 500);
      expect(l.statusFor('2026-11'), 'Partial');

      final payments = await DatabaseHelper().getFeePayments(s.id!);
      expect(payments.length, 3, reason: 'Teeno receipts mehfooz rahen');
    });

    test('class ki fee 0 ho to koi arrears nahi', () async {
      final s = await addStudent(feeStart: '2026-09');
      final l = await DatabaseHelper().feeLedgerFor(s);
      expect(l.monthlyFee, 0);
      expect(l.totalBalance, 0);
      expect(l.pendingMonthCount, 0);
    });

    test('feeOverride class ki fee se aage nikal jata hai', () async {
      final db = await DatabaseHelper().db;
      await db.update('classes', {'monthly_fee': 2000}, where: "name = '5th'");
      final s = await addStudent(feeStart: '2026-11');
      final l = await DatabaseHelper().feeLedgerFor(s, feeOverride: 1000);
      expect(l.monthlyFee, 1000);
      expect(l.balanceFor('2026-11'), 1000);
    });

    test('payment delete karne pe balance wapas barh jata hai', () async {
      final db = await DatabaseHelper().db;
      await db.update('classes', {'monthly_fee': 2000}, where: "name = '5th'");
      final s = await addStudent(feeStart: '2026-11');
      final pid = await DatabaseHelper().insertFeePayment(
          FeePayment(studentId: s.id!, month: '2026-11', amount: 2000));

      var l = await DatabaseHelper().feeLedgerFor(s);
      expect(l.isPaid('2026-11'), isTrue);

      await DatabaseHelper().deleteFeePayment(pid);
      l = await DatabaseHelper().feeLedgerFor(s);
      expect(l.balanceFor('2026-11'), 2000);
      expect(l.statusFor('2026-11'), 'Pending');
    });
  });

  group('Student search (fee screen)', () {
    test('naam se milta hai', () async {
      final r = await DatabaseHelper().searchStudents('Ali');
      expect(r, isNotEmpty);
      expect(r.every((s) => s.name.toLowerCase().contains('ali')), isTrue);
    });

    test('roll number se milta hai', () async {
      final r = await DatabaseHelper().searchStudents('101');
      expect(r, isNotEmpty);
      expect(r.any((s) => s.rollNo.contains('101')), isTrue);
    });

    test('jo nahi hai woh khali list deta hai (crash nahi)', () async {
      final r = await DatabaseHelper().searchStudents('zzz-nahi-milega');
      expect(r, isEmpty);
    });
  });
}
