import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../models/credit_payment.dart';
import '../providers/budget_provider.dart';
import '../utils/date_utils.dart';
import '../utils/money.dart';
import '../utils/validators.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';

class CreditScreen extends StatelessWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Credit Payments', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
            FilledButton.icon(onPressed: () => _showCreditDialog(context), icon: const Icon(Icons.add), label: const Text('Add')),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Debt Status',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remaining Debt', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(money(provider.remainingDebt), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppConstants.primary.withOpacity(.1), borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.credit_score_rounded, color: AppConstants.primary, size: 34),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Payment History',
          child: provider.creditPayments.isEmpty
              ? const EmptyState(icon: Icons.credit_card_off_outlined, title: 'No credit payment', message: 'Add your monthly credit or debt payment.')
              : Column(
                  children: provider.creditPayments.map((payment) {
                    return Card(
                      color: Colors.grey.shade50,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.credit_card, color: AppConstants.info)),
                        title: Text(payment.lender, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${payment.paymentMonth} · Paid ${readableDate(parseDate(payment.paidAt))}\nDebt after: ${money(payment.totalDebtAfter)}'),
                        isThreeLine: true,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(money(payment.paymentAmount), style: const TextStyle(fontWeight: FontWeight.w900)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _confirmDelete(context, payment),
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppConstants.danger),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  static Future<void> _confirmDelete(BuildContext context, CreditPayment payment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text('Remove ${payment.lender} payment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<BudgetProvider>().deleteCreditPayment(payment.id!);
    }
  }

  static Future<void> _showCreditDialog(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    final formKey = GlobalKey<FormState>();
    final lenderController = TextEditingController(text: 'Credit payment');
    final amountController = TextEditingController();
    final debtBeforeController = TextEditingController(text: provider.remainingDebt.toStringAsFixed(2));
    final noteController = TextEditingController();

    final payment = await showDialog<CreditPayment>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Credit Payment'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: lenderController,
                  decoration: const InputDecoration(labelText: 'Lender / Credit name'),
                  validator: (value) => Validators.requiredText(value, 'Lender'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Payment amount'),
                  validator: (value) => Validators.positiveAmount(value, 'Payment amount'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: debtBeforeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Debt before payment'),
                  validator: (value) => Validators.nonNegativeAmount(value, 'Debt before payment'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final amount = parseMoney(amountController.text);
              final before = parseMoney(debtBeforeController.text);
              final after = (before - amount).clamp(0, double.infinity).toDouble();
              Navigator.pop(
                dialogContext,
                CreditPayment(
                  lender: lenderController.text.trim(),
                  paymentMonth: monthKey(),
                  paymentAmount: amount,
                  totalDebtBefore: before,
                  totalDebtAfter: after,
                  paidAt: DateTime.now().toIso8601String(),
                  note: noteController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    lenderController.dispose();
    amountController.dispose();
    debtBeforeController.dispose();
    noteController.dispose();

    if (payment != null && context.mounted) {
      await context.read<BudgetProvider>().addCreditPayment(payment);
    }
  }
}
