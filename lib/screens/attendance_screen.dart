import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late TabController _tab;
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<Student> _students = [];
  Map<int, String> _picks = {}; // studentId -> status
  String _selectedClass = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await _db.getClasses();
    if (classes.isNotEmpty) setState(() { _selectedClass = classes.first; _loadStudents(); });
  }

  Future<void> _loadStudents() async {
    final list = await _db.getStudents(className: _selectedClass);
    setState(() { _students = list; _picks.clear(); });
    // load existing attendance for today
    final existing = await _db.getStudentAttendance(className: _selectedClass, date: _date);
    for (final e in existing) _picks[e.studentId] = e.status;
    setState(() => _loading = false);
  }

  Future<void> _saveAttendance() async {
    for (final s in _students) {
      final status = _picks[s.id!] ?? 'Present';
      await _db.markStudentAttendance(StudentAttendance(studentId: s.id!, date: _date, status: status, className: _selectedClass, markedBy: 'Admin'));
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Attendance'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Row(children: [
                Expanded(flex: 2, child: _classDropdown()),
                const SizedBox(width: 8),
                Expanded(child: InkWell(onTap: _pickDate, child: AbsorbPointer(child: _tf(_date, 'Date')))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _students.isEmpty ? null : _saveAttendance, child: Text('Save')),
              ]),
              const SizedBox(height: 8),
              if (_loading) const Center(child: CircularProgressIndicator()),
            ]),
          ),
          Expanded(child: _students.isEmpty
              ? const Center(child: Text('No students in this class.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (_, i) {
                    final s = _students[i];
                    final current = _picks[s.id!] ?? 'Present';
                    return ListTile(
                      leading: CircleAvatar(child: Text(s.rollNo.isNotEmpty ? s.rollNo[0] : '?', style: const TextStyle(fontSize: 10))),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Roll: ${s.rollNo}  Phone: ${s.parentPhone}'),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Present', label: Text('P')),
                          ButtonSegment(value: 'Absent', label: Text('A')),
                          ButtonSegment(value: 'Leave', label: Text('L')),
                        ],
                        selected: {current},
                        onSelectionChanged: (set) => setState(() => _picks[s.id!] = set.first),
                      ),
                    );
                  },
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _loadClasses == null ? null : _loadStudents, child: Icon(Icons.refresh)),
    );
  }

  Widget _classDropdown() {
    return FutureBuilder<List<String>>(
      future: _db.getClasses(),
      builder: (context, snap) {
        final classes = snap.data ?? [];
        return DropdownButton<String>(
          value: classes.contains(_selectedClass) ? _selectedClass : (classes.isNotEmpty ? classes.first : null),
          items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() { _selectedClass = v ?? ''; _loading = true; _loadStudents(); }),
          isExpanded: true,
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) {
      setState(() { _date = DateFormat('yyyy-MM-dd').format(picked); _loading = true; _loadStudents(); });
    }
  }

  Widget _tf(String v, String l) => TextField(decoration: InputDecoration(labelText: l, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}
