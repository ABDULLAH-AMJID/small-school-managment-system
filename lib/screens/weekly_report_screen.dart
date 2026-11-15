import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/services/pdf_service.dart';
import 'package:small_school_management/services/whatsapp_service.dart';
import 'package:small_school_management/utils/app_theme.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});
  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final _db = DatabaseHelper();
  final _commentC = TextEditingController();
  List<Student> _students = [];
  Student? _selected;
  String _hwStatus = 'Done';
  late String _weekStart;
  double _attPct = 0;
  int _present = 0, _absent = 0;
  double _feeBal = 0;
  String _feeLast = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateFormat('yyyy-MM-dd').format(monday);
    _load();
  }

  Future<void> _load() async {
    final s = await _db.getStudents();
    setState(() { _students = s; _loading = false; });
  }

  Future<void> _calc() async {
    if (_selected == null) return;
    final stats = await _db.attendanceStatsForStudent(_selected!.id!);
    final total = (stats['Present'] ?? 0) + (stats['Absent'] ?? 0) + (stats['Leave'] ?? 0);
    setState(() {
      _present = stats['Present'] ?? 0;
      _absent = stats['Absent'] ?? 0;
      _attPct = total == 0 ? 0 : (_present / total) * 100;
    });
    final fees = await _db.getFees(studentId: _selected!.id!, status: 'Pending');
    _feeBal = fees.fold(0, (sum, f) => sum + f.balance);
    _feeLast = fees.isNotEmpty ? fees.first.dueDate : '-';
  }

  Future<void> _sendWeekly() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    await _calc();
    await _db.insertWeeklyReport(WeeklyReport(
      studentId: _selected!.id!, weekStart: _weekStart,
      attendancePercent: _attPct, presentDays: _present, absentDays: _absent,
      homeworkStatus: _hwStatus, teacherComment: _commentC.text,
      feeBalance: _feeBal, feeLastDate: _feeLast,
    ));
    final pdf = await PdfService.generateWeeklyReport(
      student: _selected!, attendancePercent: _attPct, presentDays: _present,
      absentDays: _absent, homeworkStatus: _hwStatus, teacherComment: _commentC.text,
      feeBalance: _feeBal, feeLastDate: _feeLast, weekStart: _weekStart,
    );
    await WhatsAppService.sendReportPdf(context, parentPhone: _selected!.parentPhone, studentName: _selected!.name, pdfFile: pdf, comment: _commentC.text);
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weekly report sent to parent via WhatsApp!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weekly Report to Parents'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(flex: 2, child: DropdownButton<Student>(
                  value: _selected,
                  hint: Text('Select Student'),
                  items: _students.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.rollNo})'))).toList(),
                  onChanged: (v) => setState(() => _selected = v),
                  isExpanded: true,
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _commentC, decoration: const InputDecoration(labelText: 'Teacher Comment', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10)))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(
                  controller: TextEditingController(text: _weekStart),
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Week Start', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10)),
                )),
                const SizedBox(width: 8),
                Expanded(child: DropdownButton<String>(
                  value: _hwStatus,
                  items: const [
                    DropdownMenuItem(value: 'Done', child: Text('Done')),
                    DropdownMenuItem(value: 'Not Done', child: Text('Not Done')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  ],
                  onChanged: (v) => setState(() => _hwStatus = v ?? 'Done'),
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: _calc, child: Text('Calculate Attendance & Fee'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: _saving ? null : _sendWeekly, child: Text('Send PDF to Parent via WhatsApp'))),
              ]),
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Card(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Text('Weekly Summary', style: AppTheme.subHeading),
                    Text('Attendance: ${_attPct.toStringAsFixed(1)}%  (Present: $_present, Absent: $_absent)', style: AppTheme.body),
                    Text('Homework: $_hwStatus', style: AppTheme.body),
                    Text('Fee Balance: Rs ${_feeBal.toStringAsFixed(0)}', style: AppTheme.body),
                    Text('Last Date: $_feeLast', style: AppTheme.body),
                  ]),
                )),
              ],
            ]),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }
}
