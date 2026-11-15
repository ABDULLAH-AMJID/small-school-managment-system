import 'package:flutter/material.dart';
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
  final _nameC = TextEditingController();
  final _classC = TextEditingController();
  final _startC = TextEditingController();
  final _endC = TextEditingController();
  List<Exam> _exams = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final list = await _db.getExams(); setState(() { _exams = list; _loading = false; }); }
  Future<void> _save() async {
    if (_nameC.text.isEmpty || _classC.text.isEmpty) return;
    await _db.insertExam(Exam(name: _nameC.text, className: _classC.text, startDate: _startC.text, endDate: _endC.text));
    _nameC.clear(); _classC.clear(); _startC.clear(); _endC.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exam Schedule'), leading: const BackButton()),
      body: Column(
        children: [
          Card(margin: const EdgeInsets.all(8), child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add Exam', style: AppTheme.subHeading),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: _tf(_nameC, 'Exam Name (Mid Term/Final)')), const SizedBox(width: 8), Expanded(child: _tf(_classC, 'Class')]),
              const SizedBox(height: 10),
              Expanded(child: _tf(_startC, 'Start Date (yyyy-MM-dd)')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_endC, 'End Date (yyyy-MM-dd)')),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: _save, child: Text('Save Exam'))),
            ])),
          )),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _exams.isEmpty
              ? const Center(child: Text('No exams scheduled.'))
              : ListView.builder(itemCount: _exams.length, itemBuilder: (_, i) {
                  final e = _exams[i];
                  return ListTile(
                    title: Text('${e.name} - ${e.className}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${e.startDate} to ${e.endDate}'),
                    trailing: IconButton(icon: Icon(Icons.delete, color: AppTheme.danger), onPressed: () async { await _db.deleteExam(e.id!); _load(); }),
                  );
                })),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }

  Widget _tf(TextEditingController c, String l) => TextField(controller: c, decoration: InputDecoration(labelText: l, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}
