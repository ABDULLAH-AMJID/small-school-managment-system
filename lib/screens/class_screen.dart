import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

/// Class settings: har class ki monthly fee, us class ke subjects, aur har
/// subject ke marks totals (mid / final / weekly / monthly).
///
/// Yeh poori app ka "source of truth" hai — exam banate waqt subjects yahin se
/// aate hain, marks ke total yahin se, aur fee ka hisaab bhi yahin se.
class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  final _db = DatabaseHelper();
  List<SchoolClass> _classes = [];
  Map<String, int> _subjectCounts = {};
  Map<String, int> _studentCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final classes = await _db.getSchoolClasses(activeOnly: false);
    final counts = <String, int>{};
    for (final c in classes) {
      counts[c.name] = (await _db.getClassSubjects(c.name)).length;
    }
    final students = await _db.getStudents();
    final scounts = <String, int>{};
    for (final s in students) {
      scounts[s.className] = (scounts[s.className] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _subjectCounts = counts;
      _studentCounts = scounts;
      _loading = false;
    });
  }

  Future<void> _editClass(SchoolClass? c) async {
    final saved = await showDialog<SchoolClass>(
      context: context,
      builder: (_) => _ClassFormDialog(existing: c),
    );
    if (saved == null) return;
    if (c == null) {
      await _db.insertClass(saved);
    } else {
      await _db.updateClass(saved);
    }
    _load();
  }

  Future<void> _deleteClass(SchoolClass c) async {
    final students = (await _db.getStudents(className: c.name)).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${c.name}?'),
        content: Text(students > 0
            ? 'Is class mein $students students hain. Class settings delete '
                'ho jayengi (subjects aur fee), lekin students ka record '
                'qayam rahega.'
            : 'Class settings delete ho jayengi.'),
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
    await _db.deleteClass(c.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classes'), leading: const BackButton()),
      floatingActionButton: FloatingActionButton(
        heroTag: 'class_add',
        onPressed: () => _editClass(null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: Text(
                      'Har class ki fee, subjects aur marks yahan set karein. '
                      'Exam aur fee ka poora hisaab inhi settings se chalta hai.',
                      style: AppTheme.caption,
                    ),
                  ),
                  for (final c in _classes)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            c.name.length <= 4
                                ? c.name
                                : c.name.substring(0, 3),
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        title: Text(c.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                                'Fee: Rs ${c.monthlyFee.toStringAsFixed(0)} / month'),
                            Text(
                              '${_subjectCounts[c.name] ?? 0} subjects  •  '
                              '${_studentCounts[c.name] ?? 0} students',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppTheme.accent, size: 20),
                            onPressed: () => _editClass(c),
                            tooltip: 'Class edit karein',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.danger, size: 20),
                            onPressed: () => _deleteClass(c),
                            tooltip: 'Delete',
                          ),
                        ]),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassDetailScreen(schoolClass: c),
                            ),
                          );
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Class add/edit dialog — naam aur monthly fee.
class _ClassFormDialog extends StatefulWidget {
  const _ClassFormDialog({this.existing});

  final SchoolClass? existing;

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _feeC = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.monthlyFee.toStringAsFixed(0));
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _active = widget.existing?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Add Class' : 'Edit ${widget.existing!.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _nameC,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Class Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _feeC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monthly Fee (Rs)',
                helperText: 'Har mahine ki fee. 0 = fee nahi.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            if (!isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Off karne se dropdowns mein nahi aayegi'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              SchoolClass(
                id: widget.existing?.id,
                name: _nameC.text.trim(),
                monthlyFee: double.tryParse(_feeC.text.trim()) ?? 0,
                isActive: _active,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Class detail: subjects aur unke marks totals.
/// ---------------------------------------------------------------------------
class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({super.key, required this.schoolClass});

  final SchoolClass schoolClass;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _db = DatabaseHelper();
  List<ClassSubject> _subjects = [];
  bool _loading = true;

  String get _className => widget.schoolClass.name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _db.getClassSubjects(_className);
    if (!mounted) return;
    setState(() {
      _subjects = list;
      _loading = false;
    });
  }

  Future<void> _editSubject(ClassSubject? s) async {
    final saved = await showDialog<ClassSubject>(
      context: context,
      builder: (_) => _SubjectFormDialog(className: _className, existing: s),
    );
    if (saved == null) return;
    await _db.upsertClassSubject(saved);
    _load();
  }

  Future<void> _deleteSubject(ClassSubject s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s.subject} hatayein?'),
        content: const Text(
            'Subject is class ki settings se hat jayega. Pehle se entered marks '
            'DB mein rahenge.'),
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
    await _db.deleteClassSubject(s.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class $_className'),
        leading: const BackButton(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'subject_add',
        onPressed: () => _editSubject(null),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _feeCard(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                  child: Text('Subjects of Class $_className',
                      style: AppTheme.subHeading),
                ),
                if (_subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Koi subject add nahi kiya gaya.\n'
                        'Neeche + dabaa kar subjects add karein — phir exam '
                        'banate waqt yehi subjects select honge.',
                        textAlign: TextAlign.center,
                        style: AppTheme.caption,
                      ),
                    ),
                  ),
                for (final s in _subjects)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: ListTile(
                      title: Text(s.subject,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip('Total ${s.totalMarks.toInt()}',
                                AppTheme.primary),
                            _chip('Mid ${s.midMarks.toInt()}', AppTheme.accent),
                            _chip('Final ${s.finalMarks.toInt()}',
                                AppTheme.success),
                            _chip('Weekly ${s.weeklyMarks.toInt()}',
                                AppTheme.warning),
                            _chip('Monthly ${s.monthlyMarks.toInt()}',
                                AppTheme.textMuted),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: AppTheme.accent, size: 20),
                          onPressed: () => _editSubject(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.danger, size: 20),
                          onPressed: () => _deleteSubject(s),
                        ),
                      ]),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );

  Widget _feeCard() => Card(
        margin: const EdgeInsets.fromLTRB(10, 12, 10, 4),
        color: AppTheme.primary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.payments, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Fee',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Text(
                        'Rs ${widget.schoolClass.monthlyFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary)),
                    const Text(
                      'Student add karte waqt fee isi hisaab se lagti hai.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Subject add/edit: total marks + har exam type ke marks.
class _SubjectFormDialog extends StatefulWidget {
  const _SubjectFormDialog({required this.className, this.existing});

  final String className;
  final ClassSubject? existing;

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectC =
      TextEditingController(text: widget.existing?.subject ?? '');
  late final TextEditingController _totalC = TextEditingController(
      text: (widget.existing?.totalMarks ?? 100).toStringAsFixed(0));
  late final TextEditingController _midC = TextEditingController(
      text: (widget.existing?.midMarks ?? 0).toStringAsFixed(0));
  late final TextEditingController _finalC = TextEditingController(
      text: (widget.existing?.finalMarks ?? 0).toStringAsFixed(0));
  late final TextEditingController _weeklyC = TextEditingController(
      text: (widget.existing?.weeklyMarks ?? 0).toStringAsFixed(0));
  late final TextEditingController _monthlyC = TextEditingController(
      text: (widget.existing?.monthlyMarks ?? 0).toStringAsFixed(0));

  /// Common exam types ke liye ek hi total sab pe apply karne ka shortcut.
  final _applyToAllC = TextEditingController();

  void _applyToAll() {
    final v = _applyToAllC.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _midC.text = v;
      _finalC.text = v;
      _weeklyC.text = v;
      _monthlyC.text = v;
      _applyToAllC.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Add Subject' : 'Edit ${widget.existing!.subject}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _subjectC,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Subject Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _totalC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Default Total Marks',
                helperText:
                    'Agar kisi exam type ka total set na ho to yehi chalega.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            const Divider(),
            const Text('Marks per exam type',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('0 = is type ka total set nahi (default chalega)',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _num(_midC, 'Mid Term')),
              const SizedBox(width: 8),
              Expanded(child: _num(_finalC, 'Final Term')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _num(_weeklyC, 'Weekly')),
              const SizedBox(width: 8),
              Expanded(child: _num(_monthlyC, 'Monthly')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _num(_applyToAllC, 'Sab pe apply')),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _applyToAll,
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('Apply'),
              ),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ClassSubject(
                id: widget.existing?.id,
                className: widget.className,
                subject: _subjectC.text.trim(),
                totalMarks: double.tryParse(_totalC.text.trim()) ?? 100,
                midMarks: double.tryParse(_midC.text.trim()) ?? 0,
                finalMarks: double.tryParse(_finalC.text.trim()) ?? 0,
                weeklyMarks: double.tryParse(_weeklyC.text.trim()) ?? 0,
                monthlyMarks: double.tryParse(_monthlyC.text.trim()) ?? 0,
                sortOrder: widget.existing?.sortOrder ?? 0,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _num(TextEditingController c, String label) => TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      );
}
