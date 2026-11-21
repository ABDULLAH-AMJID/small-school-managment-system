import 'package:flutter/material.dart';
import 'package:small_school_management/utils/app_theme.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/screens/splash_screen.dart';
import 'package:small_school_management/screens/login_screen.dart';
import 'package:small_school_management/screens/dashboard_screen.dart';
import 'package:small_school_management/screens/student_screen.dart';
import 'package:small_school_management/screens/teacher_screen.dart';
import 'package:small_school_management/screens/class_screen.dart';
import 'package:small_school_management/screens/attendance_screen.dart';
import 'package:small_school_management/screens/exam_screen.dart';
import 'package:small_school_management/screens/timetable_screen.dart';
import 'package:small_school_management/screens/marks_screen.dart';
import 'package:small_school_management/screens/fee_screen.dart';
import 'package:small_school_management/screens/report_card_screen.dart';
import 'package:small_school_management/screens/weekly_report_screen.dart';
import 'package:small_school_management/screens/settings_screen.dart';

void main() {
  runApp(const SchoolApp());
}

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final widgets = {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) =>
              DashboardScreen(currentUser: settings.arguments as AppUser?),
          '/students': (context) => const StudentScreen(),
          '/teachers': (context) => const TeacherScreen(),
          '/classes': (context) => const ClassScreen(),
          '/attendance': (context) => const AttendanceScreen(),
          '/exams': (context) => const ExamScreen(),
          '/timetable': (context) => const TimetableScreen(),
          '/marks': (context) => const MarksScreen(),
          '/fees': (context) => const FeeScreen(),
          '/reportcard': (context) => const ReportCardScreen(),
          '/weeklyreport': (context) => const WeeklyReportScreen(),
          '/settings': (context) => const SettingsScreen(),
        };
        final builder = widgets[settings.name];
        if (builder == null) return null;
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}
