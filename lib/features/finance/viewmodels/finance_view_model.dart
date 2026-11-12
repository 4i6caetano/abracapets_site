import 'package:mobx/mobx.dart';

import '../../../data/models/finance.dart';
import '../../../data/repositories/finance_repository.dart';

part 'finance_view_model.g.dart';

enum EntryFilter { all, income, expense }

class FinanceViewModel = FinanceViewModelBase with _$FinanceViewModel;

abstract class FinanceViewModelBase with Store {
  FinanceViewModelBase(this._repository);

  final FinanceRepository _repository;

  @observable
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @observable
  EntryFilter filter = EntryFilter.all;

  @observable
  String query = '';

  bool _inMonth(DateTime d, DateTime month) =>
      d.year == month.year && d.month == month.month;

  @computed
  bool get canGoNext {
    final now = DateTime.now();
    return selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  @computed
  List<Donation> get monthDonations => _repository.donations
      .where((d) => _inMonth(d.date, selectedMonth))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  @computed
  List<Expense> get monthExpenses => _repository.expenses
      .where((e) => _inMonth(e.date, selectedMonth))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  @computed
  double get totalIncome => monthDonations.fold(0, (s, d) => s + d.amount);

  @computed
  double get totalExpense => monthExpenses.fold(0, (s, e) => s + e.amount);

  @computed
  double get balance => totalIncome - totalExpense;

  @computed
  int get expensesWithoutInvoice =>
      monthExpenses.where((e) => !e.hasInvoice).length;

  
  @computed
  double? get expenseVariation {
    final prev = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final prevTotal = _repository.expenses
        .where((e) => _inMonth(e.date, prev))
        .fold<double>(0, (s, e) => s + e.amount);
    if (prevTotal == 0) return null;
    return (totalExpense - prevTotal) / prevTotal;
  }

  @computed
  Map<ExpenseCategory, double> get categoryTotals {
    final map = {for (final c in ExpenseCategory.values) c: 0.0};
    for (final e in monthExpenses) {
      map[e.category] = map[e.category]! + e.amount;
    }
    return map;
  }

  @computed
  List<FinanceEntry> get entries {
    final q = query.trim().toLowerCase();
    final list = <FinanceEntry>[
      if (filter != EntryFilter.expense)
        ...monthDonations.map(FinanceEntry.fromDonation),
      if (filter != EntryFilter.income)
        ...monthExpenses.map(FinanceEntry.fromExpense),
    ]..sort((a, b) => b.date.compareTo(a.date));
    if (q.isEmpty) return list;
    return list.where((e) => e.title.toLowerCase().contains(q)).toList();
  }

  @computed
  List<Expense> get latestExpenses => monthExpenses.take(5).toList();

  @action
  void previousMonth() =>
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);

  @action
  void nextMonth() {
    if (canGoNext) {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    }
  }

  @action
  void setMonth(DateTime month) =>
      selectedMonth = DateTime(month.year, month.month);

  @action
  void setFilter(EntryFilter value) => filter = value;

  @action
  void setQuery(String value) => query = value;
}
