// v1.1.0: Class settings aur fee ledger ki tests.
//
// FeeLedger poori fee screen ka hisaab karti hai (arrears, installments,
// partial payments), is liye iski har shaakh test ki gayi hai. Yeh pure Dart
// hai — koi DB ya platform channel nahi chahiye.
import 'package:flutter_test/flutter_test.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';

void main() {
  group('FeeLedger.monthsBetween', () {
    test('ek hi mahina', () {
      expect(FeeLedger.monthsBetween('2026-11', '2026-11'), ['2026-11']);
    });

    test('kai mahine', () {
      expect(FeeLedger.monthsBetween('2026-09', '2026-11'),
          ['2026-09', '2026-10', '2026-11']);
    });

    test('saal badalne pe sahi chalta hai', () {
      expect(FeeLedger.monthsBetween('2025-11', '2026-02'),
          ['2025-11', '2025-12', '2026-01', '2026-02']);
    });

    test('future start ho to khali list (ghalat arrears na bane)', () {
      expect(FeeLedger.monthsBetween('2027-01', '2026-11'), isEmpty);
    });

    test('ghalat format pe khali list (crash nahi)', () {
      expect(FeeLedger.monthsBetween('abc', '2026-11'), isEmpty);
      expect(FeeLedger.monthsBetween('2026-13', '2026-11'), isEmpty);
      expect(FeeLedger.monthsBetween('', ''), isEmpty);
    });
  });

  group('FeeLedger hisaab', () {
    // 3 mahine, Rs 2000 monthly.
    final l = FeeLedger(
      monthlyFee: 2000,
      months: ['2026-09', '2026-10', '2026-11'],
      payments: {'2026-09': 2000, '2026-10': 1000},
    );

    test('payable / paid / balance totals', () {
      expect(l.totalPayable, 6000);
      expect(l.totalPaid, 3000);
      expect(l.totalBalance, 3000);
    });

    test('month ka status: Paid / Partial / Pending', () {
      expect(l.statusFor('2026-09'), 'Paid');
      expect(l.statusFor('2026-10'), 'Partial');
      expect(l.statusFor('2026-11'), 'Pending');
      expect(l.isPaid('2026-09'), isTrue);
      expect(l.isPartial('2026-10'), isTrue);
    });

    test('pending months aur unki ginti', () {
      expect(l.pendingMonths, ['2026-10', '2026-11']);
      expect(l.pendingMonthCount, 2);
    });

    test('per-month balance', () {
      expect(l.balanceFor('2026-09'), 0);
      expect(l.balanceFor('2026-10'), 1000);
      expect(l.balanceFor('2026-11'), 2000);
    });

    test('zyada payment (advance) negative balance deti hai, "Paid" rehta hai',
        () {
      final over = FeeLedger(
        monthlyFee: 2000,
        months: ['2026-11'],
        payments: {'2026-11': 2500},
      );
      expect(over.isPaid('2026-11'), isTrue);
      expect(over.statusFor('2026-11'), 'Paid');
      expect(over.balanceFor('2026-11'), -500);
      expect(over.pendingMonthCount, 0);
    });

    test('fee 0 ho to sab clear', () {
      final free = FeeLedger(
        monthlyFee: 0,
        months: ['2026-10', '2026-11'],
        payments: {},
      );
      expect(free.totalBalance, 0);
      expect(free.pendingMonthCount, 0);
      expect(free.statusFor('2026-11'), 'Paid');
    });

    test('installments: ek hi month mein kai payments jama hoti hain', () {
      // DB level pe fee_payments ki multiple rows aati hain; ledger unhe
      // month ke against jama karti hai (DatabaseHelper.feeLedgerFor mein).
      final inst = FeeLedger(
        monthlyFee: 3000,
        months: ['2026-11'],
        payments: {'2026-11': 1000 + 1000 + 500},
      );
      expect(inst.paidFor('2026-11'), 2500);
      expect(inst.balanceFor('2026-11'), 500);
      expect(inst.statusFor('2026-11'), 'Partial');
    });
  });

  group('FeeLedger.monthLabel', () {
    test('YYYY-MM se readable label', () {
      expect(FeeLedger.monthLabel('2026-11'), 'Nov 2026');
      expect(FeeLedger.monthLabel('2026-01'), 'Jan 2026');
      expect(FeeLedger.monthLabel('2026-12'), 'Dec 2026');
    });

    test('ghalat input pe wahi string wapas (crash nahi)', () {
      expect(FeeLedger.monthLabel('kuch-bhi'), 'kuch-bhi');
      expect(FeeLedger.monthLabel('2026-13'), '2026-13');
      expect(FeeLedger.monthLabel('2026-00'), '2026-00');
    });
  });

  group('FeeLedger.currentMonth', () {
    test('YYYY-MM format, zero-padded', () {
      expect(FeeLedger.currentMonth(DateTime(2026, 1, 5)), '2026-01');
      expect(FeeLedger.currentMonth(DateTime(2026, 11, 20)), '2026-11');
    });
  });

  group('ClassSubject.totalFor', () {
    final cs = ClassSubject(
      className: '10th',
      subject: 'Math',
      totalMarks: 100,
      midMarks: 50,
      finalMarks: 100,
      weeklyMarks: 0,
      monthlyMarks: 25,
    );

    test('har exam type ka apna total', () {
      expect(cs.totalFor('Mid Term'), 50);
      expect(cs.totalFor('Final Term'), 100);
      expect(cs.totalFor('Monthly Test'), 25);
    });

    test('jis type ka total set nahi (0) woh default total pe girta hai', () {
      // Weekly 0 hai, is liye 100 (default) chalega — warna marks "0 ke out of"
      // enter hone lagte aur percentage NaN/broken banta.
      expect(cs.totalFor('Weekly Test'), 100);
    });

    test('unknown exam type pe mid marks (default)', () {
      expect(cs.totalFor('Kuch Aur'), 50);
    });
  });

  group('Exam.marksFieldFor', () {
    test('exam type se DB column ka naam', () {
      expect(Exam.marksFieldFor('Mid Term'), 'mid_marks');
      expect(Exam.marksFieldFor('Final Term'), 'final_marks');
      expect(Exam.marksFieldFor('Weekly Test'), 'weekly_marks');
      expect(Exam.marksFieldFor('Monthly Test'), 'monthly_marks');
    });

    test('exam types list aur marks fields consistent hain', () {
      for (final t in Exam.examTypes) {
        expect(Exam.marksFieldFor(t), endsWith('_marks'));
      }
      expect(Exam.examTypes.length, 4);
    });
  });

  group('Model round-trip (toMap/fromMap)', () {
    test('SchoolClass', () {
      final c = SchoolClass(id: 3, name: '9th', monthlyFee: 2500);
      final back = SchoolClass.fromMap(c.toMap());
      expect(back.id, 3);
      expect(back.name, '9th');
      expect(back.monthlyFee, 2500);
      expect(back.isActive, isTrue);
    });

    test('ClassSubject ke tamam marks fields barqarar rehte hain', () {
      final s = ClassSubject(
        className: '5th',
        subject: 'Science',
        totalMarks: 75,
        midMarks: 40,
        finalMarks: 75,
        weeklyMarks: 10,
        monthlyMarks: 20,
        sortOrder: 2,
      );
      final back = ClassSubject.fromMap(s.toMap());
      expect(back.totalMarks, 75);
      expect(back.midMarks, 40);
      expect(back.finalMarks, 75);
      expect(back.weeklyMarks, 10);
      expect(back.monthlyMarks, 20);
      expect(back.sortOrder, 2);
    });

    test('Exam ka exam_type — purane records (null) pe Mid Term default', () {
      final e = Exam(
          id: 1,
          name: 'Mid 2026',
          className: '10th',
          startDate: '2026-11-01',
          endDate: '2026-11-10',
          examType: 'Final Term');
      expect(Exam.fromMap(e.toMap()).examType, 'Final Term');

      // v2 se aaya hua row: exam_type column maujood hi nahi.
      final legacy = Exam.fromMap({
        'id': 2,
        'name': 'Old',
        'class_name': '9th',
        'start_date': '2026-01-01',
        'end_date': '2026-01-05',
      });
      expect(legacy.examType, 'Mid Term');
    });

    test('FeePayment', () {
      final p = FeePayment(
          studentId: 7, month: '2026-11', amount: 1500, note: 'Installment 1');
      final back = FeePayment.fromMap(p.toMap());
      expect(back.studentId, 7);
      expect(back.month, '2026-11');
      expect(back.amount, 1500);
      expect(back.note, 'Installment 1');
    });

    test('Student ka fee_start_month barqarar rehta hai', () {
      final s = Student(
        name: 'Ali',
        rollNo: '101',
        className: '1st',
        parentName: 'P',
        parentPhone: '0300',
        feeStartMonth: '2026-09',
      );
      expect(Student.fromMap(s.toMap()).feeStartMonth, '2026-09');
    });
  });

  group('DatabaseHelper.classRank (dropdown ki tarteeb)', () {
    // Asli static method call hoti hai — logic dobara nahi likha gaya.
    test('Nursery/KG pehle, phir 1st se 10th', () {
      final names = ['10th', '2nd', 'Nursery', 'KG', '1st'];
      names.sort((a, b) =>
          DatabaseHelper.classRank(a).compareTo(DatabaseHelper.classRank(b)));
      expect(names, ['Nursery', 'KG', '1st', '2nd', '10th']);
    });

    test('na-maloom class sab se aakhir mein', () {
      expect(DatabaseHelper.classRank('Special'),
          greaterThan(DatabaseHelper.classRank('10th')));
    });

    test('10th, 2nd se baad mein aati hai (string sort ka masla nahi)', () {
      // String sort mein "10th" < "2nd" ho jata — isi liye rank chahiye.
      expect(DatabaseHelper.classRank('10th'),
          greaterThan(DatabaseHelper.classRank('2nd')));
    });
  });
}
