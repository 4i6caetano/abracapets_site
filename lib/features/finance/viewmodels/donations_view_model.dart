import 'package:mobx/mobx.dart';

import '../../../data/models/finance.dart';
import '../../../data/repositories/finance_repository.dart';

part 'donations_view_model.g.dart';

class DonationsViewModel = DonationsViewModelBase with _$DonationsViewModel;

abstract class DonationsViewModelBase with Store {
  DonationsViewModelBase(this._repository);

  final FinanceRepository _repository;

  @observable
  String query = '';

  @observable
  DonationMethod? method;

  @observable
  bool onlyWithoutReceipt = false;

  @computed
  List<Donation> get donations {
    final q = query.trim().toLowerCase();
    return _repository.donations.where((d) {
      if (method != null && d.method != method) return false;
      if (onlyWithoutReceipt && d.hasReceipt) return false;
      if (q.isNotEmpty &&
          !d.displayName.toLowerCase().contains(q) &&
          !(d.campaign?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @computed
  double get total => donations.fold(0, (s, d) => s + d.amount);

  @computed
  int get donorsCount =>
      donations.map((d) => d.donorName).whereType<String>().toSet().length;

  @action
  void setQuery(String v) => query = v;

  @action
  void setMethod(DonationMethod? v) => method = v;

  @action
  void setOnlyWithoutReceipt(bool v) => onlyWithoutReceipt = v;
}
