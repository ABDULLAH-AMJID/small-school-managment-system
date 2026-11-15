import 'package:equatable/equatable.dart';

/// ---------- ROLES ---------- ///
enum AppRole { admin, teacher, parent }
extension AppRoleExt on AppRole {
  String get label {
    switch (this) {
      case AppRole.admin: return 'Admin';
      case AppRole.teacher: return 'Ustad';
      case AppRole.parent: return 'Walidain';
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
      );
  @override
  List<Object?> get props => [id, rollNo, className];
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
  factory StudentAttendance.fromMap(Map<String, dynamic> m) => StudentAttendance(
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
  factory TeacherAttendance.fromMap(Map<String, dynamic> m) => TeacherAttendance(
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
  Exam({
    this.id,
    required this.name,
    required this.className,
    required this.startDate,
    required this.endDate,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'class_name': className,
        'start_date': startDate,
        'end_date': endDate,
      };
  factory Exam.fromMap(Map<String, dynamic> m) => Exam(
        id: m['id'],
        name: m['name'] ?? '',
        className: m['class_name'] ?? '',
        startDate: m['start_date'] ?? '',
        endDate: m['end_date'] ?? '',
      );
  @override
  List<Object?> get props => [id, name, className];
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
