import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _db = DatabaseHelper();
  final _classC = TextEditingController();
  final _dayC = TextEditingController(text: 'Monday');
  final _periodC = TextEditingController(text: '1');
  final _subjectC = TextEditingController();
  final _teacherIdC = TextEditingController();
  final _startC = TextEditingController();
  final _endC = TextEditingController();
  final days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  String _selectedClass = '';
  List<TimetableEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await _db.getClasses();
    if (classes.isNotEmpty)
      setState(() {
        _selectedClass = classes.first;
        _loadTimetable();
      });
  }

  Future<void> _loadTimetable() async {
    final list = await _db.getTimetable(_selectedClass);
    setState(() {
      _entries = list..sort((a, b) => a.day.compareTo(b.day));
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_classC.text.isEmpty || _subjectC.text.isEmpty) return;
    await _db.insertTimetable(TimetableEntry(
      className: _classC.text,
      day: _dayC.text,
      period: int.tryParse(_periodC.text) ?? 1,
      subject: _subjectC.text,
      teacherId: int.tryParse(_teacherIdC.text) ?? 0,
      timeStart: _startC.text,
      timeEnd: _endC.text,
    ));
    _subjectC.clear();
    _teacherIdC.clear();
    _startC.clear();
    _endC.clear();
    _loadTimetable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Timetable'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(
                  flex: 2,
                  child: FutureBuilder<List<String>>(
                    future: _db.getClasses(),
                    builder: (context, snap) {
                      final classes = snap.data ?? [];
                      return DropdownButton<String>(
                        value: classes.contains(_selectedClass)
                            ? _selectedClass
                            : (classes.isNotEmpty ? classes.first : null),
                        items: classes
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedClass = v ?? '';
                          _loading = true;
                          _loadTimetable();
                        }),
                        isExpanded: true,
                      );
                    },
                  )),
              const SizedBox(width: 8),
              ElevatedButton(
                  onPressed: _entries.isEmpty ? null : () {},
                  child: Text('Refresh')),
            ]),
          ),
          Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Period', style: AppTheme.subHeading),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _tf(_classC, 'Class')),
                        const SizedBox(width: 8),
                        Expanded(child: _tf(_dayC, 'Day'))
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _tf(_periodC, 'Period')),
                        const SizedBox(width: 8),
                        Expanded(child: _tf(_subjectC, 'Subject'))
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _tf(_teacherIdC, 'Teacher ID')),
                        const SizedBox(width: 8),
                        Expanded(child: _tf(_startC, 'Start Time'))
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _tf(_endC, 'End Time')),
                        const SizedBox(width: 8),
                        SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                                onPressed: _save, child: Text('Add')))
                      ]),
                    ]),
              )),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? const Center(
                          child: Text('No timetable for this class.'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (_, i) {
                            final t = _entries[i];
                            return ListTile(
                              title: Text('${t.day} - Period ${t.period}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${t.subject}  ${t.timeStart} - ${t.timeEnd}  (Teacher ID: ${t.teacherId})'),
                            );
                          })),
        ],
      ),
      floatingActionButton:
          FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }

  Widget _tf(TextEditingController c, String l) => TextField(
      controller: c,
      decoration: InputDecoration(
          labelText: l,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}
