import 'package:mobx/mobx.dart';

import '../../../app/app_view_model.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/session_repository.dart';

part 'login_view_model.g.dart';

class LoginViewModel = LoginViewModelBase with _$LoginViewModel;

abstract class LoginViewModelBase with Store {
  LoginViewModelBase(this._appVm);

  final AppViewModel _appVm;

  List<AppUser> get accounts => _appVm.accounts;

  @observable
  String email = '';

  @observable
  String password = '';

  @observable
  bool obscurePassword = true;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  
  @computed
  bool get isNewAccount =>
      Validators.email(email) == null && !_appVm.isKnownAccount(email);

  @computed
  List<(String, bool)> get passwordRules => Validators.passwordRules(password);

  @action
  void setEmail(String value) {
    email = value;
    errorMessage = null;
  }

  @action
  void setPassword(String value) {
    password = value;
    errorMessage = null;
  }

  @action
  void toggleObscure() => obscurePassword = !obscurePassword;

  @action
  Future<bool> login() async {
    isLoading = true;
    errorMessage = null;
    try {
      await _appVm.signIn(email.trim(), password);
      return true;
    } on AuthException catch (e) {
      runInAction(() => errorMessage = e.message);
      return false;
    } finally {
      runInAction(() => isLoading = false);
    }
  }

  Future<void> forget(String email) => _appVm.forgetAccount(email);
}
