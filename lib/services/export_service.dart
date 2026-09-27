import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../providers/budget_provider.dart';
import '../utils/money.dart';

class ExportService {
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');

  static Future<File> exportPdf(BudgetProvider provider) async {
    final doc = pw.Document();
    final userName = provider.currentUser?.name ?? 'User';
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text('Monthly Expense Tracker Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('User: $userName'),
          pw.Text('Generated: ${_dateTimeFormat.format(generatedAt)}'),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Monthly Summary'),
          _pdfTable([
            ['Income', money(provider.monthlyIncome)],
            ['Savings Target', money(provider.savingsTarget)],
            ['Savings Saved', money(provider.savedThisMonth)],
            ['Credit Paid', money(provider.monthlyCreditPaid)],
            ['Total Expenses', money(provider.totalExpenses)],
            ['Remaining Balance', money(provider.remainingBalance)],
            ['Invisible Budget', money(provider.invisibleBudgetTotal)],
            ['Invisible Actual', money(provider.invisibleActualTotal)],
          ]),
          pw.SizedBox(height: 16),
          _pdfSectionTitle('Expenses'),
          provider.expenses.isEmpty
              ? pw.Text('No expenses found.')
              : _pdfTable([
                  ['Date', 'Category', 'Type', 'Title', 'Amount'],
                  ...provider.expenses.map((e) => [
                        _formatShortDate(e.date),
                        e.categoryName,
                        e.categoryType,
                        e.title,
                        money(e.amount),
                      ]),
                ], headerRows: 1),
          pw.SizedBox(height: 16),
          _pdfSectionTitle('Savings History'),
          provider.savings.isEmpty
              ? pw.Text('No savings records found.')
              : _pdfTable([
                  ['Month', 'Income', 'Target', 'Saved'],
                  ...provider.savings.map((s) => [s.month, money(s.income), money(s.targetAmount), money(s.savedAmount)]),
                ], headerRows: 1),
          pw.SizedBox(height: 16),
          _pdfSectionTitle('Credit Payments'),
          provider.creditPayments.isEmpty
              ? pw.Text('No credit payments found.')
              : _pdfTable([
                  ['Paid At', 'Lender', 'Month', 'Payment', 'Debt After'],
                  ...provider.creditPayments.map((c) => [
                        _formatShortDate(c.paidAt),
                        c.lender,
                        c.paymentMonth,
                        money(c.paymentAmount),
                        money(c.totalDebtAfter),
                      ]),
                ], headerRows: 1),
          pw.SizedBox(height: 16),
          _pdfSectionTitle('Weekly Tracking'),
          _pdfTable([
            ['Week', 'Planned', 'Actual', 'Difference'],
            ...provider.weeklyTracks.map((w) => [w.weekLabel, money(w.plannedSpending), money(w.actualSpending), money(w.difference)]),
          ], headerRows: 1),
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text('© ${DateTime.now().year} Monthly Expense Tracker'),
          pw.Text('Powered by MuluTila Technology', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    final file = await _reportFile('pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  static Future<File> exportExcel(BudgetProvider provider) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Summary');

    final summary = excel['Summary'];
    _append(summary, ['Monthly Expense Tracker Report']);
    _append(summary, ['User', provider.currentUser?.name ?? 'User']);
    _append(summary, ['Generated', _dateTimeFormat.format(DateTime.now())]);
    _append(summary, []);
    _append(summary, ['Metric', 'Amount']);
    _append(summary, ['Income', provider.monthlyIncome]);
    _append(summary, ['Savings Target', provider.savingsTarget]);
    _append(summary, ['Savings Saved', provider.savedThisMonth]);
    _append(summary, ['Credit Paid', provider.monthlyCreditPaid]);
    _append(summary, ['Total Expenses', provider.totalExpenses]);
    _append(summary, ['Remaining Balance', provider.remainingBalance]);
    _append(summary, ['Invisible Budget', provider.invisibleBudgetTotal]);
    _append(summary, ['Invisible Actual', provider.invisibleActualTotal]);

    final expenses = excel['Expenses'];
    _append(expenses, ['Date', 'Category', 'Type', 'Title', 'Amount', 'Note']);
    for (final e in provider.expenses) {
      _append(expenses, [_formatShortDate(e.date), e.categoryName, e.categoryType, e.title, e.amount, e.note]);
    }

    final savings = excel['Savings'];
    _append(savings, ['Month', 'Income', 'Target Amount', 'Saved Amount', 'Created At']);
    for (final s in provider.savings) {
      _append(savings, [s.month, s.income, s.targetAmount, s.savedAmount, _formatShortDate(s.createdAt)]);
    }

    final credit = excel['Credit'];
    _append(credit, ['Paid At', 'Lender', 'Payment Month', 'Payment Amount', 'Debt Before', 'Debt After', 'Note']);
    for (final c in provider.creditPayments) {
      _append(credit, [_formatShortDate(c.paidAt), c.lender, c.paymentMonth, c.paymentAmount, c.totalDebtBefore, c.totalDebtAfter, c.note]);
    }

    final weekly = excel['Weekly'];
    _append(weekly, ['Week', 'Planned Spending', 'Actual Spending', 'Difference']);
    for (final w in provider.weeklyTracks) {
      _append(weekly, [w.weekLabel, w.plannedSpending, w.actualSpending, w.difference]);
    }

    final reminders = excel['Reminders'];
    _append(reminders, ['Remind At', 'Title', 'Message', 'Status']);
    for (final r in provider.reminders) {
      _append(reminders, [_formatShortDate(r.remindAt), r.title, r.message, r.isDone ? 'Done' : 'Pending']);
    }

    final bytes = excel.save();
    if (bytes == null) throw StateError('Excel export failed.');
    final file = await _reportFile('xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _pdfTable(List<List<String>> rows, {int headerRows = 0}) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: List.generate(rows.length, (rowIndex) {
        final isHeader = rowIndex < headerRows;
        return pw.TableRow(
          decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
          children: rows[rowIndex].map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  static void _append(Sheet sheet, List<Object?> row) {
    sheet.appendRow(row.map(_cell).toList());
  }

  static CellValue _cell(Object? value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is num) return DoubleCellValue(value.toDouble());
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value.toString());
  }

  static Future<File> _reportFile(String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/monthly_expense_reports');
    if (!await folder.exists()) await folder.create(recursive: true);
    final stamp = _fileDateFormat.format(DateTime.now());
    return File('${folder.path}/monthly_expense_report_$stamp.$extension');
  }

  static String _formatShortDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('yyyy-MM-dd').format(parsed);
  }
}
