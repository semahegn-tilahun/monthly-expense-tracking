import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../models/reminder.dart';
import '../providers/budget_provider.dart';
import '../utils/validators.dart';
import '../widgets/empty_state.dart';

class NotificationRemindersScreen extends StatelessWidget {
  const NotificationRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Reminders', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Add reminder',
            onPressed: () => _showReminderDialog(context),
            icon: const Icon(Icons.add_alert_outlined),
          ),
        ],
      ),
      body: reminders.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No reminders yet',
              message: 'Add payment, savings, expense review, or report reminders here.',
              actionLabel: 'Add Reminder',
              onAction: () => _showReminderDialog(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final due = reminder.isDue;
                return Card(
                  color: reminder.isDone ? Colors.grey.shade100 : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: due ? AppConstants.danger.withOpacity(.12) : AppConstants.primary.withOpacity(.12),
                      child: Icon(
                        reminder.isDone ? Icons.check_rounded : due ? Icons.notification_important_outlined : Icons.notifications_active_outlined,
                        color: reminder.isDone ? Colors.grey : due ? AppConstants.danger : AppConstants.primary,
                      ),
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        decoration: reminder.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_formatReminderDate(reminder.remindAt)}\n${reminder.message}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        final provider = context.read<BudgetProvider>();
                        if (value == 'done') await provider.markReminderDone(reminder.id!, !reminder.isDone);
                        if (value == 'edit' && context.mounted) await _showReminderDialog(context, reminder: reminder);
                        if (value == 'delete') await provider.deleteReminder(reminder.id!);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'done', child: Text(reminder.isDone ? 'Mark pending' : 'Mark done')),
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderDialog(context),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Reminder'),
      ),
    );
  }

  static Future<void> _showReminderDialog(BuildContext context, {ReminderRecord? reminder}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: reminder?.title ?? '');
    final messageController = TextEditingController(text: reminder?.message ?? '');
    DateTime selected = DateTime.tryParse(reminder?.remindAt ?? '') ?? DateTime.now().add(const Duration(hours: 1));

    final result = await showDialog<ReminderRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(reminder == null ? 'Add Reminder' : 'Edit Reminder'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Reminder title'),
                        validator: (value) => Validators.requiredText(value, 'Reminder title'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: messageController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Message / note'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Remind at\n${DateFormat('EEE, dd MMM yyyy · hh:mm a').format(selected)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Pick date and time',
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selected,
                                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                                );
                                if (date == null) return;
                                if (!context.mounted) return;
                                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selected));
                                if (time == null) return;
                                setState(() {
                                  selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                });
                              },
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ],
                        ),
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
                    final nowText = DateTime.now().toIso8601String();
                    Navigator.pop(
                      dialogContext,
                      ReminderRecord(
                        id: reminder?.id,
                        title: titleController.text.trim(),
                        message: messageController.text.trim(),
                        remindAt: selected.toIso8601String(),
                        isDone: reminder?.isDone ?? false,
                        createdAt: reminder?.createdAt ?? nowText,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    messageController.dispose();

    if (result != null && context.mounted) {
      await context.read<BudgetProvider>().upsertReminder(result);
    }
  }

  static String _formatReminderDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('EEE, dd MMM yyyy · hh:mm a').format(parsed);
  }
}
