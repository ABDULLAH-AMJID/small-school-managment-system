import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/services/pdf_service.dart';
import 'package:small_school_management/services/whatsapp_service.dart';
import 'package:small_school_management/utils/app_theme.dart';

class ReportCardScreen extends StatefulWidget {
  const ReportCardScreen({super.key});
  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  final _db = DatabaseHelper();
  final _rollC = TextEditingController();
  Student? _student;
  List<Mark> _mid = [];
  List<Mark> _final = [];
  Map<String, int> _att = {'Present': 0, 'Absent': 0, 'Leave': 0};
  double _feeBalance = 0;
  String _feeLastDate = '';
  String _comment = '';
  bool _loading = false;

  Future<void> _loadReport() async {
    if (_rollC.text.isEmpty) return;
    setState(() => _loading = true);
    final students = await _db.getStudents();
    Student? s;
    for (final x in students) {
      if (x.rollNo == _rollC.text) {
        s = x;
        break;
      }
    }
    if (s == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Student not found')));
      return;
    }
    _student = s;
    final exams = await _db.getExams(className: s.className);
    // Pehle exam_type dekhte hain (v1.1.0 se), warna purane exams ke liye
    // naam se andaza lagate hain.
    bool isType(Exam e, String type, String nameHint) =>
        e.examType == type || e.name.toLowerCase().contains(nameHint);
    final midExams =
        exams.where((e) => isType(e, 'Mid Term', 'mid')).toList();
    final finalExams =
        exams.where((e) => isType(e, 'Final Term', 'final')).toList();
    if (midExams.isNotEmpty)
      _mid = await _db.getMarks(studentId: s.id!, examId: midExams.first.id!);
    if (finalExams.isNotEmpty)
      _final =
          await _db.getMarks(studentId: s.id!, examId: finalExams.first.id!);
    _att = await _db.attendanceStatsForStudent(s.id!);
    // Fee ka hisaab ab fee_payments (v1.1.0) se aata hai, purani fees table
    // se nahi — warna report card pe hamesha Rs 0 baqi dikhta.
    final ledger = await _db.feeLedgerFor(s);
    _feeBalance = ledger.totalBalance;
    _feeLastDate = ledger.pendingMonths.isEmpty
        ? '-'
        : FeeLedger.monthLabel(ledger.pendingMonths.last);
    setState(() => _loading = false);
  }

  Future<void> _generateAndShare() async {
    if (_student == null) return;
    setState(() => _loading = true);
    final pdf = await PdfService.generateReportCard(
      student: _student!,
      midTermMarks: _mid,
      finalMarks: _final,
      attendance: _att,
      teacherComment: _comment,
      feeBalance: _feeBalance,
      feeLastDate: _feeLastDate,
    );
    await WhatsAppService.sendReportPdf(context,
        parentPhone: _student!.parentPhone,
        studentName: _student!.name,
        pdfFile: pdf,
        comment: _comment);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report Card'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _tf(_rollC, 'Enter Roll No')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _loading ? null : _loadReport,
                    child: Text('Load')),
              ]),
              const SizedBox(height: 10),
              _buildField('Teacher Comment', (v) => _comment = v, maxLines: 2),
            ]),
          ),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _student == null
                      ? const Center(
                          child: Text('Enter roll number to load report.'))
                      : _buildReport()),
        ],
      ),
    );
  }

  Widget _buildField(String label, Function(String) onChanged,
      {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10)),
      onChanged: onChanged,
    );
  }

  Widget _buildReport() {
    final s = _student!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.name} - Report Card', style: AppTheme.heading),
              Text(
                  'Roll: ${s.rollNo} | Class: ${s.className} ${s.section} | Parent: ${s.parentName} (${s.parentPhone})',
                  style: AppTheme.caption),
              const Divider(),
              _infoRow('Attendance',
                  'Present: ${_att['Present']} | Absent: ${_att['Absent']} | Leave: ${_att['Leave']}'),
              _infoRow('Fee Balance', 'Rs ${_feeBalance.toStringAsFixed(0)}'),
              _infoRow('Fee Last Date', _feeLastDate),
            ]),
          )),
          const SizedBox(height: 12),
          _marksSection('Mid Term', _mid),
          const SizedBox(height: 12),
          _marksSection('Final', _final),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generateAndShare,
                icon: Icon(Icons.share),
                label: Text('Send Report Card via WhatsApp'),
              )),
        ],
      ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text('$l: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(v)
        ]),
      );

  Widget _marksSection(String title, List<Mark> marks) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTheme.subHeading),
      ...marks.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
                '${m.subject}: ${m.marksObtained.toStringAsFixed(0)} / ${m.totalMarks.toStringAsFixed(0)}',
                style: AppTheme.body),
          )),
      if (marks.isEmpty) Text('No marks', style: AppTheme.caption),
    ]);
  }

  Widget _tf(TextEditingController c, String l) => TextField(
      controller: c,
      decoration: InputDecoration(
          labelText: l,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}
