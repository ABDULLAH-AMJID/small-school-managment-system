import 'package:equatable/equatable.dart';

/// ---------- ROLES ---------- ///
enum AppRole { admin, teacher, parent }

extension AppRoleExt on AppRole {
  String get label {
    switch (this) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.teacher:
        return 'Ustad';
      case AppRole.parent:
        return 'Walidain';
    }
  }
}

/// ---------- USER ---------- ///
class AppUser extends Equatable {
  final int? id;
  final String username;
  final String password;
  final String name;
  final String phone;
  final String email;
  final AppRole role;
  final bool isActive;
  AppUser({
    this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.phone,
    this.email = '',
    required this.role,
    this.isActive = true,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password': password,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.index,
        'isActive': isActive ? 1 : 0,
      };
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'],
        username: m['username'] ?? '',
        password: m['password'] ?? '',
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        role: AppRole.values[m['role'] ?? 0],
        isActive: (m['isActive'] ?? 1) == 1,
      );
  @override
  List<Object?> get props => [id, username, role];
}

/// ---------- STUDENT ---------- ///
class Student extends Equatable {
  final int? id;
  final String name;
  final String rollNo;
  final String className;
  final String section;
  final String phone;
  final String parentName;
  final String parentPhone;
  final String address;
  final String admissionDate;
  final String? photoPath;
  final bool isActive;

  /// Fee ka hisaab kis mahine se shuru hoga ("YYYY-MM"). Khaali ho to
  /// admission month (ya current month) istemaal hota hai.
  final String feeStartMonth;

  Student({
    this.id,
    required this.name,
    required this.rollNo,
    required this.className,
    this.section = '',
    this.phone = '',
    required this.parentName,
    required this.parentPhone,
    this.address = '',
    this.admissionDate = '',
    this.photoPath,
    this.isActive = true,
    this.feeStartMonth = '',
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'roll_no': rollNo,
        'class_name': className,
        'section': section,
        'phone': phone,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'address': address,
        'admission_date': admissionDate,
        'photo_path': photoPath,
        'is_active': isActive ? 1 : 0,
        'fee_start_month': feeStartMonth,
      };
  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'],
        name: m['name'] ?? '',
        rollNo: m['roll_no'] ?? '',
        className: m['class_name'] ?? '',
        section: m['section'] ?? '',
        phone: m['phone'] ?? '',
        parentName: m['parent_name'] ?? '',
        parentPhone: m['parent_phone'] ?? '',
        address: m['address'] ?? '',
        admissionDate: m['admission_date'] ?? '',
        photoPath: m['photo_path'],
        isActive: (m['is_active'] ?? 1) == 1,
        feeStartMonth: m['fee_start_month'] ?? '',
      );
  @override
  List<Object?> get props => [id, rollNo, className, feeStartMonth];
}

/// ---------- TEACHER ---------- ///
class Teacher extends Equatable {
  final int? id;
  final String name;
  final String subject;
  final String phone;
  final String email;
  final String qualification;
  final double salary;
  final bool isActive;
  Teacher({
    this.id,
    required this.name,
    this.subject = '',
    this.phone = '',
    this.email = '',
    this.qualification = '',
    this.salary = 0.0,
    this.isActive = true,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'subject': subject,
        'phone': phone,
        'email': email,
        'qualification': qualification,
        'salary': salary,
        'is_active': isActive ? 1 : 0,
      };
  factory Teacher.fromMap(Map<String, dynamic> m) => Teacher(
        id: m['id'],
        name: m['name'] ?? '',
        subject: m['subject'] ?? '',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        qualification: m['qualification'] ?? '',
        salary: (m['salary'] ?? 0).toDouble(),
        isActive: (m['is_active'] ?? 1) == 1,
      );
  @override
  List<Object?> get props => [id, name];
}

/// ---------- STUDENT ATTENDANCE ---------- ///
class StudentAttendance extends Equatable {
  final int? id;
  final int studentId;
  final String date; // yyyy-MM-dd
  final String status; // Present, Absent, Leave
  final String className;
  final String? markedBy;
  StudentAttendance({
    this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.className,
    this.markedBy,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'date': date,
        'status': status,
        'class_name': className,
        'marked_by': markedBy,
      };
  factory StudentAttendance.fromMap(Map<String, dynamic> m) =>
      StudentAttendance(
        id: m['id'],
        studentId: m['student_id'],
        date: m['date'] ?? '',
        status: m['status'] ?? '',
        className: m['class_name'] ?? '',
        markedBy: m['marked_by'],
      );
  @override
  List<Object?> get props => [id, studentId, date];
}

/// ---------- TEACHER ATTENDANCE ---------- ///
class TeacherAttendance extends Equatable {
  final int? id;
  final int teacherId;
  final String date;
  final String status;
  TeacherAttendance({
    this.id,
    required this.teacherId,
    required this.date,
    required this.status,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'teacher_id': teacherId,
        'date': date,
        'status': status,
      };
  factory TeacherAttendance.fromMap(Map<String, dynamic> m) =>
      TeacherAttendance(
        id: m['id'],
        teacherId: m['teacher_id'],
        date: m['date'] ?? '',
        status: m['status'] ?? '',
      );
  @override
  List<Object?> get props => [id, teacherId, date];
}

/// ---------- EXAM ---------- ///
class Exam extends Equatable {
  final int? id;
  final String name; // Mid Term, Final, Monthly
  final String className;
  final String startDate;
  final String endDate;

  /// Exam ki type — is se tay hota hai ke har subject ke kitne total marks
  /// honge (class settings mein mid/final/weekly/monthly alag alag set hote
  /// hain). Values [Exam.examTypes] mein hain.
  final String examType;

  /// Supported exam types. Class settings mein har subject ke liye inhi ke
  /// marks set hote hain.
  static const List<String> examTypes = [
    'Mid Term',
    'Final Term',
    'Weekly Test',
    'Monthly Test',
  ];

  /// [examType] ke liye [ClassSubject] ka kaunsa field istemaal hoga.
  static String marksFieldFor(String examType) {
    switch (examType) {
      case 'Final Term':
        return 'final_marks';
      case 'Weekly Test':
        return 'weekly_marks';
      case 'Monthly Test':
        return 'monthly_marks';
      case 'Mid Term':
      default:
        return 'mid_marks';
    }
  }

  Exam({
    this.id,
    required this.name,
    required this.className,
    required this.startDate,
    required this.endDate,
    this.examType = 'Mid Term',
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'class_name': className,
        'start_date': startDate,
        'end_date': endDate,
        'exam_type': examType,
      };
  factory Exam.fromMap(Map<String, dynamic> m) => Exam(
        id: m['id'],
        name: m['name'] ?? '',
        className: m['class_name'] ?? '',
        startDate: m['start_date'] ?? '',
        endDate: m['end_date'] ?? '',
        examType: (m['exam_type'] as String?)?.isNotEmpty == true
            ? m['exam_type'] as String
            : 'Mid Term',
      );
  @override
  List<Object?> get props => [id, name, className, examType];
}

/// ---------- CLASS SETTINGS ---------- ///
/// Har class ki default priorities: monthly fee aur us class ke subjects.
class SchoolClass extends Equatable {
  final int? id;
  final String name; // e.g. "1st", "10th"
  final double monthlyFee;
  final bool isActive;

  SchoolClass({
    this.id,
    required this.name,
    this.monthlyFee = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'monthly_fee': monthlyFee,
        'is_active': isActive ? 1 : 0,
      };

  factory SchoolClass.fromMap(Map<String, dynamic> m) => SchoolClass(
        id: m['id'],
        name: m['name'] ?? '',
        monthlyFee: (m['monthly_fee'] ?? 0).toDouble(),
        isActive: (m['is_active'] ?? 1) == 1,
      );

  @override
  List<Object?> get props => [id, name, monthlyFee, isActive];
}

/// Ek class ka ek subject, aur uske marks ke totals (exam type ke hisaab se).
class ClassSubject extends Equatable {
  final int? id;
  final String className;
  final String subject;

  /// Default total marks (jab exam type ka apna total set na ho).
  final double totalMarks;
  final double midMarks;
  final double finalMarks;
  final double weeklyMarks;
  final double monthlyMarks;
  final int sortOrder;

  ClassSubject({
    this.id,
    required this.className,
    required this.subject,
    this.totalMarks = 100,
    this.midMarks = 0,
    this.finalMarks = 0,
    this.weeklyMarks = 0,
    this.monthlyMarks = 0,
    this.sortOrder = 0,
  });

  /// Exam type ke hisaab se total marks. Agar us type ka total set nahi (0)
  /// to [totalMarks] par fallback — warna exam mein 0 ke out of marks aa jate.
  double totalFor(String examType) {
    final v = switch (examType) {
      'Final Term' => finalMarks,
      'Weekly Test' => weeklyMarks,
      'Monthly Test' => monthlyMarks,
      _ => midMarks,
    };
    return v > 0 ? v : totalMarks;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'class_name': className,
        'subject': subject,
        'total_marks': totalMarks,
        'mid_marks': midMarks,
        'final_marks': finalMarks,
        'weekly_marks': weeklyMarks,
        'monthly_marks': monthlyMarks,
        'sort_order': sortOrder,
      };

  factory ClassSubject.fromMap(Map<String, dynamic> m) => ClassSubject(
        id: m['id'],
        className: m['class_name'] ?? '',
        subject: m['subject'] ?? '',
        totalMarks: (m['total_marks'] ?? 100).toDouble(),
        midMarks: (m['mid_marks'] ?? 0).toDouble(),
        finalMarks: (m['final_marks'] ?? 0).toDouble(),
        weeklyMarks: (m['weekly_marks'] ?? 0).toDouble(),
        monthlyMarks: (m['monthly_marks'] ?? 0).toDouble(),
        sortOrder: m['sort_order'] ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, className, subject, totalMarks, midMarks, finalMarks];
}

/// Exam banate waqt chune gaye subjects (aur unke totals us exam ke liye).
class ExamSubject extends Equatable {
  final int? id;
  final int examId;
  final String subject;
  final double totalMarks;

  ExamSubject({
    this.id,
    required this.examId,
    required this.subject,
    this.totalMarks = 100,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'exam_id': examId,
        'subject': subject,
        'total_marks': totalMarks,
      };

  factory ExamSubject.fromMap(Map<String, dynamic> m) => ExamSubject(
        id: m['id'],
        examId: m['exam_id'],
        subject: m['subject'] ?? '',
        totalMarks: (m['total_marks'] ?? 100).toDouble(),
      );

  @override
  List<Object?> get props => [id, examId, subject, totalMarks];
}

/// Fee ki ek adaiigi (receipt). Installments isi se banti hain — ek hi month
/// ke against kitni bhi payments record ho sakti hain.
class FeePayment extends Equatable {
  final int? id;
  final int studentId;
  final String month; // "YYYY-MM"
  final double amount;
  final String paidDate; // yyyy-MM-dd
  final String note;

  FeePayment({
    this.id,
    required this.studentId,
    required this.month,
    required this.amount,
    this.paidDate = '',
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'month': month,
        'amount': amount,
        'paid_date': paidDate,
        'note': note,
      };

  factory FeePayment.fromMap(Map<String, dynamic> m) => FeePayment(
        id: m['id'],
        studentId: m['student_id'],
        month: m['month'] ?? '',
        amount: (m['amount'] ?? 0).toDouble(),
        paidDate: m['paid_date'] ?? '',
        note: m['note'] ?? '',
      );

  @override
  List<Object?> get props => [id, studentId, month, amount];
}

/// Fee ka hisaab (UI ke liye) — database table nahi.
class FeeLedger {
  FeeLedger({
    required this.monthlyFee,
    required this.months,
    required this.payments,
  });

  final double monthlyFee;

  /// "YYYY-MM" ki list, purane se naye.
  final List<String> months;

  /// month -> jama shuda raqam.
  final Map<String, double> payments;

  double payableFor(String month) => monthlyFee;

  double paidFor(String month) => payments[month] ?? 0;

  double balanceFor(String month) => payableFor(month) - paidFor(month);

  double get totalPayable => monthlyFee * months.length;

  double get totalPaid =>
      months.fold(0.0, (sum, m) => sum + (payments[m] ?? 0));

  double get totalBalance => totalPayable - totalPaid;

  /// Jitne mahinon ka kuch na kuch baqi hai.
  List<String> get pendingMonths =>
      months.where((m) => balanceFor(m) > 0.005).toList();

  int get pendingMonthCount => pendingMonths.length;

  bool isPaid(String month) => balanceFor(month) <= 0.005;

  bool isPartial(String month) =>
      paidFor(month) > 0.005 && balanceFor(month) > 0.005;

  String statusFor(String month) {
    if (isPaid(month)) return 'Paid';
    if (isPartial(month)) return 'Partial';
    return 'Pending';
  }

  /// Month labels, e.g. "2026-11" -> "Nov 2026".
  static String monthLabel(String yyyymm) {
    final parts = yyyymm.split('-');
    if (parts.length != 2) return yyyymm;
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final y = parts[0];
    final m = int.tryParse(parts[1]) ?? 0;
    if (m < 1 || m > 12) return yyyymm;
    return '${names[m - 1]} $y';
  }

  static String currentMonth([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  /// [from] se [to] tak ke tamam months (dono shamil), "YYYY-MM".
  static List<String> monthsBetween(String from, String to) {
    final out = <String>[];
    final f = _parse(from);
    final t = _parse(to);
    if (f == null || t == null) return out;
    var cur = DateTime(f.year, f.month);
    final end = DateTime(t.year, t.month);
    // Hadd se zyada loop se bachao (e.g. ghalat date ki wajah se).
    var guard = 0;
    while (!cur.isAfter(end) && guard < 600) {
      out.add('${cur.year}-${cur.month.toString().padLeft(2, '0')}');
      cur = DateTime(cur.year, cur.month + 1);
      guard++;
    }
    return out;
  }

  static DateTime? _parse(String yyyymm) {
    final parts = yyyymm.split('-');
    if (parts.length != 2) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (y == null || m == null || m < 1 || m > 12) return null;
    return DateTime(y, m);
  }
}

/// ---------- TIMETABLE ---------- ///
class TimetableEntry extends Equatable {
  final int? id;
  final String className;
  final String day; // Monday..Friday
  final int period;
  final String subject;
  final int teacherId;
  final String timeStart;
  final String timeEnd;
  TimetableEntry({
    this.id,
    required this.className,
    required this.day,
    required this.period,
    required this.subject,
    required this.teacherId,
    required this.timeStart,
    required this.timeEnd,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'class_name': className,
        'day': day,
        'period': period,
        'subject': subject,
        'teacher_id': teacherId,
        'time_start': timeStart,
        'time_end': timeEnd,
      };
  factory TimetableEntry.fromMap(Map<String, dynamic> m) => TimetableEntry(
        id: m['id'],
        className: m['class_name'] ?? '',
        day: m['day'] ?? '',
        period: m['period'] ?? 0,
        subject: m['subject'] ?? '',
        teacherId: m['teacher_id'] ?? 0,
        timeStart: m['time_start'] ?? '',
        timeEnd: m['time_end'] ?? '',
      );
  @override
  List<Object?> get props => [id, className, day, period];
}

/// ---------- MARKS ---------- ///
class Mark extends Equatable {
  final int? id;
  final int studentId;
  final int examId;
  final String subject;
  final double marksObtained;
  final double totalMarks;
  Mark({
    this.id,
    required this.studentId,
    required this.examId,
    required this.subject,
    required this.marksObtained,
    required this.totalMarks,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'exam_id': examId,
        'subject': subject,
        'marks_obtained': marksObtained,
        'total_marks': totalMarks,
      };
  factory Mark.fromMap(Map<String, dynamic> m) => Mark(
        id: m['id'],
        studentId: m['student_id'],
        examId: m['exam_id'],
        subject: m['subject'] ?? '',
        marksObtained: (m['marks_obtained'] ?? 0).toDouble(),
        totalMarks: (m['total_marks'] ?? 100).toDouble(),
      );
  @override
  List<Object?> get props => [id, studentId, examId, subject];
}

/// ---------- FEE ---------- ///
class Fee extends Equatable {
  final int? id;
  final int studentId;
  final String month; // e.g. "2026-01"
  final double amount;
  final String dueDate;
  final double amountPaid;
  final String status; // Paid, Pending, Partial
  final String? paidDate;
  Fee({
    this.id,
    required this.studentId,
    required this.month,
    required this.amount,
    required this.dueDate,
    this.amountPaid = 0.0,
    this.status = 'Pending',
    this.paidDate,
  });
  double get balance => amount - amountPaid;
  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'month': month,
        'amount': amount,
        'due_date': dueDate,
        'amount_paid': amountPaid,
        'status': status,
        'paid_date': paidDate,
      };
  factory Fee.fromMap(Map<String, dynamic> m) => Fee(
        id: m['id'],
        studentId: m['student_id'],
        month: m['month'] ?? '',
        amount: (m['amount'] ?? 0).toDouble(),
        dueDate: m['due_date'] ?? '',
        amountPaid: (m['amount_paid'] ?? 0).toDouble(),
        status: m['status'] ?? 'Pending',
        paidDate: m['paid_date'],
      );
  @override
  List<Object?> get props => [id, studentId, month];
}

/// ---------- HOMEWORK ---------- ///
class Homework extends Equatable {
  final int? id;
  final String className;
  final String subject;
  final String description;
  final String date; // assigned date
  Homework({
    this.id,
    required this.className,
    required this.subject,
    required this.description,
    required this.date,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'class_name': className,
        'subject': subject,
        'description': description,
        'date': date,
      };
  factory Homework.fromMap(Map<String, dynamic> m) => Homework(
        id: m['id'],
        className: m['class_name'] ?? '',
        subject: m['subject'] ?? '',
        description: m['description'] ?? '',
        date: m['date'] ?? '',
      );
  @override
  List<Object?> get props => [id, className, date];
}

/// ---------- WEEKLY REPORT SNAPSHOT ---------- ///
class WeeklyReport extends Equatable {
  final int? id;
  final int studentId;
  final String weekStart; // yyyy-MM-dd
  final double attendancePercent;
  final int presentDays;
  final int absentDays;
  final String homeworkStatus; // Done/Not Done/Pending
  final String teacherComment;
  final double feeBalance;
  final String feeLastDate;
  WeeklyReport({
    this.id,
    required this.studentId,
    required this.weekStart,
    required this.attendancePercent,
    required this.presentDays,
    required this.absentDays,
    required this.homeworkStatus,
    required this.teacherComment,
    required this.feeBalance,
    required this.feeLastDate,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'week_start': weekStart,
        'attendance_percent': attendancePercent,
        'present_days': presentDays,
        'absent_days': absentDays,
        'homework_status': homeworkStatus,
        'teacher_comment': teacherComment,
        'fee_balance': feeBalance,
        'fee_last_date': feeLastDate,
      };
  factory WeeklyReport.fromMap(Map<String, dynamic> m) => WeeklyReport(
        id: m['id'],
        studentId: m['student_id'],
        weekStart: m['week_start'] ?? '',
        attendancePercent: (m['attendance_percent'] ?? 0).toDouble(),
        presentDays: m['present_days'] ?? 0,
        absentDays: m['absent_days'] ?? 0,
        homeworkStatus: m['homework_status'] ?? '',
        teacherComment: m['teacher_comment'] ?? '',
        feeBalance: (m['fee_balance'] ?? 0).toDouble(),
        feeLastDate: m['fee_last_date'] ?? '',
      );
  @override
  List<Object?> get props => [id, studentId, weekStart];
}
