import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  final _searchC = TextEditingController();
  List<Student> _students = [];
  List<String> _classes = [];
  bool _loading = true;
  String _filterClass = '';
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
    final classes = await _db.getClasses();
    final all = await _db.getStudents(
        className: _filterClass.isEmpty ? null : _filterClass);
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.rollNo.toLowerCase().contains(q) ||
                (s.parentPhone).toLowerCase().contains(q))
            .toList();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _students = list;
      _loading = false;
    });
  }

  /// Add AUR edit dono isi se hotay hain — [existing] null ho to naya student.
  Future<void> _openForm({Student? existing}) async {
    final result = await showModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _StudentForm(
        existing: existing,
        classes: _classes,
      ),
    );
    if (result == null) return;
    if (existing == null) {
      await _db.insertStudent(result);
    } else {
      await _db.updateStudent(result);
    }
    _load();
  }

  Future<void> _delete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s.name} ko delete karein?'),
        content: const Text('Student ka record hat jayega.'),
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
    await _db.deleteStudent(s.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Students'), leading: const BackButton()),
      floatingActionButton: FloatingActionButton(
        heroTag: 'student_add',
        onPressed: () => _openForm(),
        child: const Icon(Icons.person_add_alt),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchC,
              onChanged: (v) {
                _query = v;
                _load();
              },
              decoration: InputDecoration(
                hintText: 'Search by name, roll no or parent phone',
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
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filterClass.isEmpty,
                    onSelected: (_) {
                      _filterClass = '';
                      _load();
                    },
                  ),
                ),
                for (final c in _classes)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _filterClass == c,
                      onSelected: (_) {
                        _filterClass = _filterClass == c ? '' : c;
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Text(
                            _query.isEmpty
                                ? 'Koi student nahi mila.\n+ se naya student add karein.'
                                : '"$_query" se koi student nahi mila.',
                            textAlign: TextAlign.center,
                            style: AppTheme.caption))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _students.length,
                          itemBuilder: (_, i) {
                            final s = _students[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primary.withOpacity(0.1),
                                child: Text(
                                  s.name.isNotEmpty ? s.name[0] : '?',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Roll ${s.rollNo}  •  ${s.className} ${s.section}'
                                      .trim()),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppTheme.accent, size: 21),
                                      tooltip: 'Edit',
                                      onPressed: () => _openForm(existing: s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppTheme.danger, size: 21),
                                      tooltip: 'Delete',
                                      onPressed: () => _delete(s),
                                    ),
                                  ]),
                              onTap: () => _openForm(existing: s),
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

/// Student ka add/edit form (bottom sheet). Class dropdown `classes` table se
/// aati hai, aur admission date calendar se select hoti hai.
class _StudentForm extends StatefulWidget {
  const _StudentForm({required this.classes, this.existing});

  final List<String> classes;
  final Student? existing;

  @override
  State<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _rollC = TextEditingController();
  final _sectionC = TextEditingController();
  final _phoneC = TextEditingController();
  final _parentNameC = TextEditingController();
  final _parentPhoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _admissionC = TextEditingController();
  String? _class;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s != null) {
      _nameC.text = s.name;
      _rollC.text = s.rollNo;
      _sectionC.text = s.section;
      _phoneC.text = s.phone;
      _parentNameC.text = s.parentName;
      _parentPhoneC.text = s.parentPhone;
      _addressC.text = s.address;
      _admissionC.text = s.admissionDate;
      _class = s.className;
    } else {
      // Naya student: admission date aaj, aur class dropdown ki pehli class.
      _admissionC.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (widget.classes.isNotEmpty) _class = widget.classes.first;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameC,
      _rollC,
      _sectionC,
      _phoneC,
      _parentNameC,
      _parentPhoneC,
      _addressC,
      _admissionC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAdmissionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _admissionC.text.isNotEmpty
          ? (DateTime.tryParse(_admissionC.text) ?? now)
          : now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 5),
      helpText: 'Admission Date',
    );
    if (picked != null) {
      setState(
          () => _admissionC.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
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
              Text(isNew ? 'Add New Student' : 'Edit Student',
                  style: AppTheme.subHeading),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameC,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Student Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _rollC,
                    decoration: const InputDecoration(labelText: 'Roll No *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.classes.contains(_class) ? _class : null,
                    decoration: const InputDecoration(labelText: 'Class *'),
                    items: widget.classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _class = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _tf(_sectionC, 'Section',
                        capitalization: TextCapitalization.characters)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _admissionC,
                    readOnly: true,
                    onTap: _pickAdmissionDate,
                    decoration: const InputDecoration(
                      labelText: 'Admission Date',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _tf(_phoneC, 'Student Phone', keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _tf(_parentNameC, 'Parent Name',
                  capitalization: TextCapitalization.words),
              const SizedBox(height: 10),
              _tf(_parentPhoneC, 'Parent Phone',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _tf(_addressC, 'Address', maxLines: 2),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Save Student' : 'Update Student'),
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
    if (_class == null) return;
    Navigator.pop(
      context,
      Student(
        id: widget.existing?.id,
        name: _nameC.text.trim(),
        rollNo: _rollC.text.trim(),
        className: _class!,
        section: _sectionC.text.trim(),
        phone: _phoneC.text.trim(),
        parentName: _parentNameC.text.trim(),
        parentPhone: _parentPhoneC.text.trim(),
        address: _addressC.text.trim(),
        admissionDate: _admissionC.text.trim(),
        photoPath: widget.existing?.photoPath,
        isActive: widget.existing?.isActive ?? true,
        // Purane student ka fee start month barkarar rakho, warna arrears
        // dobara calculate ho jayenge.
        feeStartMonth: widget.existing?.feeStartMonth ?? '',
      ),
    );
  }

  Widget _tf(TextEditingController c, String label,
          {TextInputType? keyboardType,
          int maxLines = 1,
          TextCapitalization capitalization = TextCapitalization.none}) =>
      TextFormField(
        controller: c,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: capitalization,
        inputFormatters: keyboardType == TextInputType.phone
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))]
            : null,
        decoration: InputDecoration(labelText: label),
      );
}
