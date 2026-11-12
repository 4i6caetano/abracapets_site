import 'package:mobx/mobx.dart';

import '../../../app/app_view_model.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/session_repository.dart';

part 'user_profile_view_model.g.dart';

class UserProfileViewModel = UserProfileViewModelBase with _$UserProfileViewModel;



abstract class UserProfileViewModelBase with Store {
  UserProfileViewModelBase(this._app);

  final AppViewModel _app;

  AppUser? get user => _app.user;
  List<AppUser> get accounts => _app.accounts;

  @observable
  bool isSaving = false;

  @action
  Future<void> save({required String name, required String phone}) async {
    final u = _app.user;
    if (u == null) return;
    isSaving = true;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _app.updateUser(u.copyWith(name: name.trim(), phone: phone));
    runInAction(() => isSaving = false);
  }

  
  Future<String?> changePassword(String current, String next) async {
    try {
      await _app.changePassword(current, next);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> forget(String email) => _app.forgetAccount(email);
}
