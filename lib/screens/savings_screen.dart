import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/budget_provider.dart';
import '../utils/money.dart';
import '../utils/validators.dart';
import '../widgets/section_card.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Savings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
            FilledButton.icon(
              onPressed: () => _showSavingsDialog(context),
              icon: const Icon(Icons.edit),
              label: const Text('Update'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Current Month Target',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(money(provider.savingsTarget), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('${provider.savingsPercent.toStringAsFixed(0)}% from ${money(provider.monthlyIncome)} monthly income'),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 16,
                  value: provider.savingsProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: AppConstants.success,
                ),
              ),
              const SizedBox(height: 10),
              Text('Saved: ${money(provider.savedThisMonth)}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Savings History',
          child: provider.savings.isEmpty
              ? const Text('No savings history yet.')
              : Column(
                  children: provider.savings.map((item) {
                    final progress = item.targetAmount <= 0 ? 0.0 : (item.savedAmount / item.targetAmount).clamp(0.0, 1.0);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.grey.shade50,
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.savings_outlined)),
                        title: Text(item.month, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: LinearProgressIndicator(value: progress, minHeight: 8, color: AppConstants.success),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(money(item.savedAmount), style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text('Target ${money(item.targetAmount)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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

  static Future<void> _showSavingsDialog(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    final controller = TextEditingController(text: provider.savedThisMonth.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final savedAmount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Savings'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Saved amount'),
            validator: (value) => Validators.nonNegativeAmount(value, 'Saved amount'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, parseMoney(controller.text));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (savedAmount != null && context.mounted) {
      await context.read<BudgetProvider>().createOrUpdateSavings(savedAmount: savedAmount);
    }
  }
}
