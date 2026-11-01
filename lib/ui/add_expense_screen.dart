import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../core/split.dart';
import '../models/expense.dart';
import '../models/group.dart';
import '../state/providers.dart';

/// Adds a new expense, or edits [existing] when given.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.group, this.existing});

  final Group group;
  final Expense? existing;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  late final Map<String, TextEditingController> _values = {
    for (final m in widget.group.members) m.id: TextEditingController(),
  };
  late String _payer;
  late Set<String> _selected;
  SplitType _type = SplitType.equal;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final members = widget.group.members;
    final me = widget.group.memberForUid(ref.read(repositoryProvider).currentUid);
    final e = widget.existing;
    if (e == null) {
      _payer = (me ?? members.first).id;
      _selected = {for (final m in members) m.id};
      return;
    }
    _description.text = e.description;
    _amount.text = amountToPlain(e.amount);
    _payer = e.paidBy.keys.first;
    _type = e.splitType;
    _date = e.date;
    _selected = (e.splitValues.isNotEmpty ? e.splitValues.keys : e.owed.keys).toSet();
    e.splitValues.forEach((id, v) {
      _values[id]?.text = switch (_type) {
        SplitType.exact => amountToPlain(v.round()),
        _ => v % 1 == 0 ? v.toInt().toString() : v.toString(),
      };
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    for (final c in _values.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _participants => [
    for (final m in widget.group.members)
      if (_selected.contains(m.id)) m.id,
  ];

  Map<String, num> _splitValues() => {
    for (final id in _participants)
      id: switch (_type) {
        SplitType.equal => 1,
        SplitType.exact => parseAmount(_values[id]!.text) ?? 0,
        _ => num.tryParse(_values[id]!.text.trim()) ?? 0,
      },
  };

  /// The split for the current inputs, or an error message.
  (Map<String, int>?, String?) _preview() {
    final total = parseAmount(_amount.text);
    if (total == null || total == 0) return (null, 'Enter an amount');
    try {
      return (
        computeSplit(total: total, type: _type, members: _participants, values: _splitValues()),
        null,
      );
    } on SplitException catch (e) {
      return (null, e.message);
    }
  }

  void _setType(SplitType type) {
    setState(() {
      _type = type;
      for (final c in _values.values) {
        c.text = type == SplitType.shares ? '1' : '';
      }
    });
  }

  Future<void> _save(Map<String, int> owed) async {
    final repo = ref.read(repositoryProvider);
    final amount = parseAmount(_amount.text)!;
    await repo.saveExpense(
      Expense(
        id: widget.existing?.id ?? repo.newId(),
        groupId: widget.group.id,
        description: _description.text.trim().isEmpty ? 'Expense' : _description.text.trim(),
        amount: amount,
        paidBy: {_payer: amount},
        owed: owed,
        splitType: _type,
        splitValues: _splitValues(),
        category: widget.existing?.category ?? 'general',
        date: _date,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).deleteExpense(widget.group.id, widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final (owed, error) = _preview();
    final group = widget.group;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add expense' : 'Edit expense'),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _description,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Description', hintText: 'Dinner'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _payer,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: [
                    for (final m in group.members)
                      DropdownMenuItem(value: m.id, child: Text(m.name)),
                  ],
                  onChanged: (v) => setState(() => _payer = v!),
                ),
              ),
              const SizedBox(width: 12),
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 18),
                label: Text(DateFormat('d MMM yyyy').format(_date)),
                onPressed: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Split', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<SplitType>(
              segments: [
                for (final t in SplitType.values) ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _setType(s.first),
            ),
          ),
          const SizedBox(height: 8),
          for (final m in group.members)
            Row(
              children: [
                Checkbox(
                  value: _selected.contains(m.id),
                  onChanged: (v) =>
                      setState(() => v! ? _selected.add(m.id) : _selected.remove(m.id)),
                ),
                Expanded(child: Text(m.name)),
                if (_type != SplitType.equal && _selected.contains(m.id))
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _values[m.id],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: _type == SplitType.exact ? '₹ ' : null,
                        suffixText: switch (_type) {
                          SplitType.percent => '%',
                          SplitType.shares => 'x',
                          _ => null,
                        },
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: Text(
                    owed == null ? '' : formatAmount(owed[m.id] ?? 0),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: owed == null ? null : () => _save(owed),
            child: const Text('Save'),
          ),
        ),
      ),
    );
  }
}
