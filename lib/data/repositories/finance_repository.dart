import 'package:mobx/mobx.dart';

import '../mock/mock_data.dart';
import '../models/finance.dart';

class FinanceRepository {
  final donations = ObservableList<Donation>.of(MockData.donations);
  final expenses = ObservableList<Expense>.of(MockData.expenses);

  List<Expense> expensesOfAnimal(String animalId) =>
      expenses.where((e) => e.animalId == animalId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> addExpense(Expense expense) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    runInAction(() => expenses.add(expense));
  }

  Future<void> addDonation(Donation donation) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    runInAction(() => donations.add(donation));
  }
}
