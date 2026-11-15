import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final _db = DatabaseHelper();
  final _nameC = TextEditingController();
  final _subjectC = TextEditingController();
  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _qualC = TextEditingController();
  final _salaryC = TextEditingController();
  List<Teacher> _teachers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final list = await _db.getTeachers();
    setState(() { _teachers = list; _loading = false; });
  }

  Future<void> _save() async {
    if (_nameC.text.isEmpty) return;
    await _db.insertTeacher(Teacher(
      name: _nameC.text, subject: _subjectC.text, phone: _phoneC.text,
      email: _emailC.text, qualification: _qualC.text,
      salary: double.tryParse(_salaryC.text) ?? 0,
    ));
    _nameC.clear(); _subjectC.clear(); _phoneC.clear(); _emailC.clear(); _qualC.clear(); _salaryC.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teachers'), leading: const BackButton()),
      body: Column(
        children: [
          Card(margin: const EdgeInsets.all(8), child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Teacher', style: AppTheme.subHeading),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _tf(_nameC, 'Name')), const SizedBox(width: 8), Expanded(child: _tf(_subjectC, 'Subject'))]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _tf(_phoneC, 'Phone')), const SizedBox(width: 8), Expanded(child: _tf(_emailC, 'Email'))]),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _tf(_qualC, 'Qualification')), const SizedBox(width: 8), Expanded(child: _tf(_salaryC, 'Salary'))]),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: _save, child: Text('Save Teacher'))),
              ],
            ),
          )),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
            itemCount: _teachers.length,
            itemBuilder: (_, i) {
              final t = _teachers[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${t.subject}  |  ${t.phone}  |  Rs ${t.salary.toStringAsFixed(0)}'),
                trailing: IconButton(icon: Icon(Icons.delete, color: AppTheme.danger), onPressed: () async { await _db.deleteTeacher(t.id!); _load(); }),
              );
            },
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }

  Widget _tf(TextEditingController c, String label) => TextField(controller: c, decoration: InputDecoration(labelText: label, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}
