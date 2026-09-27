import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../models/expense_category.dart';
import '../models/expense_record.dart';
import '../providers/budget_provider.dart';
import '../utils/date_utils.dart';
import '../utils/money.dart';
import '../utils/validators.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Expenses', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
            FilledButton.icon(
              onPressed: provider.categories.isEmpty ? null : () => _showExpenseDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Categories',
          trailing: IconButton(
            tooltip: 'Add category',
            onPressed: () => _showCategoryDialog(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
          child: provider.categories.isEmpty
              ? const EmptyState(icon: Icons.category_outlined, title: 'No categories', message: 'Create categories before adding expenses.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.categories.map((category) {
                    final color = category.type == 'fixed'
                        ? AppConstants.info
                        : category.type == 'invisible'
                            ? AppConstants.warning
                            : AppConstants.primary;
                    return InputChip(
                      label: Text('${category.name} · ${money(category.monthlyBudget)}'),
                      avatar: Icon(Icons.label_outline, size: 18, color: color),
                      onPressed: () => _showCategoryDialog(context, category: category),
                      onDeleted: () => _confirmDeleteCategory(context, category),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Expense Records',
          child: provider.expenses.isEmpty
              ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses yet', message: 'Tap Add to register the first expense.')
              : Column(
                  children: provider.expenses.map((expense) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.grey.shade50,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: _categoryColor(expense.categoryType).withOpacity(.12),
                          child: Icon(Icons.receipt_long, color: _categoryColor(expense.categoryType)),
                        ),
                        title: Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${expense.categoryName} · ${readableDate(parseDate(expense.date))}\n${expense.note}'.trim()),
                        isThreeLine: expense.note.trim().isNotEmpty,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(money(expense.amount), style: const TextStyle(fontWeight: FontWeight.w900)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showExpenseDialog(context, expense: expense),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDeleteExpense(context, expense),
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppConstants.danger),
                                ),
                              ],
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

  static Color _categoryColor(String type) {
    if (type == 'fixed') return AppConstants.info;
    if (type == 'invisible') return AppConstants.warning;
    return AppConstants.primary;
  }

  static Future<void> _confirmDeleteCategory(BuildContext context, ExpenseCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Deleting ${category.name} also deletes expenses inside it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<BudgetProvider>().deleteCategory(category.id!);
    }
  }

  static Future<void> _confirmDeleteExpense(BuildContext context, ExpenseRecord expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove ${expense.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<BudgetProvider>().deleteExpense(expense.id!);
    }
  }

  static Future<void> _showCategoryDialog(BuildContext context, {ExpenseCategory? category}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');
    final budgetController = TextEditingController(text: category == null ? '' : category.monthlyBudget.toStringAsFixed(2));
    var type = category?.type ?? 'fixed';

    final saved = await showDialog<ExpenseCategory>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(category == null ? 'Add Category' : 'Edit Category'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Category name'),
                      validator: (value) => Validators.requiredText(value, 'Category name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Category type'),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                        DropdownMenuItem(value: 'invisible', child: Text('Invisible/Common')),
                        DropdownMenuItem(value: 'variable', child: Text('Variable')),
                      ],
                      onChanged: (value) => setState(() => type = value ?? 'fixed'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly budget'),
                      validator: (value) => Validators.nonNegativeAmount(value, 'Monthly budget'),
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
                  Navigator.pop(
                    dialogContext,
                    ExpenseCategory(
                      id: category?.id,
                      name: nameController.text.trim(),
                      type: type,
                      monthlyBudget: parseMoney(budgetController.text),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    budgetController.dispose();

    if (saved != null && context.mounted) {
      await context.read<BudgetProvider>().upsertCategory(saved);
    }
  }

  static Future<void> _showExpenseDialog(BuildContext context, {ExpenseRecord? expense}) async {
    final provider = context.read<BudgetProvider>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: expense?.title ?? '');
    final amountController = TextEditingController(text: expense == null ? '' : expense.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: expense?.note ?? '');
    DateTime selectedDate = expense == null ? DateTime.now() : parseDate(expense.date);
    int? categoryId = expense?.categoryId ?? (provider.categories.isNotEmpty ? provider.categories.first.id : null);

    final saved = await showDialog<ExpenseRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: provider.categories
                          .map((item) => DropdownMenuItem(value: item.id, child: Text('${item.name} (${item.type})')))
                          .toList(),
                      onChanged: (value) => setState(() => categoryId = value),
                      validator: (value) => value == null ? 'Category is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) => Validators.requiredText(value, 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (value) => Validators.positiveAmount(value, 'Amount'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(readableDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
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
                  final selectedCategory = provider.categories.firstWhere((item) => item.id == categoryId);
                  Navigator.pop(
                    dialogContext,
                    ExpenseRecord(
                      id: expense?.id,
                      categoryId: categoryId!,
                      categoryName: selectedCategory.name,
                      categoryType: selectedCategory.type,
                      title: titleController.text.trim(),
                      amount: parseMoney(amountController.text),
                      date: selectedDate.toIso8601String(),
                      note: noteController.text.trim(),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    amountController.dispose();
    noteController.dispose();

    if (saved != null && context.mounted) {
      await context.read<BudgetProvider>().upsertExpense(saved);
    }
  }
}
