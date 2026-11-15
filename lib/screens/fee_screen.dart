import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});
  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  final _db = DatabaseHelper();
  final _studentC = TextEditingController(); // student id
  final _monthC = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().month}');
  final _amountC = TextEditingController();
  final _dueC = TextEditingController();
  final _paidC = TextEditingController();
  List<Student> _students = [];
  List<Fee> _fees = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final s = await _db.getStudents();
    final f = await _db.getFees();
    setState(() { _students = s; _fees = f; _loading = false; });
  }
  Future<void> _saveFee() async {
    if (_studentC.text.isEmpty || _amountC.text.isEmpty) return;
    await _db.insertFee(Fee(
      studentId: int.tryParse(_studentC.text) ?? 0, month: _monthC.text,
      amount: double.tryParse(_amountC.text) ?? 0, dueDate: _dueC.text,
      amountPaid: double.tryParse(_paidC.text) ?? 0,
      status: (double.tryParse(_paidC.text) ?? 0) >= (double.tryParse(_amountC.text) ?? 0) ? 'Paid' : 'Pending',
    ));
    _studentC.clear(); _amountC.clear(); _dueC.clear(); _paidC.clear();
    _load();
  }
  Future<void> _markPaid(Fee f) async {
    await _db.updateFee(Fee(id: f.id, studentId: f.studentId, month: f.month, amount: f.amount, dueDate: f.dueDate, amountPaid: f.amount, status: 'Paid', paidDate: DateFormat('yyyy-MM-dd').format(DateTime.now())));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fee Management'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add / Collect Fee', style: AppTheme.subHeading),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tf(_studentC, 'Student ID')),
                const SizedBox(width: 8),
                Expanded(child: _tf(_monthC, 'Month (YYYY-MM)')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tf(_amountC, 'Amount')),
                const SizedBox(width: 8),
                Expanded(child: _tf(_dueC, 'Due Date')),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _tf(_paidC, 'Amount Paid')),
                const SizedBox(width: 8),
                SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: _saveFee, child: Text('Save Fee'))),
              ]),
              const SizedBox(height: 10),
              Text('Pending Fees', style: AppTheme.subHeading),
            ]),
          ),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _fees.isEmpty
              ? const Center(child: Text('No fee records.'))
              : ListView.builder(itemCount: _fees.length, itemBuilder: (_, i) {
                  final f = _fees[i];
                  final pending = f.status != 'Paid';
                  return ListTile(
                    title: Text('Student ${f.studentId} - ${f.month}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Due: Rs ${f.amount.toStringAsFixed(0)} | Paid: Rs ${f.amountPaid.toStringAsFixed(0)} | Balance: Rs ${f.balance.toStringAsFixed(0)} | Due: ${f.dueDate}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pending ? 'Pending' : 'Paid', style: TextStyle(color: pending ? AppTheme.danger : AppTheme.success, fontWeight: FontWeight.bold)),
                        if (pending) TextButton(onPressed: () => _markPaid(f), child: Text('Mark Paid')),
                      ],
                    ),
                  );
                })),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: Icon(Icons.add)),
    );
  }

  Widget _tf(TextEditingController c, String l) => TextField(controller: c, decoration: InputDecoration(labelText: l, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10)));
}
