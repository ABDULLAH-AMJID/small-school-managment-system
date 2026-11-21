import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _db = DatabaseHelper();
  List<Exam> _exams = [];
  Map<int, List<ExamSubject>> _examSubjects = {};
  bool _loading = true;
  String _filterClass = '';
  List<String> _classes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _db.getExams();
    final classes = await _db.getClasses();
    final subs = <int, List<ExamSubject>>{};
    for (final e in all) {
      if (e.id != null) subs[e.id!] = await _db.getExamSubjects(e.id!);
    }
    if (!mounted) return;
    setState(() {
      _exams = all;
      _examSubjects = subs;
      _classes = classes;
      _loading = false;
    });
  }

  Future<void> _openForm({Exam? existing}) async {
    final result = await showModalBottomSheet<_ExamFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ExamForm(
        classes: _classes,
        existing: existing,
        existingSubjects: existing?.id == null
            ? const []
            : (_examSubjects[existing!.id!] ?? const []),
      ),
    );
    if (result == null) return;

    int examId;
    if (existing == null) {
      examId = await _db.insertExam(result.exam);
    } else {
      await _db.updateExam(result.exam);
      examId = existing.id!;
    }
    await _db.replaceExamSubjects(examId, result.subjects);
    _load();
  }

  Future<void> _delete(Exam e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${e.name} delete karein?'),
        content: const Text('Exam aur uske subjects hat jayenge. '
            'Entered marks DB mein rahenge.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (ok != true) return;
    if (e.id != null) await _db.deleteExamSubjectsForExam(e.id!);
    await _db.deleteExam(e.id!);
    _load();
  }

  String _prettyDate(String d) {
    final dt = DateTime.tryParse(d);
    return dt == null ? d : DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filterClass.isEmpty
        ? _exams
        : _exams.where((e) => e.className == _filterClass).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Exams'), leading: const BackButton()),
      floatingActionButton: FloatingActionButton(
        heroTag: 'exam_add',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filterClass.isEmpty,
                    onSelected: (_) => setState(() => _filterClass = ''),
                  ),
                ),
                for (final c in _classes)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _filterClass == c,
                      onSelected: (_) => setState(
                          () => _filterClass = _filterClass == c ? '' : c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? Center(
                        child: Text(
                            'Koi exam nahi bana.\n+ se naya exam add karein.',
                            textAlign: TextAlign.center,
                            style: AppTheme.caption))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (_, i) {
                            final e = visible[i];
                            final subs = _examSubjects[e.id] ?? const [];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: ListTile(
                                title: Row(children: [
                                  Expanded(
                                    child: Text('${e.name} — ${e.className}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(e.examType,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${_prettyDate(e.startDate)}  →  ${_prettyDate(e.endDate)}'),
                                      const SizedBox(height: 4),
                                      Text(
                                        subs.isEmpty
                                            ? 'Koi subject select nahi kiya gaya'
                                            : '${subs.length} subjects: '
                                                '${subs.map((s) => '${s.subject} (${s.totalMarks.toInt()})').join(', ')}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            color: AppTheme.accent, size: 21),
                                        onPressed: () => _openForm(existing: e),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppTheme.danger, size: 21),
                                        onPressed: () => _delete(e),
                                      ),
                                    ]),
                                onTap: () => _openForm(existing: e),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ExamFormResult {
  _ExamFormResult(this.exam, this.subjects);
  final Exam exam;
  final List<ExamSubject> subjects;
}

/// Exam ka add/edit form.
///
/// Dates: calendar se bhi select ho sakti hain aur type bhi ki ja sakti hain.
/// Start date default aaj ki hoti hai. Subjects class settings se aate hain,
/// aur har subject ka total us exam type ke mutabiq auto-fill hota hai.
class _ExamForm extends StatefulWidget {
  const _ExamForm({
    required this.classes,
    this.existing,
    this.existingSubjects = const [],
  });

  final List<String> classes;
  final Exam? existing;
  final List<ExamSubject> existingSubjects;

  @override
  State<_ExamForm> createState() => _ExamFormState();
}

class _ExamFormState extends State<_ExamForm> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _startC = TextEditingController();
  final _endC = TextEditingController();

  String? _class;
  String _examType = Exam.examTypes.first;

  List<ClassSubject> _classSubjects = [];
  final Set<String> _selected = {};
  final Map<String, TextEditingController> _totalCs = {};

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (e != null) {
      _nameC.text = e.name;
      _startC.text = e.startDate.isEmpty ? today : e.startDate;
      _endC.text = e.endDate;
      _class = e.className;
      _examType = e.examType;
      for (final s in widget.existingSubjects) {
        _selected.add(s.subject);
      }
    } else {
      // Start date = aaj (user ki request), end date khaali.
      _startC.text = today;
      if (widget.classes.isNotEmpty) _class = widget.classes.first;
    }
    _loadSubjects();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _startC.dispose();
    _endC.dispose();
    for (final c in _totalCs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final c = _class;
    if (c == null) {
      setState(() => _classSubjects = []);
      return;
    }
    final list = await _db.getClassSubjects(c);
    if (!mounted) return;
    setState(() {
      _classSubjects = list;
      _selected.removeWhere((s) => !list.any((cs) => cs.subject == s));
      _syncTotals();
    });
  }

  /// Class ya exam type badle to har subject ka total dobara set karo
  /// (user ne khud edit na kiya ho to).
  void _syncTotals() {
    for (final cs in _classSubjects) {
      final c = _totalCs.putIfAbsent(cs.subject, () => TextEditingController());
      c.text = cs.totalFor(_examType).toStringAsFixed(0);
    }
  }

  Future<void> _pickDate(TextEditingController c,
      {required String helpText, DateTime? first}) async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(c.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: first ?? DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: helpText,
    );
    if (picked != null) {
      setState(() => c.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  String? _validateDate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = DateTime.tryParse(v.trim());
    if (d == null) return 'yyyy-MM-dd format';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.97,
        builder: (_, controller) => Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(isNew ? 'Add Exam' : 'Edit Exam',
                  style: AppTheme.subHeading),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameC,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Exam Name *', hintText: 'e.g. Mid Term 2026'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.classes.contains(_class) ? _class : null,
                    decoration: const InputDecoration(labelText: 'Class *'),
                    items: widget.classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _class = v);
                      _loadSubjects();
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _examType,
                    decoration: const InputDecoration(labelText: 'Exam Type'),
                    items: Exam.examTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _examType = v;
                        _syncTotals();
                      });
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _startC,
                    decoration: const InputDecoration(
                      labelText: 'Start Date *',
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: Icon(Icons.calendar_month, size: 18),
                    ),
                    keyboardType: TextInputType.datetime,
                    onTap: () => _pickDate(_startC, helpText: 'Start Date'),
                    validator: _validateDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _endC,
                    decoration: const InputDecoration(
                      labelText: 'End Date *',
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: Icon(Icons.calendar_month, size: 18),
                    ),
                    keyboardType: TextInputType.datetime,
                    onTap: () => _pickDate(_endC,
                        helpText: 'End Date',
                        first: DateTime.tryParse(_startC.text)),
                    validator: _validateDate,
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                'Date pe tap kar ke calendar khulta hai, ya seedha type bhi kar '
                'sakte hain (yyyy-MM-dd).',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 14),
              const Divider(),
              Text('Subjects of this exam', style: AppTheme.subHeading),
              Text(
                'Class $_class ke subjects. Total marks class settings se '
                '$_examType ke hisaab se aaye hain — zaroorat ho to badal lein.',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 8),
              if (_classSubjects.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _class == null
                        ? 'Pehle class select karein.'
                        : 'Class $_class mein koi subject add nahi kiya gaya. '
                            'Classes → $_class → + se subjects add karein, '
                            'phir yahan select kar sakenge.',
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.textDark),
                  ),
                ),
              for (final cs in _classSubjects) _subjectRow(cs),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Save Exam' : 'Update Exam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subjectRow(ClassSubject cs) {
    final checked = _selected.contains(cs.subject);
    final c = _totalCs.putIfAbsent(cs.subject, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Checkbox(
              value: checked,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(cs.subject);
                } else {
                  _selected.remove(cs.subject);
                }
              }),
            ),
          ),
          Expanded(
            child: Text(cs.subject,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: 88,
            child: TextField(
              controller: c,
              enabled: checked,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Total',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_class == null) return;
    final start = DateTime.parse(_startC.text.trim());
    final end = DateTime.parse(_endC.text.trim());
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('End date start date se pehle nahi ho sakti.')));
      return;
    }
    final subjects = <ExamSubject>[];
    for (final cs in _classSubjects) {
      if (!_selected.contains(cs.subject)) continue;
      subjects.add(ExamSubject(
        examId: 0, // replaceExamSubjects mein asal exam id set hoti hai
        subject: cs.subject,
        totalMarks: double.tryParse(_totalCs[cs.subject]?.text.trim() ?? '') ??
            cs.totalFor(_examType),
      ));
    }
    Navigator.pop(
      context,
      _ExamFormResult(
        Exam(
          id: widget.existing?.id,
          name: _nameC.text.trim(),
          className: _class!,
          startDate: _startC.text.trim(),
          endDate: _endC.text.trim(),
          examType: _examType,
        ),
        subjects,
      ),
    );
  }
}
