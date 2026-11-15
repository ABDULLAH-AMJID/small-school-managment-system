import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_models.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'school_management.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        role INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    // Students
    await db.execute('''
      CREATE TABLE students(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        roll_no TEXT,
        class_name TEXT,
        section TEXT,
        phone TEXT,
        parent_name TEXT,
        parent_phone TEXT,
        address TEXT,
        admission_date TEXT,
        photo_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    // Teachers
    await db.execute('''
      CREATE TABLE teachers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        subject TEXT,
        phone TEXT,
        email TEXT,
        qualification TEXT,
        salary REAL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    // Student attendance
    await db.execute('''
      CREATE TABLE student_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        class_name TEXT,
        marked_by TEXT
      )
    ''');
    // Teacher attendance
    await db.execute('''
      CREATE TABLE teacher_attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    // Exams
    await db.execute('''
      CREATE TABLE exams(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        class_name TEXT,
        start_date TEXT,
        end_date TEXT
      )
    ''');
    // Timetable
    await db.execute('''
      CREATE TABLE timetable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT,
        day TEXT,
        period INTEGER,
        subject TEXT,
        teacher_id INTEGER,
        time_start TEXT,
        time_end TEXT
      )
    ''');
    // Marks
    await db.execute('''
      CREATE TABLE marks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        exam_id INTEGER NOT NULL,
        subject TEXT,
        marks_obtained REAL DEFAULT 0,
        total_marks REAL DEFAULT 100
      )
    ''');
    // Fees
    await db.execute('''
      CREATE TABLE fees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        month TEXT,
        amount REAL DEFAULT 0,
        due_date TEXT,
        amount_paid REAL DEFAULT 0,
        status TEXT DEFAULT 'Pending',
        paid_date TEXT
      )
    ''');
    // Homework
    await db.execute('''
      CREATE TABLE homework(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT,
        subject TEXT,
        description TEXT,
        date TEXT
      )
    ''');
    // Weekly reports
    await db.execute('''
      CREATE TABLE weekly_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        week_start TEXT,
        attendance_percent REAL DEFAULT 0,
        present_days INTEGER DEFAULT 0,
        absent_days INTEGER DEFAULT 0,
        homework_status TEXT,
        teacher_comment TEXT,
        fee_balance REAL DEFAULT 0,
        fee_last_date TEXT
      )
    ''');
    // Seed default admin
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'name': 'School Admin',
      'phone': '',
      'email': '',
      'role': 0,
      'is_active': 1,
    });
    await db.insert('users', {
      'username': 'teacher',
      'password': 'teacher123',
      'name': 'Ustad Ahmad',
      'phone': '',
      'email': '',
      'role': 1,
      'is_active': 1,
    });
    await db.insert('users', {
      'username': 'parent',
      'password': 'parent123',
      'name': 'Walidain',
      'phone': '',
      'email': '',
      'role': 2,
      'is_active': 1,
    });
  }

  // ============ GENERIC ============
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final d = await db;
    return await d.insert(table, data);
  }
  Future<int> update(String table, Map<String, dynamic> data, String where, List<Object?> whereArgs) async {
    final d = await db;
    return await d.update(table, data, where: where, whereArgs: whereArgs);
  }
  Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    final d = await db;
    return await d.delete(table, where: where, whereArgs: whereArgs);
  }
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final d = await db;
    return await d.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  // ============ AUTH ============
  Future<AppUser?> authenticate(String username, String password) async {
    final rows = await query('users',
        where: 'username = ? AND password = ? AND is_active = 1',
        whereArgs: [username, password]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // ============ STUDENTS ============
  Future<List<Student>> getStudents({String? className, bool activeOnly = true}) async {
    String where = activeOnly ? 'is_active = 1' : '1';
    List<Object?> args = [];
    if (className != null && className.isNotEmpty) {
      where += ' AND class_name = ?';
      args.add(className);
    }
    final rows = await query('students', where: where, whereArgs: args, orderBy: 'name ASC');
    return rows.map(Student.fromMap).toList();
  }
  Future<int> insertStudent(Student s) => insert('students', s.toMap());
  Future<int> updateStudent(Student s) => update('students', s.toMap(), 'id = ?', [s.id]);
  Future<int> deleteStudent(int id) => delete('students', 'id = ?', [id]);
  Future<Student?> getStudentById(int id) async {
    final rows = await query('students', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? Student.fromMap(rows.first) : null;
  }
  Future<List<String>> getClasses() async {
    final d = await db;
    final rows = await d.rawQuery("SELECT DISTINCT class_name FROM students WHERE is_active = 1 ORDER BY class_name");
    return rows.map((r) => r['class_name'] as String).toList();
  }

  // ============ TEACHERS ============
  Future<List<Teacher>> getTeachers({bool activeOnly = true}) async {
    String where = activeOnly ? 'is_active = 1' : '1';
    final rows = await query('teachers', where: where, whereArgs: [], orderBy: 'name ASC');
    return rows.map(Teacher.fromMap).toList();
  }
  Future<int> insertTeacher(Teacher t) => insert('teachers', t.toMap());
  Future<int> updateTeacher(Teacher t) => update('teachers', t.toMap(), 'id = ?', [t.id]);
  Future<int> deleteTeacher(int id) => delete('teachers', 'id = ?', [id]);

  // ============ STUDENT ATTENDANCE ============
  Future<int> markStudentAttendance(StudentAttendance a) => insert('student_attendance', a.toMap());
  Future<List<StudentAttendance>> getStudentAttendance({
    required String className,
    required String date,
  }) async {
    final rows = await query('student_attendance',
        where: 'class_name = ? AND date = ?',
        whereArgs: [className, date]);
    return rows.map(StudentAttendance.fromMap).toList();
  }
  Future<List<StudentAttendance>> getAttendanceForStudent(int studentId,
      {String? fromDate, String? toDate}) async {
    String where = 'student_id = ?';
    List<Object?> args = [studentId];
    if (fromDate != null && fromDate.isNotEmpty) {
      where += ' AND date >= ?'; args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where += ' AND date <= ?'; args.add(toDate);
    }
    final rows = await query('student_attendance',
        where: where, whereArgs: args, orderBy: 'date DESC');
    return rows.map(StudentAttendance.fromMap).toList();
  }
  Future<Map<String, int>> attendanceStatsForStudent(int studentId,
      {String? fromDate, String? toDate}) async {
    String where = 'student_id = ?';
    List<Object?> args = [studentId];
    if (fromDate != null && fromDate.isNotEmpty) {
      where += ' AND date >= ?'; args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where += ' AND date <= ?'; args.add(toDate);
    }
    final present = await _count('student_attendance', '$where AND status = ?', [...args, 'Present']);
    final absent = await _count('student_attendance', '$where AND status = ?', [...args, 'Absent']);
    final leave = await _count('student_attendance', '$where AND status = ?', [...args, 'Leave']);
    return {'Present': present, 'Absent': absent, 'Leave': leave};
  }
  Future<int> _count(String table, String where, List<Object?> args) async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) as c FROM $table WHERE $where', args);
    return (r.first['c'] as int);
  }

  // ============ TEACHER ATTENDANCE ============
  Future<int> markTeacherAttendance(TeacherAttendance a) => insert('teacher_attendance', a.toMap());
  Future<List<TeacherAttendance>> getTeacherAttendance({String? date}) async {
    String where = date != null && date.isNotEmpty ? 'date = ?' : '1';
    List<Object?> args = date != null && date.isNotEmpty ? [date] : [];
    final rows = await query('teacher_attendance', where: where, whereArgs: args);
    return rows.map(TeacherAttendance.fromMap).toList();
  }

  // ============ EXAMS ============
  Future<List<Exam>> getExams({String? className}) async {
    String where = className != null && className.isNotEmpty ? 'class_name = ?' : '1';
    List<Object?> args = className != null && className.isNotEmpty ? [className] : [];
    final rows = await query('exams', where: where, whereArgs: args, orderBy: 'start_date DESC');
    return rows.map(Exam.fromMap).toList();
  }
  Future<int> insertExam(Exam e) => insert('exams', e.toMap());
  Future<int> updateExam(Exam e) => update('exams', e.toMap(), 'id = ?', [e.id]);
  Future<int> deleteExam(int id) => delete('exams', 'id = ?', [id]);

  // ============ TIMETABLE ============
  Future<List<TimetableEntry>> getTimetable(String className) async {
    final rows = await query('timetable',
        where: 'class_name = ?', whereArgs: [className],
        orderBy: 'day ASC, period ASC');
    return rows.map(TimetableEntry.fromMap).toList();
  }
  Future<int> insertTimetable(TimetableEntry t) => insert('timetable', t.toMap());
  Future<int> deleteTimetableForClass(String className) =>
      delete('timetable', 'class_name = ?', [className]);

  // ============ MARKS ============
  Future<List<Mark>> getMarks({int? studentId, int? examId}) async {
    List<String> wheres = [];
    List<Object?> args = [];
    if (studentId != null) { wheres.add('student_id = ?'); args.add(studentId); }
    if (examId != null) { wheres.add('exam_id = ?'); args.add(examId); }
    final rows = await query('marks',
        where: wheres.isEmpty ? null : wheres.join(' AND '),
        whereArgs: wheres.isEmpty ? null : args,
        orderBy: 'subject ASC');
    return rows.map(Mark.fromMap).toList();
  }
  Future<int> insertMark(Mark m) => insert('marks', m.toMap());
  Future<List<Mark>> getMarksForStudentInExam(int studentId, int examId) =>
      getMarks(studentId: studentId, examId: examId);

  // ============ FEES ============
  Future<List<Fee>> getFees({int? studentId, String? status}) async {
    List<String> wheres = [];
    List<Object?> args = [];
    if (studentId != null) { wheres.add('student_id = ?'); args.add(studentId); }
    if (status != null && status.isNotEmpty) { wheres.add('status = ?'); args.add(status); }
    final rows = await query('fees',
        where: wheres.isEmpty ? null : wheres.join(' AND '),
        whereArgs: wheres.isEmpty ? null : args,
        orderBy: 'month DESC');
    return rows.map(Fee.fromMap).toList();
  }
  Future<int> insertFee(Fee f) => insert('fees', f.toMap());
  Future<int> updateFee(Fee f) => update('fees', f.toMap(), 'id = ?', [f.id]);
  Future<List<Fee>> getPendingFees() async {
    final rows = await query('fees',
        where: "status != 'Paid'", whereArgs: [],
        orderBy: 'due_date ASC');
    return rows.map(Fee.fromMap).toList();
  }

  // ============ HOMEWORK ============
  Future<List<Homework>> getHomework({String? className}) async {
    String where = className != null && className.isNotEmpty ? 'class_name = ?' : '1';
    List<Object?> args = className != null && className.isNotEmpty ? [className] : [];
    final rows = await query('homework', where: where, whereArgs: args, orderBy: 'date DESC');
    return rows.map(Homework.fromMap).toList();
  }
  Future<int> insertHomework(Homework h) => insert('homework', h.toMap());

  // ============ WEEKLY REPORTS ============
  Future<int> insertWeeklyReport(WeeklyReport r) => insert('weekly_reports', r.toMap());
  Future<List<WeeklyReport>> getWeeklyReports({int? studentId}) async {
    String where = studentId != null ? 'student_id = ?' : '1';
    List<Object?> args = studentId != null ? [studentId] : [];
    final rows = await query('weekly_reports', where: where, whereArgs: args, orderBy: 'week_start DESC');
    return rows.map(WeeklyReport.fromMap).toList();
  }
  Future<void> close() async {
    final d = _db;
    if (d != null && d.isOpen) await d.close();
    _db = null;
  }
}
