import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

/// Ek student ke ek exam ke tamam subjects ke marks — ek hi screen pe.
///
/// Flow: Marks tab → class → exam → student → yeh screen.
class MarksEntryScreen extends StatefulWidget {
  const MarksEntryScreen({
    super.key,
    required this.student,
    required this.exam,
  });

  final Student student;
  final Exam exam;

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  List<ExamSubject> _subjects = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;
  bool _hasExisting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final subjects = await _db.getExamSubjects(widget.exam.id!);
    final existing = await _db.getMarks(
        studentId: widget.student.id!, examId: widget.exam.id!);
    final bySubject = {for (final m in existing) m.subject: m};

    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    for (final s in subjects) {
      _controllers[s.subject] = TextEditingController(
        text: bySubject[s.subject]
                ?.marksObtained
                .toStringAsFixed(0)
                .replaceFirst(RegExp(r'\.0$'), '') ??
            '',
      );
    }

    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _hasExisting = existing.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      for (final s in _subjects) {
        final raw = _controllers[s.subject]?.text.trim() ?? '';
        if (raw.isEmpty) continue; // khali = is subject ke marks nahi bhare
        final obtained = double.tryParse(raw) ?? 0;
        await _db.upsertMark(Mark(
          studentId: widget.student.id!,
          examId: widget.exam.id!,
          subject: s.subject,
          marksObtained: obtained,
          totalMarks: s.totalMarks,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    setState(() => _hasExisting = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Marks save ho gaye.'),
      backgroundColor: AppTheme.success,
    ));
  }

  // ---- totals ----
  double get _obtainedTotal {
    var sum = 0.0;
    for (final s in _subjects) {
      sum += double.tryParse(_controllers[s.subject]?.text.trim() ?? '') ?? 0;
    }
    return sum;
  }

  double get _maxTotal => _subjects.fold(0.0, (sum, s) => sum + s.totalMarks);

  double? get _percentage {
    if (_maxTotal <= 0) return null;
    return (_obtainedTotal / _maxTotal) * 100;
  }

  static String gradeFor(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    if (pct >= 40) return 'E';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final pct = _percentage;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Is exam mein koi subject add nahi kiya gaya.\n\n'
                      'Exams → ${widget.exam.name} → edit kar ke subjects '
                      'select karein.',
                      textAlign: TextAlign.center,
                      style: AppTheme.caption,
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                    children: [
                      _headerCard(s, pct),
                      const SizedBox(height: 10),
                      for (final sub in _subjects) _subjectTile(sub),
                      const SizedBox(height: 10),
                      Text(
                        _hasExisting
                            ? 'Pehle se save shuda marks dikha rahe hain — '
                                'badal kar dobara Save dabayein.'
                            : 'Khali chhore gaye subject ke marks save nahi honge.',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _subjects.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_obtainedTotal.toStringAsFixed(0)} / ${_maxTotal.toStringAsFixed(0)}'
                          '${pct == null ? '' : '  (${pct.toStringAsFixed(1)}%)'}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (pct != null)
                          Text('Grade ${gradeFor(pct)}',
                              style: AppTheme.caption),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveAll,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: const Text('Save Marks'),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  Widget _headerCard(Student s, double? pct) => Card(
        color: AppTheme.primary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary,
              child: Text(s.name.isNotEmpty ? s.name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Roll ${s.rollNo}  •  Class ${s.className} ${s.section}'
                      .trim()),
                  const SizedBox(height: 4),
                  Text('${widget.exam.name} (${widget.exam.examType})',
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
            if (pct != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pct >= 40
                      ? AppTheme.success.withOpacity(0.15)
                      : AppTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(gradeFor(pct),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: pct >= 40 ? AppTheme.success : AppTheme.danger)),
              ),
          ]),
        ),
      );

  Widget _subjectTile(ExamSubject sub) {
    final c = _controllers[sub.subject]!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.subject,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('out of ${sub.totalMarks.toStringAsFixed(0)}',
                    style: AppTheme.caption),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: TextFormField(
              controller: c,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '—',
                isDense: true,
                suffixText: '/${sub.totalMarks.toStringAsFixed(0)}',
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              ),
              validator: (v) {
                final raw = v?.trim() ?? '';
                if (raw.isEmpty) return null;
                final n = double.tryParse(raw);
                if (n == null) return 'Number?';
                if (n < 0) return 'Negative?';
                if (n > sub.totalMarks) return 'Max ${sub.totalMarks.toInt()}';
                return null;
              },
            ),
          ),
        ]),
      ),
    );
  }
}
