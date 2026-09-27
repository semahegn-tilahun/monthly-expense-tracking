import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';
import '../data/database_service.dart';
import '../models/app_user.dart';
import '../models/credit_payment.dart';
import '../models/expense_category.dart';
import '../models/expense_record.dart';
import '../models/reminder.dart';
import '../models/savings_record.dart';
import '../models/weekly_track.dart';
import '../utils/date_utils.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool isLoading = true;
  AppUser? currentUser;
  List<AppUser> users = [];
  List<ExpenseCategory> categories = [];
  List<ExpenseRecord> expenses = [];
  List<SavingsRecord> savings = [];
  List<CreditPayment> creditPayments = [];
  List<WeeklyTrack> weeklyTracks = [];
  List<ReminderRecord> reminders = [];
  double monthlyIncome = AppConstants.seedMonthlyIncome;
  double savingsPercent = AppConstants.seedSavingsPercent;

  int get _currentUserId {
    final id = currentUser?.id;
    if (id == null) throw StateError('No logged-in user found.');
    return id;
  }

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();

    await _db.database;
    users = await _db.getUsers();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      currentUser = await _db.findUserById(userId);
    }
    if (currentUser != null) {
      await loadData(silent: true);
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String pin) async {
    final user = await _db.login(email, pin);
    if (user == null) return false;
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    await loadUsers();
    await loadData(silent: true);
    notifyListeners();
    return true;
  }

  Future<void> register(String name, String email, String pin) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.registerUser(AppUser(name: name.trim(), email: email.trim().toLowerCase(), pin: pin.trim(), createdAt: now));
    currentUser = AppUser(id: id, name: name.trim(), email: email.trim().toLowerCase(), pin: pin.trim(), createdAt: now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await loadUsers();
    await loadData(silent: true);
    notifyListeners();
  }

  Future<void> loadUsers() async {
    users = await _db.getUsers();
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    categories = [];
    expenses = [];
    savings = [];
    creditPayments = [];
    weeklyTracks = [];
    reminders = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    notifyListeners();
  }

  Future<void> loadData({bool silent = false}) async {
    if (currentUser == null) {
      categories = [];
      expenses = [];
      savings = [];
      creditPayments = [];
      weeklyTracks = [];
      reminders = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    if (!silent) {
      isLoading = true;
      notifyListeners();
    }

    final userId = _currentUserId;
    monthlyIncome = await _db.getDoubleSetting(userId, 'monthly_income', AppConstants.seedMonthlyIncome);
    savingsPercent = await _db.getDoubleSetting(userId, 'savings_percent', AppConstants.seedSavingsPercent);
    categories = await _db.getCategories(userId);
    expenses = await _db.getExpenses(userId);
    savings = await _db.getSavings(userId);
    creditPayments = await _db.getCreditPayments(userId);
    weeklyTracks = await _db.getWeeklyTracks(userId);
    reminders = await _db.getReminders(userId);

    if (!silent) {
      isLoading = false;
    }
    notifyListeners();
  }

  double get savingsTarget => monthlyIncome * savingsPercent / 100;

  SavingsRecord? get currentSavings {
    final current = monthKey();
    for (final item in savings) {
      if (item.month == current) return item;
    }
    return null;
  }

  double get savedThisMonth => currentSavings?.savedAmount ?? 0;

  double get savingsProgress {
    if (savingsTarget <= 0) return 0;
    return (savedThisMonth / savingsTarget).clamp(0, 1).toDouble();
  }

  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item.amount);

  double get fixedExpenseTotal => expenses.where((item) => item.categoryType == 'fixed').fold(0, (sum, item) => sum + item.amount);

  double get invisibleActualTotal => expenses.where((item) => item.categoryType == 'invisible').fold(0, (sum, item) => sum + item.amount);

  double get invisibleBudgetTotal => categories.where((item) => item.type == 'invisible').fold(0, (sum, item) => sum + item.monthlyBudget);

  double get monthlyCreditPaid {
    final current = monthKey();
    return creditPayments.where((item) => item.paymentMonth == current).fold(0, (sum, item) => sum + item.paymentAmount);
  }

  double get remainingBalance => monthlyIncome - savingsTarget - monthlyCreditPaid - totalExpenses;

  double get remainingDebt {
    if (creditPayments.isEmpty) return 0;
    return creditPayments.first.totalDebtAfter;
  }

  List<ExpenseRecord> get currentMonthExpenses {
    final current = monthKey();
    return expenses.where((item) => monthKey(DateTime.tryParse(item.date) ?? DateTime.now()) == current).toList();
  }

  List<ReminderRecord> get dueReminders {
    return reminders.where((item) => item.isDue).toList();
  }

  int get pendingReminderCount => reminders.where((item) => !item.isDone).length;

  Future<void> updateSettings({required double income, required double percent}) async {
    final userId = _currentUserId;
    await _db.setDoubleSetting(userId, 'monthly_income', income);
    await _db.setDoubleSetting(userId, 'savings_percent', percent);
    monthlyIncome = income;
    savingsPercent = percent;
    await createOrUpdateSavings(savedAmount: income * percent / 100);
    await loadData();
  }

  Future<void> createOrUpdateSavings({required double savedAmount}) async {
    final current = monthKey();
    final now = DateTime.now().toIso8601String();
    final existing = currentSavings;
    await _db.saveSavingsRecord(
      _currentUserId,
      SavingsRecord(
        id: existing?.id,
        month: current,
        income: monthlyIncome,
        targetAmount: savingsTarget,
        savedAmount: savedAmount,
        createdAt: existing?.createdAt ?? now,
      ),
    );
    await loadData();
  }

  Future<void> upsertCategory(ExpenseCategory category) async {
    await _db.upsertCategory(_currentUserId, category);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(_currentUserId, id);
    await loadData();
  }

  Future<void> upsertExpense(ExpenseRecord expense) async {
    await _db.upsertExpense(_currentUserId, expense);
    await loadData();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(_currentUserId, id);
    await loadData();
  }

  Future<void> addCreditPayment(CreditPayment payment) async {
    await _db.addCreditPayment(_currentUserId, payment);
    await loadData();
  }

  Future<void> deleteCreditPayment(int id) async {
    await _db.deleteCreditPayment(_currentUserId, id);
    await loadData();
  }

  Future<void> upsertWeeklyTrack(WeeklyTrack track) async {
    await _db.upsertWeeklyTrack(_currentUserId, track);
    await loadData();
  }

  Future<void> upsertReminder(ReminderRecord reminder) async {
    await _db.upsertReminder(_currentUserId, reminder);
    await loadData();
  }

  Future<void> deleteReminder(int id) async {
    await _db.deleteReminder(_currentUserId, id);
    await loadData();
  }

  Future<void> markReminderDone(int id, bool isDone) async {
    await _db.markReminderDone(_currentUserId, id, isDone);
    await loadData();
  }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await _db.resetDatabase();
    users = await _db.getUsers();
    currentUser = null;
    await loadData();
  }
}
