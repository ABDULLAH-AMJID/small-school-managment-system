import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/screens/marks_entry_screen.dart';
import 'package:small_school_management/utils/app_theme.dart';

/// Marks entry ka flow:
///   1. Class select karein
///   2. Us class ka exam select karein
///   3. Us class ke students ki list (kitne subjects ke marks bhare, saath)
///   4. Student pe tap → us ke tamam subjects ke marks ek screen pe
class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});
  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  final _db = DatabaseHelper();

  List<String> _classes = [];
  String? _class;
  List<Exam> _exams = [];
  Exam? _exam;
  List<Student> _students = [];
  List<ExamSubject> _examSubjects = [];
  Map<int, List<Mark>> _marksByStudent = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await _db.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      // Sirf woh classes jinka koi exam bana ho — warna list lambi aur bekaar.
      _loading = false;
    });
  }

  Future<void> _selectClass(String c) async {
    final exams = await _db.getExams(className: c);
    if (!mounted) return;
    setState(() {
      _class = c;
      _exams = exams;
      _exam = null;
      _students = [];
      _examSubjects = [];
      _marksByStudent = {};
    });
  }

  Future<void> _selectExam(Exam e) async {
    final students = await _db.getStudents(className: e.className);
    final subjects = await _db.getExamSubjects(e.id!);
    final marks = await _db.getMarksByStudentForExam(e.id!);
    if (!mounted) return;
    setState(() {
      _exam = e;
      _students = students;
      _examSubjects = subjects;
      _marksByStudent = marks;
    });
  }

  Future<void> _refresh() async {
    if (_exam == null) return;
    await _selectExam(_exam!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Marks Entry'), leading: const BackButton()),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _stepHeader(1, 'Select Class'),
                _classChips(),
                if (_class != null) ...[
                  _stepHeader(2, 'Select Exam'),
                  _examList(),
                ],
                if (_exam != null) ...[
                  _stepHeader(3, 'Students of Class $_class',
                      trailing: '${_students.length} students'),
                  Expanded(child: _studentList()),
                ],
                if (_exam == null) const Spacer(),
              ],
            ),
    );
  }

  Widget _stepHeader(int n, String title, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text('$n',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          if (trailing != null) Text(trailing, style: AppTheme.caption),
        ]),
      );

  Widget _classChips() => SizedBox(
        height: 44,
        child: _classes.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('Classes tab mein pehle classes add karein.',
                    style: AppTheme.caption),
              )
            : ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final c in _classes)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _class == c,
                        onSelected: (_) => _selectClass(c),
                      ),
                    ),
                ],
              ),
      );

  Widget _examList() {
    if (_exams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Class $_class ka koi exam nahi bana. Exams tab se exam banayein '
            '(aur us mein subjects select karna na bhoolein).',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final e in _exams)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _examCard(e),
            ),
        ],
      ),
    );
  }

  Widget _examCard(Exam e) {
    final selected = _exam?.id == e.id;
    return GestureDetector(
      onTap: () => _selectExam(e),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppTheme.primary : const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textDark)),
            const SizedBox(height: 2),
            Text(e.examType,
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : AppTheme.accent)),
            const SizedBox(height: 2),
            Text('${e.startDate} → ${e.endDate}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white70 : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _studentList() {
    if (_examSubjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Is exam mein koi subject select nahi kiya gaya.\n\n'
            'Exams → ${_exam!.name} → edit → subjects select karein.',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
        ),
      );
    }
    if (_students.isEmpty) {
      return Center(
          child: Text('Class $_class mein koi student nahi hai.',
              style: AppTheme.caption));
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _students.length,
        itemBuilder: (_, i) {
          final s = _students[i];
          final marks = _marksByStudent[s.id] ?? const [];
          final done = marks.length;
          final total = _examSubjects.length;
          final complete = done >= total && total > 0;
          final obtained = marks.fold(0.0, (a, m) => a + m.marksObtained);
          final max = marks.fold(0.0, (a, m) => a + m.totalMarks);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: complete
                  ? AppTheme.success.withOpacity(0.15)
                  : AppTheme.primary.withOpacity(0.1),
              child: Text(s.rollNo,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: complete ? AppTheme.success : AppTheme.primary)),
            ),
            title: Text(s.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              done == 0
                  ? 'Koi marks enter nahi hue'
                  : '$done/$total subjects  •  '
                      '${obtained.toStringAsFixed(0)}/${max.toStringAsFixed(0)}'
                      '${max > 0 ? '  (${(obtained / max * 100).toStringAsFixed(0)}%)' : ''}',
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                complete ? Icons.check_circle : Icons.edit_outlined,
                color: complete ? AppTheme.success : AppTheme.accent,
                size: 20,
              ),
              const Icon(Icons.chevron_right, size: 20),
            ]),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MarksEntryScreen(student: s, exam: _exam!),
                ),
              );
              _refresh();
            },
          );
        },
      ),
    );
  }
}
