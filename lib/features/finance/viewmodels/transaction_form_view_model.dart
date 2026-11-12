import 'package:mobx/mobx.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/animal.dart';
import '../../../data/models/finance.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/finance_repository.dart';

part 'transaction_form_view_model.g.dart';

class TransactionFormViewModel = TransactionFormViewModelBase
    with _$TransactionFormViewModel;


abstract class TransactionFormViewModelBase with Store {
  TransactionFormViewModelBase(
    this._finance,
    this._animals, {
    required this.isExpense,
  });

  final FinanceRepository _finance;
  final AnimalRepository _animals;
  final bool isExpense;

  List<Animal> get animals => _animals.animals.toList();

  @observable
  String description = '';

  @observable
  String amount = '';

  @observable
  DateTime date = DateTime.now();

  
  @observable
  ExpenseCategory category = ExpenseCategory.food;

  @observable
  PaymentMethod paymentMethod = PaymentMethod.pix;

  @observable
  bool installment = false;

  @observable
  int installments = 2;

  @observable
  String? animalId;

  @observable
  bool hasInvoice = false;

  
  @observable
  DonationMethod donationMethod = DonationMethod.pix;

  @observable
  bool anonymous = false;

  @observable
  String donorName = '';

  @observable
  bool hasReceipt = false;

  @observable
  bool isSaving = false;

  @computed
  double get parsedAmount => Fmt.parseCurrency(amount) ?? 0;

  @computed
  double get installmentValue =>
      installment && installments > 0 ? parsedAmount / installments : 0;

  String? validateDonor(String? value) {
    if (anonymous) return null;
    if ((value ?? '').trim().length < 3) {
      return 'Informe o nome do doador ou marque como anônimo';
    }
    return null;
  }

  String? validateDate() =>
      date.isAfter(DateTime.now()) ? 'A data não pode ser futura' : null;

  @action
  void setDescription(String v) => description = v;
  @action
  void setAmount(String v) => amount = v;
  @action
  void setDate(DateTime v) => date = v;
  @action
  void setCategory(ExpenseCategory v) => category = v;
  @action
  void setPaymentMethod(PaymentMethod v) {
    paymentMethod = v;
    if (v != PaymentMethod.creditCard) installment = false;
  }

  @action
  void setInstallment(bool v) => installment = v;
  @action
  void setInstallments(int v) => installments = v;
  @action
  void setAnimal(String? v) => animalId = v;
  @action
  void setHasInvoice(bool v) => hasInvoice = v;
  @action
  void setDonationMethod(DonationMethod v) => donationMethod = v;
  @action
  void setAnonymous(bool v) => anonymous = v;
  @action
  void setDonorName(String v) => donorName = v;
  @action
  void setHasReceipt(bool v) => hasReceipt = v;

  @action
  Future<void> save() async {
    isSaving = true;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    if (isExpense) {
      await _finance.addExpense(
        Expense(
          id: 'e$id',
          description: description.trim(),
          category: category,
          amount: parsedAmount,
          paymentMethod: paymentMethod,
          installments: installment ? installments : 1,
          date: date,
          hasInvoice: hasInvoice,
          animalId: animalId,
        ),
      );
    } else {
      await _finance.addDonation(
        Donation(
          id: 'd$id',
          amount: parsedAmount,
          method: donationMethod,
          date: date,
          donorName: anonymous ? null : donorName.trim(),
          hasReceipt: hasReceipt,
        ),
      );
    }
    isSaving = false;
  }
}
