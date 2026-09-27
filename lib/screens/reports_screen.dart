import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../models/weekly_track.dart';
import '../providers/budget_provider.dart';
import '../services/export_service.dart';
import '../utils/money.dart';
import '../utils/validators.dart';
import '../widgets/app_footer_note.dart';
import '../widgets/section_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportExcel(context),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Export Excel'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Monthly Financial Summary',
          child: Column(
            children: [
              _SummaryLine('Income', money(provider.monthlyIncome)),
              _SummaryLine('Savings Target', money(provider.savingsTarget)),
              _SummaryLine('Credit Paid', money(provider.monthlyCreditPaid)),
              _SummaryLine('Expenses', money(provider.totalExpenses)),
              const Divider(height: 24),
              _SummaryLine('Remaining Balance', money(provider.remainingBalance), strong: true, color: provider.remainingBalance >= 0 ? AppConstants.success : AppConstants.danger),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Spending Comparison Chart',
          child: SizedBox(
            height: 260,
            child: provider.categories.isEmpty
                ? const Center(child: Text('No categories to chart.'))
                : BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(enabled: true),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= provider.categories.length) return const SizedBox.shrink();
                              final name = provider.categories[index].name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Transform.rotate(
                                  angle: -0.55,
                                  child: Text(name.length > 10 ? '${name.substring(0, 10)}…' : name, style: const TextStyle(fontSize: 10)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(provider.categories.length, (index) {
                        final category = provider.categories[index];
                        final spent = provider.expenses
                            .where((expense) => expense.categoryId == category.id)
                            .fold<double>(0, (sum, expense) => sum + expense.amount);
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: spent,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: spent > category.monthlyBudget && category.monthlyBudget > 0 ? AppConstants.danger : AppConstants.primary,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Weekly Tracker',
          child: Column(
            children: provider.weeklyTracks.map((track) {
              return Card(
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(track.weekLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('Planned: ${money(track.plannedSpending)} · Actual: ${money(track.actualSpending)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(money(track.difference), style: TextStyle(fontWeight: FontWeight.w900, color: track.difference >= 0 ? AppConstants.success : AppConstants.danger)),
                      IconButton(onPressed: () => _showWeeklyDialog(context, track), icon: const Icon(Icons.edit_outlined)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const AppFooterNote(),
        const SizedBox(height: 90),
      ],
    );
  }

  static Future<void> _exportPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ExportService.exportPdf(context.read<BudgetProvider>());
      messenger.showSnackBar(SnackBar(content: const Text('PDF exported successfully.'), action: SnackBarAction(label: 'Open', onPressed: () => OpenFilex.open(file.path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('PDF export failed: $error')));
    }
  }

  static Future<void> _exportExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ExportService.exportExcel(context.read<BudgetProvider>());
      messenger.showSnackBar(SnackBar(content: const Text('Excel exported successfully.'), action: SnackBarAction(label: 'Open', onPressed: () => OpenFilex.open(file.path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Excel export failed: $error')));
    }
  }

  static Future<void> _showWeeklyDialog(BuildContext context, WeeklyTrack track) async {
    final formKey = GlobalKey<FormState>();
    final plannedController = TextEditingController(text: track.plannedSpending.toStringAsFixed(2));
    final actualController = TextEditingController(text: track.actualSpending.toStringAsFixed(2));

    final updated = await showDialog<WeeklyTrack>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update ${track.weekLabel}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: plannedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Planned spending'),
                validator: (value) => Validators.nonNegativeAmount(value, 'Planned spending'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: actualController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Actual spending'),
                validator: (value) => Validators.nonNegativeAmount(value, 'Actual spending'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                WeeklyTrack(
                  id: track.id,
                  weekLabel: track.weekLabel,
                  plannedSpending: parseMoney(plannedController.text),
                  actualSpending: parseMoney(actualController.text),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    plannedController.dispose();
    actualController.dispose();

    if (updated != null && context.mounted) {
      await context.read<BudgetProvider>().upsertWeeklyTrack(updated);
    }
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;

  const _SummaryLine(this.label, this.value, {this.strong = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w700))),
          Text(value, style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
