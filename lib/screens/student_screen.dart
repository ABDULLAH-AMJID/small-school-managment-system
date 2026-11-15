import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});
  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final _db = DatabaseHelper();
  final _nameC = TextEditingController();
  final _rollC = TextEditingController();
  final _classC = TextEditingController();
  final _sectionC = TextEditingController();
  final _phoneC = TextEditingController();
  final _parentNameC = TextEditingController();
  final _parentPhoneC = TextEditingController();
  final _addressC = TextEditingController();
  List<Student> _students = [];
  bool _loading = true;
  String _filterClass = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final classes = await _db.getClasses();
    final list = await _db.getStudents(className: _filterClass.isEmpty ? null : _filterClass);
    setState(() { _students = list; _loading = false; });
  }

  Future<void> _save() async {
    if (_nameC.text.isEmpty || _rollC.text.isEmpty || _classC.text.isEmpty) return;
    await _db.insertStudent(Student(
      name: _nameC.text, rollNo: _rollC.text, className: _classC.text,
      section: _sectionC.text, phone: _phoneC.text,
      parentName: _parentNameC.text, parentPhone: _parentPhoneC.text,
      address: _addressC.text,
    ));
    _clear(); _load();
  }

  void _clear() { _nameC.clear(); _rollC.clear(); _classC.clear(); _sectionC.clear(); _phoneC.clear(); _parentNameC.clear(); _parentPhoneC.clear(); _addressC.clear(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Students'), leading: const BackButton()),
      body: Column(
        children: [
          _buildAddForm(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => setState(() {}), child: Icon(Icons.add)),
    );
  }

  Widget _buildAddForm() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Student', style: AppTheme.subHeading),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tf(_nameC, 'Name')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_rollC, 'Roll No')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tf(_classC, 'Class (e.g. 10th)')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_sectionC, 'Section')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tf(_phoneC, 'Student Phone')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_parentNameC, 'Parent Name')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tf(_parentPhoneC, 'Parent Phone')),
              const SizedBox(width: 8),
              Expanded(child: _tf(_addressC, 'Address')),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: _save, child: Text('Save Student'))),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label) => TextField(controller: c, decoration: InputDecoration(labelText: label, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));

  Widget _buildList() {
    return _students.isEmpty
        ? const Center(child: Text('No students added yet.'))
        : ListView.builder(
            itemCount: _students.length,
            itemBuilder: (_, i) {
              final s = _students[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.rollNo}  |  ${s.className}  |  Parent: ${s.parentPhone}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(Icons.edit, color: AppTheme.accent), onPressed: () {}),
                  IconButton(icon: Icon(Icons.delete, color: AppTheme.danger), onPressed: () async {
                    await _db.deleteStudent(s.id!); _load();
                  }),
                ]),
              );
            },
          );
  }
}
