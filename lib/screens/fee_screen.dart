import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

/// Fee tab: student ka naam ya roll no likhein, us ka poora hisaab samne —
/// kitni fee banti thi, kitni jama hui, kitni baqi hai, aur kitne mahinon ki.
///
/// Fee class settings se aati hai (monthly), is liye student add karte waqt
/// khud tay ho jati hai. Installments isi tarah banti hain ke ek hi mahine ke
/// against kitni bhi payments record ki ja sakti hain.
class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});
  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  final _db = DatabaseHelper();
  final _searchC = TextEditingController();
  List<Student> _results = [];
  Map<int, double> _balances = {};
  bool _searched = false;
  bool _loading = false;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _balances = {};
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    final students = await _db.searchStudents(query);
    final balances = <int, double>{};
    for (final s in students) {
      final ledger = await _db.feeLedgerFor(s);
      balances[s.id ?? 0] = ledger.totalBalance;
    }
    if (!mounted) return;
    setState(() {
      _results = students;
      _balances = balances;
      _searched = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fees'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchC,
              autofocus: true,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Student ka naam ya roll no likhein',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_searched
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 56,
                                  color: AppTheme.primary.withOpacity(0.35)),
                              const SizedBox(height: 12),
                              Text(
                                'Student search karein — naam ya roll no se.\n'
                                'Fee ka poora hisaab (baqi, jama, mahine) '
                                'yahin dikh jayega.',
                                textAlign: TextAlign.center,
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                                '"${_searchC.text.trim()}" se koi student nahi mila.',
                                style: AppTheme.caption))
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final s = _results[i];
                              final bal = _balances[s.id] ?? 0;
                              final clear = bal <= 0.005;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primary.withOpacity(0.1),
                                  child: Text(s.rollNo,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary)),
                                ),
                                title: Text(s.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    'Roll ${s.rollNo}  •  ${s.className} ${s.section}'
                                        .trim()),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (clear
                                            ? AppTheme.success
                                            : AppTheme.danger)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    clear
                                        ? 'Clear'
                                        : 'Rs ${bal.toStringAsFixed(0)} baqi',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: clear
                                            ? AppTheme.success
                                            : AppTheme.danger),
                                  ),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FeeDetailScreen(student: s),
                                    ),
                                  );
                                  _search(_searchC.text);
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Ek student ka poora fee hisaab.
/// ---------------------------------------------------------------------------
class FeeDetailScreen extends StatefulWidget {
  const FeeDetailScreen({super.key, required this.student});

  final Student student;

  @override
  State<FeeDetailScreen> createState() => _FeeDetailScreenState();
}

class _FeeDetailScreenState extends State<FeeDetailScreen> {
  final _db = DatabaseHelper();
  FeeLedger? _ledger;
  List<FeePayment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ledger = await _db.feeLedgerFor(widget.student);
    final payments = await _db.getFeePayments(widget.student.id!);
    if (!mounted) return;
    setState(() {
      _ledger = ledger;
      _payments = payments;
      _loading = false;
    });
  }

  Future<void> _collectFee() async {
    final ledger = _ledger;
    if (ledger == null) return;
    if (ledger.monthlyFee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Is class ki monthly fee set nahi hai. Classes → '
            '${widget.student.className} → fee set karein.'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CollectFeeDialog(
        student: widget.student,
        ledger: ledger,
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _deletePayment(FeePayment p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment delete karein?'),
        content: Text(
            'Rs ${p.amount.toStringAsFixed(0)} (${FeeLedger.monthLabel(p.month)}) '
            'ka record hat jayega.'),
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
    await _db.deleteFeePayment(p.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final ledger = _ledger;
    return Scaffold(
      appBar: AppBar(title: Text(s.name), leading: const BackButton()),
      floatingActionButton: ledger == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fee_collect',
              onPressed: _collectFee,
              icon: const Icon(Icons.add_card),
              label: const Text('Collect Fee'),
            ),
      body: _loading || ledger == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              children: [
                _summary(ledger),
                const SizedBox(height: 12),
                Text('Month by month', style: AppTheme.subHeading),
                const SizedBox(height: 4),
                if (ledger.months.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Fee ka hisaab abhi shuru nahi hua (koi month nahi banta).',
                      style: AppTheme.caption,
                    ),
                  ),
                for (final m in ledger.months.reversed) _monthTile(ledger, m),
                const SizedBox(height: 14),
                Text('Payments received (${_payments.length})',
                    style: AppTheme.subHeading),
                const SizedBox(height: 4),
                if (_payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('Koi payment record nahi.',
                        style: AppTheme.caption),
                  ),
                for (final p in _payments.reversed) _paymentTile(p),
              ],
            ),
    );
  }

  Widget _summary(FeeLedger l) => Card(
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.student.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      Text(
                        'Roll ${widget.student.rollNo}  •  '
                                'Class ${widget.student.className} ${widget.student.section}'
                            .trim(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Monthly Fee',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('Rs ${l.monthlyFee.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _stat('Payable', l.totalPayable),
                _stat('Paid', l.totalPaid),
                _stat('Balance', l.totalBalance, highlight: true),
              ]),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.pendingMonthCount == 0
                      ? 'Sab mahinon ki fee clear hai ✓'
                      : '${l.pendingMonthCount} mahine(n) ki fee baqi hai: '
                          '${l.pendingMonths.reversed.map(FeeLedger.monthLabel).join(', ')}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _stat(String label, double value, {bool highlight = false}) =>
      Expanded(
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text('Rs ${value.toStringAsFixed(0)}',
                style: TextStyle(
                    color: highlight ? AppTheme.warning : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _monthTile(FeeLedger l, String month) {
    final status = l.statusFor(month);
    final color = status == 'Paid'
        ? AppTheme.success
        : status == 'Partial'
            ? AppTheme.warning
            : AppTheme.danger;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(
          status == 'Paid'
              ? Icons.check_circle
              : status == 'Partial'
                  ? Icons.timelapse
                  : Icons.error_outline,
          color: color,
          size: 22,
        ),
        title: Text(FeeLedger.monthLabel(month),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Banti: Rs ${l.payableFor(month).toStringAsFixed(0)}  •  '
          'Jama: Rs ${l.paidFor(month).toStringAsFixed(0)}  •  '
          'Baqi: Rs ${l.balanceFor(month).toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(status,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        onTap: _collectFee,
      ),
    );
  }

  Widget _paymentTile(FeePayment p) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.receipt, color: AppTheme.success, size: 22),
          title: Text('Rs ${p.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${FeeLedger.monthLabel(p.month)}'
            '${p.paidDate.isEmpty ? '' : '  •  ${p.paidDate}'}'
            '${p.note.isEmpty ? '' : '  •  ${p.note}'}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.danger, size: 20),
            onPressed: () => _deletePayment(p),
          ),
        ),
      );
}

/// Fee jama karne ka dialog — installment ke liye partial amount bhi de sakte
/// hain.
class _CollectFeeDialog extends StatefulWidget {
  const _CollectFeeDialog({required this.student, required this.ledger});

  final Student student;
  final FeeLedger ledger;

  @override
  State<_CollectFeeDialog> createState() => _CollectFeeDialogState();
}

class _CollectFeeDialogState extends State<_CollectFeeDialog> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _amountC = TextEditingController();
  final _noteC = TextEditingController();
  late String _month;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pending = widget.ledger.pendingMonths;
    // Sab se purana baqi month pehle.
    _month = pending.isNotEmpty ? pending.first : FeeLedger.currentMonth();
  }

  @override
  void dispose() {
    _amountC.dispose();
    _noteC.dispose();
    super.dispose();
  }

  void _setAmount(double v) =>
      setState(() => _amountC.text = v.toStringAsFixed(0));

  @override
  Widget build(BuildContext context) {
    final l = widget.ledger;
    final balance = l.balanceFor(_month);
    final months = [...l.months].reversed.toList();
    if (!months.contains(_month)) months.insert(0, _month);

    return AlertDialog(
      title: const Text('Collect Fee'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: _month,
              decoration:
                  const InputDecoration(labelText: 'Fee kis mahine ki?'),
              items: months
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          '${FeeLedger.monthLabel(m)}'
                          '  (${l.statusFor(m)}'
                          '${l.balanceFor(m) > 0.005 ? ', Rs ${l.balanceFor(m).toStringAsFixed(0)} baqi' : ''})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _month = v;
                  _amountC.clear();
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: Text(
                      'Poora mahina Rs ${l.payableFor(_month).toStringAsFixed(0)}'),
                  onPressed: () => _setAmount(l.payableFor(_month)),
                ),
                if (balance > 0.005 && balance < l.payableFor(_month))
                  ActionChip(
                    label: Text('Baqi Rs ${balance.toStringAsFixed(0)}'),
                    onPressed: () => _setAmount(balance),
                  ),
                ActionChip(
                  label: Text(
                      ' Aadha Rs ${(l.payableFor(_month) / 2).toStringAsFixed(0)}'),
                  onPressed: () => _setAmount(l.payableFor(_month) / 2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Amount (Rs) *',
                helperText:
                    'Installment ke liye kam amount bhi likh sakte hain — '
                    'baqi mahine ke against baqi rahega.',
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Amount likhein';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteC,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Installment 1 of 3'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  await _db.insertFeePayment(FeePayment(
                    studentId: widget.student.id!,
                    month: _month,
                    amount: double.parse(_amountC.text.trim()),
                    paidDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    note: _noteC.text.trim(),
                  ));
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Payment'),
        ),
      ],
    );
  }
}
