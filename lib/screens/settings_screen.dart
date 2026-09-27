import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/budget_provider.dart';
import '../utils/money.dart';
import '../utils/validators.dart';
import '../widgets/app_footer_note.dart';
import '../widgets/section_card.dart';
import 'notification_reminders_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Monthly Budget Setup',
          trailing: IconButton(onPressed: () => _showBudgetDialog(context), icon: const Icon(Icons.edit_outlined)),
          child: Column(
            children: [
              _RowLine('Monthly income', money(provider.monthlyIncome)),
              _RowLine('Savings percentage', '${provider.savingsPercent.toStringAsFixed(0)}%'),
              _RowLine('Auto savings target', money(provider.savingsTarget)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Notification Reminders',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pending reminders: ${provider.pendingReminderCount}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationRemindersScreen())),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Open Reminder Center'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Multi-user Support',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Each registered user has isolated income, expenses, savings, credit payments, weekly tracking, reminders, and exported reports.'),
              const SizedBox(height: 12),
              ...provider.users.map((user) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase())),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(user.email),
                    trailing: user.id == provider.currentUser?.id ? const Chip(label: Text('Current')) : null,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Seed Data Source',
          child: const Text(
            'The first launch creates the specification budget: income 14,000 ETB, savings 25%, credit payment 1,150 ETB, fixed expenses 8,550 ETB, and invisible expense budget 700 ETB.',
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Danger Zone',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reset returns the local database to the original seeded budget and logs out the current user.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmReset(context),
                icon: const Icon(Icons.restart_alt_rounded, color: AppConstants.danger),
                label: const Text('Reset Local Data', style: TextStyle(color: AppConstants.danger)),
              ),
            ],
          ),
        ),
        const AppFooterNote(),
        const SizedBox(height: 90),
      ],
    );
  }

  static Future<void> _showBudgetDialog(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    final formKey = GlobalKey<FormState>();
    final incomeController = TextEditingController(text: provider.monthlyIncome.toStringAsFixed(2));
    final percentController = TextEditingController(text: provider.savingsPercent.toStringAsFixed(2));

    final result = await showDialog<({double income, double percent})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Budget Setup'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly income'),
                validator: (value) => Validators.positiveAmount(value, 'Monthly income'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: percentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Savings percent'),
                validator: (value) {
                  final err = Validators.nonNegativeAmount(value, 'Savings percent');
                  if (err != null) return err;
                  final parsed = parseMoney(value ?? '0');
                  if (parsed > 100) return 'Savings percent cannot exceed 100';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, (income: parseMoney(incomeController.text), percent: parseMoney(percentController.text)));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    incomeController.dispose();
    percentController.dispose();

    if (result != null && context.mounted) {
      await context.read<BudgetProvider>().updateSettings(income: result.income, percent: result.percent);
    }
  }

  static Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text('This deletes local app data and restores the original seeded budget. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<BudgetProvider>().resetAllData();
    }
  }
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;

  const _RowLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
