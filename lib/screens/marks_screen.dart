import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});
  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  final _db = DatabaseHelper();
  final _subjectC = TextEditingController();
  final _obtainedC = TextEditingController();
  final _totalC = TextEditingController(text: '100');
  List<Student> _students = [];
  List<Exam> _exams = [];
  int? _selectedStudentId;
  int? _selectedExamId;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final s = await _db.getStudents();
    final e = await _db.getExams();
    setState(() { _students = s; _exams = e; _loading = false; });
  }
  Future<void> _save() async {
    if (_selectedStudentId == null || _selectedExamId == null || _subjectC.text.isEmpty) return;
    await _db.insertMark(Mark(
      studentId: _selectedStudentId!, examId: _selectedExamId!, subject: _subjectC.text,
      marksObtained: double.tryParse(_obtainedC.text) ?? 0, totalMarks: double.tryParse(_totalC.text) ?? 100,
    ));
    _subjectC.clear(); _obtainedC.clear(); _totalC.text = '100';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marks Entry'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(flex: 2, child: DropdownButton<Student>(
                  value: _students.firstWhereOrNull((s) => s.id == _selectedStudentId),
                  hint: Text('Select Student'),
                  items: _students.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.rollNo})'))).toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v?.id),
                  isExpanded: true,
                )),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: DropdownButton<Exam>(
                  value: _exams.firstWhereOrNull((e) => e.id == _selectedExamId),
                  hint: Text('Select Exam'),
                  items: _exams.map((e) => DropdownMenuItem(value: e, child: Text('${e.name} - ${e.className}'))).toList(),
                  onChanged: (v) => setState(() => _selectedExamId = v?.id),
                  isExpanded: true,
                )),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tf(_subjectC, 'Subject')),
                const SizedBox(width: 8),
                Expanded(child: _tf(_obtainedC, 'Obtained')),
                const SizedBox(width: 8),
                Expanded(child: _tf(_totalC, 'Total')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _save, child: Text('Add')),
              ]),
            ]),
          ),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : const Center(child: Text('Marks saved to database.'))),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }

  Widget _tf(TextEditingController c, String l) => TextField(controller: c, decoration: InputDecoration(labelText: l, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) if (test(e)) return e;
    return null;
  }
}
