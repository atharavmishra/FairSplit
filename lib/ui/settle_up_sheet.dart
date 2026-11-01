import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/balances.dart';
import '../core/money.dart';
import '../core/upi.dart';
import '../models/group.dart';
import '../models/settlement.dart';
import '../state/providers.dart';

void showSettleUpSheet(BuildContext context, Group group, Transfer transfer) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettleUpSheet(group: group, transfer: transfer),
  );
}

class _SettleUpSheet extends ConsumerStatefulWidget {
  const _SettleUpSheet({required this.group, required this.transfer});

  final Group group;
  final Transfer transfer;

  @override
  ConsumerState<_SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends ConsumerState<_SettleUpSheet> {
  late final _amount = TextEditingController(text: amountToPlain(widget.transfer.amount));

  int? get _paise {
    final p = parseAmount(_amount.text);
    return p != null && p > 0 ? p : null;
  }

  Future<void> _record() async {
    final repo = ref.read(repositoryProvider);
    await repo.addSettlement(
      Settlement(
        id: repo.newId(),
        groupId: widget.group.id,
        from: widget.transfer.from,
        to: widget.transfer.to,
        amount: _paise!,
        date: DateTime.now(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _payUpi(String upiId, String name) async {
    final ok = await launchUrl(
      upiPayUri(upiId: upiId, payeeName: name, amount: _paise!),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No UPI app found')));
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.group.nameOf(widget.transfer.from);
    final payee = widget.group.memberById(widget.transfer.to);
    final upiId = payee?.upiId;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$from pays ${payee?.name ?? 'Someone'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (upiId != null) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: Text('Pay via UPI ($upiId)'),
              onPressed: _paise == null ? null : () => _payUpi(upiId, payee!.name),
            ),
            const SizedBox(height: 4),
            const Text(
              'After paying in your UPI app, come back and record the payment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _paise == null ? null : _record,
            child: const Text('Record payment'),
          ),
        ],
      ),
    );
  }
}
