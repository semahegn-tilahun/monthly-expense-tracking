import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/budget_provider.dart';
import '../widgets/app_footer_note.dart';
import 'credit_screen.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'notification_reminders_screen.dart';
import 'reports_screen.dart';
import 'savings_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  Timer? _reminderTimer;
  final Set<int> _shownReminderIds = {};

  final _screens = const [
    DashboardScreen(),
    ExpensesScreen(),
    SavingsScreen(),
    CreditScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDueReminders());
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDueReminders());
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _checkDueReminders() {
    if (!mounted) return;
    final provider = context.read<BudgetProvider>();
    for (final reminder in provider.dueReminders) {
      final id = reminder.id;
      if (id == null || _shownReminderIds.contains(id)) continue;
      _shownReminderIds.add(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text('Reminder: ${reminder.title}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openReminders(),
          ),
        ),
      );
    }
  }

  Future<void> _openReminders() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationRemindersScreen()));
    if (mounted) await context.read<BudgetProvider>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final userName = provider.currentUser?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppConstants.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              '$userName · ${AppFooterNote.currentDateText()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notification reminders',
                onPressed: _openReminders,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (provider.pendingReminderCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.danger,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      provider.pendingReminderCount > 99 ? '99+' : provider.pendingReminderCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => provider.loadData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => provider.logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: provider.isLoading ? const Center(child: CircularProgressIndicator()) : IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Savings'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Credit'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
