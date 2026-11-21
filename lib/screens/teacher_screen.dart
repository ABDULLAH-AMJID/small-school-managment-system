import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _searchC = TextEditingController();
  List<Teacher> _teachers = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _db.getTeachers();
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all
            .where((t) =>
                t.name.toLowerCase().contains(q) ||
                t.subject.toLowerCase().contains(q) ||
                t.phone.toLowerCase().contains(q))
            .toList();
    if (!mounted) return;
    setState(() {
      _teachers = list;
      _loading = false;
    });
  }

  /// Add aur edit dono ek hi form se.
  Future<void> _openForm({Teacher? existing}) async {
    final result = await showModalBottomSheet<Teacher>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _TeacherForm(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _db.insertTeacher(result);
    } else {
      await _db.updateTeacher(result);
    }
    _load();
  }

  Future<void> _delete(Teacher t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${t.name} ko delete karein?'),
        content: const Text('Teacher ka record hat jayega.'),
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
    await _db.deleteTeacher(t.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Teachers'), leading: const BackButton()),
      floatingActionButton: FloatingActionButton(
        heroTag: 'teacher_add',
        onPressed: () => _openForm(),
        child: const Icon(Icons.person_add_alt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchC,
              onChanged: (v) {
                _query = v;
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Search by name, subject or phone',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchC.clear();
                          _query = '';
                          _load();
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _teachers.isEmpty
                    ? Center(
                        child: Text(
                            _query.isEmpty
                                ? 'Koi teacher nahi mila.\n+ se naya teacher add karein.'
                                : '"$_query" se koi teacher nahi mila.',
                            textAlign: TextAlign.center,
                            style: AppTheme.caption))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _teachers.length,
                          itemBuilder: (_, i) {
                            final t = _teachers[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primary.withOpacity(0.1),
                                child: Text(
                                  t.name.isNotEmpty ? t.name[0] : '?',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(t.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${t.subject.isEmpty ? '—' : t.subject}  •  '
                                  '${t.phone.isEmpty ? '—' : t.phone}  •  '
                                  'Rs ${t.salary.toStringAsFixed(0)}'),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppTheme.accent, size: 21),
                                      tooltip: 'Edit',
                                      onPressed: () => _openForm(existing: t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppTheme.danger, size: 21),
                                      tooltip: 'Delete',
                                      onPressed: () => _delete(t),
                                    ),
                                  ]),
                              onTap: () => _openForm(existing: t),
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

class _TeacherForm extends StatefulWidget {
  const _TeacherForm({this.existing});

  final Teacher? existing;

  @override
  State<_TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<_TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _subjectC = TextEditingController();
  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _qualC = TextEditingController();
  final _salaryC = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _nameC.text = t.name;
      _subjectC.text = t.subject;
      _phoneC.text = t.phone;
      _emailC.text = t.email;
      _qualC.text = t.qualification;
      _salaryC.text = t.salary == 0 ? '' : t.salary.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    for (final c in [_nameC, _subjectC, _phoneC, _emailC, _qualC, _salaryC]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
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
              Text(isNew ? 'Add Teacher' : 'Edit Teacher',
                  style: AppTheme.subHeading),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameC,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Teacher Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              _tf(_subjectC, 'Subject',
                  capitalization: TextCapitalization.words),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _tf(_phoneC, 'Phone',
                        keyboardType: TextInputType.phone)),
                const SizedBox(width: 10),
                Expanded(
                    child: _tf(_emailC, 'Email',
                        keyboardType: TextInputType.emailAddress)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _tf(_qualC, 'Qualification',
                        capitalization: TextCapitalization.words)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _salaryC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Salary (Rs)'),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Save Teacher' : 'Update Teacher'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Teacher(
        id: widget.existing?.id,
        name: _nameC.text.trim(),
        subject: _subjectC.text.trim(),
        phone: _phoneC.text.trim(),
        email: _emailC.text.trim(),
        qualification: _qualC.text.trim(),
        salary: double.tryParse(_salaryC.text.trim()) ?? 0,
        isActive: widget.existing?.isActive ?? true,
      ),
    );
  }

  Widget _tf(TextEditingController c, String label,
          {TextInputType? keyboardType,
          TextCapitalization capitalization = TextCapitalization.none}) =>
      TextFormField(
        controller: c,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        inputFormatters: keyboardType == TextInputType.phone
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))]
            : null,
        decoration: InputDecoration(labelText: label),
      );
}
