import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/budget_provider.dart';
import '../utils/money.dart';
import '../widgets/app_footer_note.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final balanceColor = provider.remainingBalance >= 0 ? AppConstants.success : AppConstants.danger;

    return RefreshIndicator(
      onRefresh: provider.loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Monthly Summary',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isWide = width >= 760;
              final columns = isWide ? 4 : 2;
              final spacing = isWide ? 14.0 : 12.0;
              final cardHeight = isWide ? 210.0 : 228.0;
              final rows = (4 / columns).ceil();

              final cards = [
                MetricCard(
                  title: 'Income',
                  value: money(provider.monthlyIncome),
                  icon: Icons.payments_outlined,
                  color: AppConstants.info,
                ),
                MetricCard(
                  title: 'Savings Target',
                  value: money(provider.savingsTarget),
                  icon: Icons.savings_outlined,
                  color: AppConstants.success,
                  subtitle: '${provider.savingsPercent.toStringAsFixed(0)}% of income',
                ),
                MetricCard(
                  title: 'Expenses',
                  value: money(provider.totalExpenses),
                  icon: Icons.shopping_bag_outlined,
                  color: AppConstants.warning,
                ),
                MetricCard(
                  title: 'Remaining',
                  value: money(provider.remainingBalance),
                  icon: Icons.account_balance_wallet_outlined,
                  color: balanceColor,
                ),
              ];

              return SizedBox(
                height: (rows * cardHeight) + ((rows - 1) * spacing),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: cardHeight,
                  ),
                  itemBuilder: (_, index) => cards[index],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Savings Progress',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 14,
                    value: provider.savingsProgress,
                    backgroundColor: Colors.grey.shade200,
                    color: AppConstants.success,
                  ),
                ),
                const SizedBox(height: 10),
                Text('${money(provider.savedThisMonth)} saved from ${money(provider.savingsTarget)} target'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Budget Logic',
            child: Column(
              children: [
                _Line(label: 'Monthly Income', value: money(provider.monthlyIncome)),
                _Line(label: 'Savings ${provider.savingsPercent.toStringAsFixed(0)}%', value: '- ${money(provider.savingsTarget)}'),
                _Line(label: 'Credit Payment', value: '- ${money(provider.monthlyCreditPaid)}'),
                _Line(label: 'Fixed + Actual Expenses', value: '- ${money(provider.totalExpenses)}'),
                const Divider(height: 24),
                _Line(
                  label: 'Remaining Balance',
                  value: money(provider.remainingBalance),
                  bold: true,
                  valueColor: balanceColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Invisible/Common Expense Watch',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(label: 'Suggested Invisible Budget', value: money(provider.invisibleBudgetTotal)),
                _Line(label: 'Actual Invisible Spending', value: money(provider.invisibleActualTotal)),
                const SizedBox(height: 8),
                Text(
                  provider.invisibleActualTotal <= provider.invisibleBudgetTotal
                      ? 'You are inside the invisible/common expense budget.'
                      : 'Invisible spending is over budget. Cut it now before it becomes silent leakage.',
                  style: TextStyle(
                    color: provider.invisibleActualTotal <= provider.invisibleBudgetTotal ? AppConstants.success : AppConstants.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const AppFooterNote(),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}
