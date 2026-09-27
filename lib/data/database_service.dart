import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../core/app_constants.dart';
import '../models/app_user.dart';
import '../models/credit_payment.dart';
import '../models/expense_category.dart';
import '../models/expense_record.dart';
import '../models/reminder.dart';
import '../models/savings_record.dart';
import '../models/weekly_track.dart';
import '../utils/date_utils.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'monthly_expense_tracker_v3.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onOpen: (db) async {
        await _seedOwnerIfEmpty(db);
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        pin TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        userId INTEGER NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY(userId, key),
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        monthlyBudget REAL NOT NULL DEFAULT 0,
        UNIQUE(userId, name),
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(categoryId) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE savings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        month TEXT NOT NULL,
        income REAL NOT NULL,
        targetAmount REAL NOT NULL,
        savedAmount REAL NOT NULL,
        createdAt TEXT NOT NULL,
        UNIQUE(userId, month),
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE credit_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        lender TEXT NOT NULL,
        paymentMonth TEXT NOT NULL,
        paymentAmount REAL NOT NULL,
        totalDebtBefore REAL NOT NULL,
        totalDebtAfter REAL NOT NULL,
        paidAt TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE weekly_tracks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        weekLabel TEXT NOT NULL,
        plannedSpending REAL NOT NULL DEFAULT 0,
        actualSpending REAL NOT NULL DEFAULT 0,
        UNIQUE(userId, weekLabel),
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT,
        remindAt TEXT NOT NULL,
        isDone INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _seedOwnerIfEmpty(Database db) async {
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    if (userCount > 0) return;

    final nowText = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      final ownerId = await txn.insert('users', {
        'name': 'Owner',
        'email': AppConstants.defaultEmail,
        'pin': AppConstants.defaultPin,
        'createdAt': nowText,
      });
      await _seedBudgetForUser(txn, ownerId);
    });
  }

  Future<void> _seedBudgetForUser(DatabaseExecutor executor, int userId) async {
    final existing = Sqflite.firstIntValue(await executor.rawQuery('SELECT COUNT(*) FROM categories WHERE userId = ?', [userId])) ?? 0;
    if (existing > 0) return;

    final now = DateTime.now();
    final nowText = now.toIso8601String();
    final currentMonth = monthKey(now);
    final savingsTarget = AppConstants.seedMonthlyIncome * AppConstants.seedSavingsPercent / 100;

    await executor.insert('settings', {
      'userId': userId,
      'key': 'monthly_income',
      'value': AppConstants.seedMonthlyIncome.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await executor.insert('settings', {
      'userId': userId,
      'key': 'savings_percent',
      'value': AppConstants.seedSavingsPercent.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final categoryRows = <Map<String, Object?>>[
      {'name': 'House Rent', 'type': 'fixed', 'monthlyBudget': 4000.0},
      {'name': 'Internet Service', 'type': 'fixed', 'monthlyBudget': 2050.0},
      {'name': 'Charity', 'type': 'fixed', 'monthlyBudget': 2000.0},
      {'name': 'Social Affairs', 'type': 'fixed', 'monthlyBudget': 500.0},
      {'name': 'Transportation', 'type': 'invisible', 'monthlyBudget': 250.0},
      {'name': 'Mobile Airtime/Data', 'type': 'invisible', 'monthlyBudget': 150.0},
      {'name': 'Emergency/Miscellaneous', 'type': 'invisible', 'monthlyBudget': 200.0},
      {'name': 'Household Supplies', 'type': 'invisible', 'monthlyBudget': 100.0},
    ];

    final categoryIds = <String, int>{};
    for (final row in categoryRows) {
      final id = await executor.insert('categories', {
        'userId': userId,
        ...row,
      });
      categoryIds[row['name'] as String] = id;
    }

    final expenseRows = <Map<String, Object?>>[
      {
        'categoryId': categoryIds['House Rent'],
        'title': 'Monthly house rent',
        'amount': 4000.0,
        'date': nowText,
        'note': 'Seeded fixed expense',
      },
      {
        'categoryId': categoryIds['Internet Service'],
        'title': 'Internet service',
        'amount': 2050.0,
        'date': nowText,
        'note': 'Seeded fixed expense',
      },
      {
        'categoryId': categoryIds['Charity'],
        'title': 'Charity',
        'amount': 2000.0,
        'date': nowText,
        'note': 'Seeded fixed expense',
      },
      {
        'categoryId': categoryIds['Social Affairs'],
        'title': 'Social affairs',
        'amount': 500.0,
        'date': nowText,
        'note': 'Seeded fixed expense',
      },
    ];

    for (final row in expenseRows) {
      await executor.insert('expenses', {
        'userId': userId,
        ...row,
      });
    }

    await executor.insert('savings', {
      'userId': userId,
      'month': currentMonth,
      'income': AppConstants.seedMonthlyIncome,
      'targetAmount': savingsTarget,
      'savedAmount': savingsTarget,
      'createdAt': nowText,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await executor.insert('credit_payments', {
      'userId': userId,
      'lender': 'Monthly credit payment',
      'paymentMonth': currentMonth,
      'paymentAmount': AppConstants.seedCreditPayment,
      'totalDebtBefore': AppConstants.seedCreditPayment,
      'totalDebtAfter': 0.0,
      'paidAt': nowText,
      'note': 'Seeded credit payment from specification',
    });

    for (var i = 1; i <= 4; i++) {
      await executor.insert('weekly_tracks', {
        'userId': userId,
        'weekLabel': 'Week $i',
        'plannedSpending': 0.0,
        'actualSpending': 0.0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await executor.insert('reminders', {
      'userId': userId,
      'title': 'Review monthly spending',
      'message': 'Check savings target, expenses, credit payment, and remaining balance.',
      'remindAt': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'isDone': 0,
      'createdAt': nowText,
    });
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('reminders');
      await txn.delete('expenses');
      await txn.delete('categories');
      await txn.delete('savings');
      await txn.delete('credit_payments');
      await txn.delete('weekly_tracks');
      await txn.delete('settings');
      await txn.delete('users');
    });
    await _seedOwnerIfEmpty(db);
  }

  Future<List<AppUser>> getUsers() async {
    final db = await database;
    final rows = await db.query('users', orderBy: 'createdAt DESC, id DESC');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> findUserById(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> login(String email, String pin) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ? AND pin = ?',
      whereArgs: [email.trim().toLowerCase(), pin.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<int> registerUser(AppUser user) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
      await _seedBudgetForUser(txn, id);
      return id;
    });
  }

  Future<double> getDoubleSetting(int userId, String key, double fallback) async {
    final db = await database;
    final rows = await db.query('settings', where: 'userId = ? AND key = ?', whereArgs: [userId, key], limit: 1);
    if (rows.isEmpty) return fallback;
    return double.tryParse(rows.first['value'] as String) ?? fallback;
  }

  Future<void> setDoubleSetting(int userId, String key, double value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'userId': userId, 'key': key, 'value': value.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseCategory>> getCategories(int userId) async {
    final db = await database;
    final rows = await db.query('categories', where: 'userId = ?', whereArgs: [userId], orderBy: 'type ASC, name ASC');
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  Future<int> upsertCategory(int userId, ExpenseCategory category) async {
    final db = await database;
    final map = {...category.toMap(), 'userId': userId};
    if (category.id == null) return db.insert('categories', map);
    return db.update('categories', map, where: 'id = ? AND userId = ?', whereArgs: [category.id, userId]);
  }

  Future<int> deleteCategory(int userId, int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<ExpenseRecord>> getExpenses(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT e.id, e.categoryId, e.title, e.amount, e.date, e.note,
             c.name AS categoryName, c.type AS categoryType
      FROM expenses e
      INNER JOIN categories c ON c.id = e.categoryId
      WHERE e.userId = ?
      ORDER BY e.date DESC, e.id DESC
    ''', [userId]);
    return rows.map(ExpenseRecord.fromMap).toList();
  }

  Future<int> upsertExpense(int userId, ExpenseRecord expense) async {
    final db = await database;
    final map = {...expense.toMap(), 'userId': userId};
    if (expense.id == null) return db.insert('expenses', map);
    return db.update('expenses', map, where: 'id = ? AND userId = ?', whereArgs: [expense.id, userId]);
  }

  Future<int> deleteExpense(int userId, int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<SavingsRecord>> getSavings(int userId) async {
    final db = await database;
    final rows = await db.query('savings', where: 'userId = ?', whereArgs: [userId], orderBy: 'month DESC');
    return rows.map(SavingsRecord.fromMap).toList();
  }

  Future<int> saveSavingsRecord(int userId, SavingsRecord record) async {
    final db = await database;
    return db.insert(
      'savings',
      {...record.toMap(), 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CreditPayment>> getCreditPayments(int userId) async {
    final db = await database;
    final rows = await db.query('credit_payments', where: 'userId = ?', whereArgs: [userId], orderBy: 'paidAt DESC, id DESC');
    return rows.map(CreditPayment.fromMap).toList();
  }

  Future<int> addCreditPayment(int userId, CreditPayment payment) async {
    final db = await database;
    return db.insert('credit_payments', {...payment.toMap(), 'userId': userId});
  }

  Future<int> deleteCreditPayment(int userId, int id) async {
    final db = await database;
    return db.delete('credit_payments', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<List<WeeklyTrack>> getWeeklyTracks(int userId) async {
    final db = await database;
    final rows = await db.query('weekly_tracks', where: 'userId = ?', whereArgs: [userId], orderBy: 'id ASC');
    return rows.map(WeeklyTrack.fromMap).toList();
  }

  Future<int> upsertWeeklyTrack(int userId, WeeklyTrack track) async {
    final db = await database;
    final map = {...track.toMap(), 'userId': userId};
    if (track.id == null) return db.insert('weekly_tracks', map, conflictAlgorithm: ConflictAlgorithm.replace);
    return db.update('weekly_tracks', map, where: 'id = ? AND userId = ?', whereArgs: [track.id, userId]);
  }

  Future<List<ReminderRecord>> getReminders(int userId) async {
    final db = await database;
    final rows = await db.query('reminders', where: 'userId = ?', whereArgs: [userId], orderBy: 'isDone ASC, remindAt ASC');
    return rows.map(ReminderRecord.fromMap).toList();
  }

  Future<int> upsertReminder(int userId, ReminderRecord reminder) async {
    final db = await database;
    final map = {...reminder.toMap(), 'userId': userId};
    if (reminder.id == null) return db.insert('reminders', map);
    return db.update('reminders', map, where: 'id = ? AND userId = ?', whereArgs: [reminder.id, userId]);
  }

  Future<int> deleteReminder(int userId, int id) async {
    final db = await database;
    return db.delete('reminders', where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  Future<int> markReminderDone(int userId, int id, bool isDone) async {
    final db = await database;
    return db.update('reminders', {'isDone': isDone ? 1 : 0}, where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }
}
