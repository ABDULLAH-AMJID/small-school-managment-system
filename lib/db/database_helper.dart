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

  /// DB schema/data version.
  /// 1 = initial release (v1.0.0)
  /// 2 = test data seed: 5 teachers + 40 students (v1.0.1)
  static const int _dbVersion = 2;

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'school_management.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Sirf pehli baar chalta hai, jab DB file banti hai.
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

    await _seedUsers(db);
    await _seedTeachers(db);
    await _seedStudents(db);
  }

  /// Purani install (DB v1) pe chalta hai.
  /// BUG jo yahan fix hua: pehle onUpgrade maujood hi nahi tha aur DB version 1
  /// pe atka tha, is liye v1.0.1 install karne ke baad bhi test data nahi aata
  /// tha — onCreate sirf pehli baar chalta hai, purani DB pe kabhi nahi.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _seedTeachers(db);
      await _seedStudents(db);
    }
  }

  // ============ SEED HELPERS (idempotent) ============
  // onCreate aur onUpgrade dono se call hote hain, is liye har ek pehle check
  // karta hai ke data pehle se mojood to nahi — warna duplicate rows ban jatin.

  Future<void> _seedUsers(Database db) async {
    final n =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users'));
    if (n != null && n > 0) return;
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

  Future<void> _seedTeachers(Database db) async {
    final n = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM teachers'));
    if (n != null && n > 0) return;
    // ============ SEED TEACHERS (5 staff members) ============
    await db.insert('teachers', {
      'name': 'Ustad Ahmad Ali',
      'subject': 'Urdu',
      'phone': '03001234567',
      'email': 'ahmad@school.com',
      'qualification': 'M.A Urdu',
      'salary': 25000,
      'is_active': 1,
    });
    await db.insert('teachers', {
      'name': 'Ms. Fatima Batool',
      'subject': 'English',
      'phone': '03002345678',
      'email': 'fatima@school.com',
      'qualification': 'M.A English',
      'salary': 25000,
      'is_active': 1,
    });
    await db.insert('teachers', {
      'name': 'Ustad Muhammad Ali',
      'subject': 'Mathematics',
      'phone': '03003456789',
      'email': 'ali@school.com',
      'qualification': 'M.Sc Math',
      'salary': 28000,
      'is_active': 1,
    });
    await db.insert('teachers', {
      'name': 'Ms. Sara Ahmed',
      'subject': 'Science',
      'phone': '03004567890',
      'email': 'sara@school.com',
      'qualification': 'M.Sc Science',
      'salary': 27000,
      'is_active': 1,
    });
    await db.insert('teachers', {
      'name': 'Ustad Rehman Khan',
      'subject': 'Computer / Islamiat',
      'phone': '03005678901',
      'email': 'rehman@school.com',
      'qualification': 'BS CS',
      'salary': 26000,
      'is_active': 1,
    });
  }

  Future<void> _seedStudents(Database db) async {
    final n = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM students'));
    if (n != null && n > 0) return;
    // ============ SEED STUDENTS (Classes 1st to 10th, Sections A & B) ============
    final students = [
      // Class 1
      {
        'name': 'Ali Raza',
        'roll_no': '101',
        'class_name': '1st',
        'section': 'A',
        'phone': '03001111111',
        'parent_name': 'Muhammad Raza',
        'parent_phone': '03009999991',
        'address': 'Mohallah A, Sahiwal'
      },
      {
        'name': 'Fatima Noor',
        'roll_no': '102',
        'class_name': '1st',
        'section': 'A',
        'phone': '03001111112',
        'parent_name': 'Noor Ahmed',
        'parent_phone': '03009999992',
        'address': 'Mohallah B, Sahiwal'
      },
      {
        'name': 'Ahmed Hassan',
        'roll_no': '103',
        'class_name': '1st',
        'section': 'B',
        'phone': '03001111113',
        'parent_name': 'Hassan Ali',
        'parent_phone': '03009999993',
        'address': 'Mohallah C, Sahiwal'
      },
      {
        'name': 'Zainab Bibi',
        'roll_no': '104',
        'class_name': '1st',
        'section': 'B',
        'phone': '03001111114',
        'parent_name': 'Bibi Zainab',
        'parent_phone': '03009999994',
        'address': 'Mohallah D, Sahiwal'
      },
      // Class 2
      {
        'name': 'Usman Ghani',
        'roll_no': '201',
        'class_name': '2nd',
        'section': 'A',
        'phone': '03001111115',
        'parent_name': 'Ghani Ahmed',
        'parent_phone': '03009999995',
        'address': 'Mohallah E, Sahiwal'
      },
      {
        'name': 'Maryam Saleem',
        'roll_no': '202',
        'class_name': '2nd',
        'section': 'A',
        'phone': '03001111116',
        'parent_name': 'Saleem Akhtar',
        'parent_phone': '03009999996',
        'address': 'Mohallah F, Sahiwal'
      },
      {
        'name': 'Bilal Khan',
        'roll_no': '203',
        'class_name': '2nd',
        'section': 'B',
        'phone': '03001111117',
        'parent_name': 'Khan Muhammad',
        'parent_phone': '03009999997',
        'address': 'Mohallah G, Sahiwal'
      },
      {
        'name': 'Ayesha Siddiqua',
        'roll_no': '204',
        'class_name': '2nd',
        'section': 'B',
        'phone': '03001111118',
        'parent_name': 'Siddiqua Ali',
        'parent_phone': '03009999998',
        'address': 'Mohallah H, Sahiwal'
      },
      // Class 3
      {
        'name': 'Omar Farooq',
        'roll_no': '301',
        'class_name': '3rd',
        'section': 'A',
        'phone': '03001111119',
        'parent_name': 'Farooq Ahmed',
        'parent_phone': '03009999999',
        'address': 'Mohallah I, Sahiwal'
      },
      {
        'name': 'Hina Shahzadi',
        'roll_no': '302',
        'class_name': '3rd',
        'section': 'A',
        'phone': '03001111120',
        'parent_name': 'Shahzadi Bano',
        'parent_phone': '03009999900',
        'address': 'Mohallah J, Sahiwal'
      },
      {
        'name': 'Danish Ali',
        'roll_no': '303',
        'class_name': '3rd',
        'section': 'B',
        'phone': '03001111121',
        'parent_name': 'Ali Akbar',
        'parent_phone': '03009999901',
        'address': 'Mohallah K, Sahiwal'
      },
      {
        'name': 'Noor Fatima',
        'roll_no': '304',
        'class_name': '3rd',
        'section': 'B',
        'phone': '03001111122',
        'parent_name': 'Fatima Batool',
        'parent_phone': '03009999902',
        'address': 'Mohallah L, Sahiwal'
      },
      // Class 4
      {
        'name': 'Hamza Tariq',
        'roll_no': '401',
        'class_name': '4th',
        'section': 'A',
        'phone': '03001111123',
        'parent_name': 'Tariq Mahmood',
        'parent_phone': '03009999903',
        'address': 'Mohallah M, Sahiwal'
      },
      {
        'name': 'Zoya Khan',
        'roll_no': '402',
        'class_name': '4th',
        'section': 'A',
        'phone': '03001111124',
        'parent_name': 'Khan Bahadur',
        'parent_phone': '03009999904',
        'address': 'Mohallah N, Sahiwal'
      },
      {
        'name': 'Abdullah Shah',
        'roll_no': '403',
        'class_name': '4th',
        'section': 'B',
        'phone': '03001111125',
        'parent_name': 'Shah Jahan',
        'parent_phone': '03009999905',
        'address': 'Mohallah O, Sahiwal'
      },
      {
        'name': 'Amina Bibi',
        'roll_no': '404',
        'class_name': '4th',
        'section': 'B',
        'phone': '03001111126',
        'parent_name': 'Bibi Amina',
        'parent_phone': '03009999906',
        'address': 'Mohallah P, Sahiwal'
      },
      // Class 5
      {
        'name': 'Saad Ahmed',
        'roll_no': '501',
        'class_name': '5th',
        'section': 'A',
        'phone': '03001111127',
        'parent_name': 'Ahmed Raza',
        'parent_phone': '03009999907',
        'address': 'Mohallah Q, Sahiwal'
      },
      {
        'name': 'Hadia Noor',
        'roll_no': '502',
        'class_name': '5th',
        'section': 'A',
        'phone': '03001111128',
        'parent_name': 'Noor Muhammad',
        'parent_phone': '03009999908',
        'address': 'Mohallah R, Sahiwal'
      },
      {
        'name': 'Yousaf Ali',
        'roll_no': '503',
        'class_name': '5th',
        'section': 'B',
        'phone': '03001111129',
        'parent_name': 'Ali Raza',
        'parent_phone': '03009999909',
        'address': 'Mohallah S, Sahiwal'
      },
      {
        'name': 'Aiman Fatima',
        'roll_no': '504',
        'class_name': '5th',
        'section': 'B',
        'phone': '03001111130',
        'parent_name': 'Fatima Zahra',
        'parent_phone': '03009999910',
        'address': 'Mohallah T, Sahiwal'
      },
      // Class 6
      {
        'name': 'Hassan Raza',
        'roll_no': '601',
        'class_name': '6th',
        'section': 'A',
        'phone': '03001111131',
        'parent_name': 'Raza Shah',
        'parent_phone': '03009999911',
        'address': 'Mohallah U, Sahiwal'
      },
      {
        'name': 'Mariam Batool',
        'roll_no': '602',
        'class_name': '6th',
        'section': 'A',
        'phone': '03001111132',
        'parent_name': 'Batool Rizvi',
        'parent_phone': '03009999912',
        'address': 'Mohallah V, Sahiwal'
      },
      {
        'name': 'Zain Abbas',
        'roll_no': '603',
        'class_name': '6th',
        'section': 'B',
        'phone': '03001111133',
        'parent_name': 'Abbas Naqvi',
        'parent_phone': '03009999913',
        'address': 'Mohallah W, Sahiwal'
      },
      {
        'name': 'Sana Khan',
        'roll_no': '604',
        'class_name': '6th',
        'section': 'B',
        'phone': '03001111134',
        'parent_name': 'Khan Bibi',
        'parent_phone': '03009999914',
        'address': 'Mohallah X, Sahiwal'
      },
      // Class 7
      {
        'name': 'Imran Ali',
        'roll_no': '701',
        'class_name': '7th',
        'section': 'A',
        'phone': '03001111135',
        'parent_name': 'Ali Muhammad',
        'parent_phone': '03009999915',
        'address': 'Mohallah Y, Sahiwal'
      },
      {
        'name': 'Khadija Tul Kubra',
        'roll_no': '702',
        'class_name': '7th',
        'section': 'A',
        'phone': '03001111136',
        'parent_name': 'Kubra Ahmed',
        'parent_phone': '03009999916',
        'address': 'Mohallah Z, Sahiwal'
      },
      {
        'name': 'Bilal Ahmed',
        'roll_no': '703',
        'class_name': '7th',
        'section': 'B',
        'phone': '03001111137',
        'parent_name': 'Ahmed Bilal',
        'parent_phone': '03009999917',
        'address': 'Mohallah AA, Sahiwal'
      },
      {
        'name': 'Rabia Basri',
        'roll_no': '704',
        'class_name': '7th',
        'section': 'B',
        'phone': '03001111138',
        'parent_name': 'Basri Ali',
        'parent_phone': '03009999918',
        'address': 'Mohallah BB, Sahiwal'
      },
      // Class 8
      {
        'name': 'Talha Khan',
        'roll_no': '801',
        'class_name': '8th',
        'section': 'A',
        'phone': '03001111139',
        'parent_name': 'Khan Talha',
        'parent_phone': '03009999919',
        'address': 'Mohallah CC, Sahiwal'
      },
      {
        'name': 'Nimra Ali',
        'roll_no': '802',
        'class_name': '8th',
        'section': 'A',
        'phone': '03001111140',
        'parent_name': 'Ali Nimra',
        'parent_phone': '03009999920',
        'address': 'Mohallah DD, Sahiwal'
      },
      {
        'name': 'Hamza Shah',
        'roll_no': '803',
        'class_name': '8th',
        'section': 'B',
        'phone': '03001111141',
        'parent_name': 'Shah Hamza',
        'parent_phone': '03009999921',
        'address': 'Mohallah EE, Sahiwal'
      },
      {
        'name': 'Iqra Batool',
        'roll_no': '804',
        'class_name': '8th',
        'section': 'B',
        'phone': '03001111142',
        'parent_name': 'Batool Iqra',
        'parent_phone': '03009999922',
        'address': 'Mohallah FF, Sahiwal'
      },
      // Class 9
      {
        'name': 'Suleman Ahmed',
        'roll_no': '901',
        'class_name': '9th',
        'section': 'A',
        'phone': '03001111143',
        'parent_name': 'Ahmed Suleman',
        'parent_phone': '03009999923',
        'address': 'Mohallah GG, Sahiwal'
      },
      {
        'name': 'Hira Noor',
        'roll_no': '902',
        'class_name': '9th',
        'section': 'A',
        'phone': '03001111144',
        'parent_name': 'Noor Hira',
        'parent_phone': '03009999924',
        'address': 'Mohallah HH, Sahiwal'
      },
      {
        'name': 'Usman Ali',
        'roll_no': '903',
        'class_name': '9th',
        'section': 'B',
        'phone': '03001111145',
        'parent_name': 'Ali Usman',
        'parent_phone': '03009999925',
        'address': 'Mohallah II, Sahiwal'
      },
      {
        'name': 'Zainab Ahmed',
        'roll_no': '904',
        'class_name': '9th',
        'section': 'B',
        'phone': '03001111146',
        'parent_name': 'Ahmed Zainab',
        'parent_phone': '03009999926',
        'address': 'Mohallah JJ, Sahiwal'
      },
      // Class 10
      {
        'name': 'Abdullah Khan',
        'roll_no': '1001',
        'class_name': '10th',
        'section': 'A',
        'phone': '03001111147',
        'parent_name': 'Khan Abdullah',
        'parent_phone': '03009999927',
        'address': 'Mohallah KK, Sahiwal'
      },
      {
        'name': 'Ayesha Fatima',
        'roll_no': '1002',
        'class_name': '10th',
        'section': 'A',
        'phone': '03001111148',
        'parent_name': 'Fatima Ayesha',
        'parent_phone': '03009999928',
        'address': 'Mohallah LL, Sahiwal'
      },
      {
        'name': 'Muhammad Ali',
        'roll_no': '1003',
        'class_name': '10th',
        'section': 'B',
        'phone': '03001111149',
        'parent_name': 'Ali Muhammad',
        'parent_phone': '03009999929',
        'address': 'Mohallah MM, Sahiwal'
      },
      {
        'name': 'Hafsa Bibi',
        'roll_no': '1004',
        'class_name': '10th',
        'section': 'B',
        'phone': '03001111150',
        'parent_name': 'Bibi Hafsa',
        'parent_phone': '03009999930',
        'address': 'Mohallah NN, Sahiwal'
      },
    ];

    for (var s in students) {
      await db.insert('students', {
        'name': s['name'],
        'roll_no': s['roll_no'],
        'class_name': s['class_name'],
        'section': s['section'],
        'phone': s['phone'],
        'parent_name': s['parent_name'],
        'parent_phone': s['parent_phone'],
        'address': s['address'],
        'admission_date': '2026-01-01',
        'photo_path': null,
        'is_active': 1,
      });
    }
  }

  // ============ GENERIC ============
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final d = await db;
    return await d.insert(table, data);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where,
      List<Object?> whereArgs) async {
    final d = await db;
    return await d.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
      String table, String where, List<Object?> whereArgs) async {
    final d = await db;
    return await d.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final d = await db;
    return await d.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
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
  Future<List<Student>> getStudents(
      {String? className, bool activeOnly = true}) async {
    String where = activeOnly ? 'is_active = 1' : '1';
    List<Object?> args = [];
    if (className != null && className.isNotEmpty) {
      where += ' AND class_name = ?';
      args.add(className);
    }
    final rows = await query('students',
        where: where, whereArgs: args, orderBy: 'name ASC');
    return rows.map(Student.fromMap).toList();
  }

  Future<int> insertStudent(Student s) => insert('students', s.toMap());
  Future<int> updateStudent(Student s) =>
      update('students', s.toMap(), 'id = ?', [s.id]);
  Future<int> deleteStudent(int id) => delete('students', 'id = ?', [id]);
  Future<Student?> getStudentById(int id) async {
    final rows = await query('students', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? Student.fromMap(rows.first) : null;
  }

  Future<List<String>> getClasses() async {
    final d = await db;
    final rows = await d.rawQuery(
        "SELECT DISTINCT class_name FROM students WHERE is_active = 1 ORDER BY class_name");
    return rows.map((r) => r['class_name'] as String).toList();
  }

  // ============ TEACHERS ============
  Future<List<Teacher>> getTeachers({bool activeOnly = true}) async {
    String where = activeOnly ? 'is_active = 1' : '1';
    final rows = await query('teachers',
        where: where, whereArgs: [], orderBy: 'name ASC');
    return rows.map(Teacher.fromMap).toList();
  }

  Future<int> insertTeacher(Teacher t) => insert('teachers', t.toMap());
  Future<int> updateTeacher(Teacher t) =>
      update('teachers', t.toMap(), 'id = ?', [t.id]);
  Future<int> deleteTeacher(int id) => delete('teachers', 'id = ?', [id]);

  // ============ STUDENT ATTENDANCE ============
  Future<int> markStudentAttendance(StudentAttendance a) =>
      insert('student_attendance', a.toMap());
  Future<List<StudentAttendance>> getStudentAttendance({
    required String className,
    required String date,
  }) async {
    final rows = await query('student_attendance',
        where: 'class_name = ? AND date = ?', whereArgs: [className, date]);
    return rows.map(StudentAttendance.fromMap).toList();
  }

  Future<List<StudentAttendance>> getAttendanceForStudent(int studentId,
      {String? fromDate, String? toDate}) async {
    String where = 'student_id = ?';
    List<Object?> args = [studentId];
    if (fromDate != null && fromDate.isNotEmpty) {
      where += ' AND date >= ?';
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where += ' AND date <= ?';
      args.add(toDate);
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
      where += ' AND date >= ?';
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      where += ' AND date <= ?';
      args.add(toDate);
    }
    final present = await _count(
        'student_attendance', '$where AND status = ?', [...args, 'Present']);
    final absent = await _count(
        'student_attendance', '$where AND status = ?', [...args, 'Absent']);
    final leave = await _count(
        'student_attendance', '$where AND status = ?', [...args, 'Leave']);
    return {'Present': present, 'Absent': absent, 'Leave': leave};
  }

  Future<int> _count(String table, String where, List<Object?> args) async {
    final d = await db;
    final r =
        await d.rawQuery('SELECT COUNT(*) as c FROM $table WHERE $where', args);
    return (r.first['c'] as int);
  }

  // ============ TEACHER ATTENDANCE ============
  Future<int> markTeacherAttendance(TeacherAttendance a) =>
      insert('teacher_attendance', a.toMap());
  Future<List<TeacherAttendance>> getTeacherAttendance({String? date}) async {
    String where = date != null && date.isNotEmpty ? 'date = ?' : '1';
    List<Object?> args = date != null && date.isNotEmpty ? [date] : [];
    final rows =
        await query('teacher_attendance', where: where, whereArgs: args);
    return rows.map(TeacherAttendance.fromMap).toList();
  }

  // ============ EXAMS ============
  Future<List<Exam>> getExams({String? className}) async {
    String where =
        className != null && className.isNotEmpty ? 'class_name = ?' : '1';
    List<Object?> args =
        className != null && className.isNotEmpty ? [className] : [];
    final rows = await query('exams',
        where: where, whereArgs: args, orderBy: 'start_date DESC');
    return rows.map(Exam.fromMap).toList();
  }

  Future<int> insertExam(Exam e) => insert('exams', e.toMap());
  Future<int> updateExam(Exam e) =>
      update('exams', e.toMap(), 'id = ?', [e.id]);
  Future<int> deleteExam(int id) => delete('exams', 'id = ?', [id]);

  // ============ TIMETABLE ============
  Future<List<TimetableEntry>> getTimetable(String className) async {
    final rows = await query('timetable',
        where: 'class_name = ?',
        whereArgs: [className],
        orderBy: 'day ASC, period ASC');
    return rows.map(TimetableEntry.fromMap).toList();
  }

  Future<int> insertTimetable(TimetableEntry t) =>
      insert('timetable', t.toMap());
  Future<int> deleteTimetableForClass(String className) =>
      delete('timetable', 'class_name = ?', [className]);

  // ============ MARKS ============
  Future<List<Mark>> getMarks({int? studentId, int? examId}) async {
    List<String> wheres = [];
    List<Object?> args = [];
    if (studentId != null) {
      wheres.add('student_id = ?');
      args.add(studentId);
    }
    if (examId != null) {
      wheres.add('exam_id = ?');
      args.add(examId);
    }
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
    if (studentId != null) {
      wheres.add('student_id = ?');
      args.add(studentId);
    }
    if (status != null && status.isNotEmpty) {
      wheres.add('status = ?');
      args.add(status);
    }
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
        where: "status != 'Paid'", whereArgs: [], orderBy: 'due_date ASC');
    return rows.map(Fee.fromMap).toList();
  }

  // ============ HOMEWORK ============
  Future<List<Homework>> getHomework({String? className}) async {
    String where =
        className != null && className.isNotEmpty ? 'class_name = ?' : '1';
    List<Object?> args =
        className != null && className.isNotEmpty ? [className] : [];
    final rows = await query('homework',
        where: where, whereArgs: args, orderBy: 'date DESC');
    return rows.map(Homework.fromMap).toList();
  }

  Future<int> insertHomework(Homework h) => insert('homework', h.toMap());

  // ============ WEEKLY REPORTS ============
  Future<int> insertWeeklyReport(WeeklyReport r) =>
      insert('weekly_reports', r.toMap());
  Future<List<WeeklyReport>> getWeeklyReports({int? studentId}) async {
    String where = studentId != null ? 'student_id = ?' : '1';
    List<Object?> args = studentId != null ? [studentId] : [];
    final rows = await query('weekly_reports',
        where: where, whereArgs: args, orderBy: 'week_start DESC');
    return rows.map(WeeklyReport.fromMap).toList();
  }

  Future<void> close() async {
    final d = _db;
    if (d != null && d.isOpen) await d.close();
    _db = null;
  }
}
