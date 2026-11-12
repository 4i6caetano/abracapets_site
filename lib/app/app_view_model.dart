import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../data/models/app_user.dart';
import '../data/repositories/session_repository.dart';

part 'app_view_model.g.dart';


class AppViewModel = AppViewModelBase with _$AppViewModel;

abstract class AppViewModelBase with Store {
  AppViewModelBase(this._sessions) {
    user = _sessions.restore();
    accounts.addAll(_sessions.accounts);
  }

  final SessionRepository _sessions;

  @observable
  AppUser? user;

  
  final accounts = ObservableList<AppUser>();

  @observable
  ThemeMode themeMode = ThemeMode.light;

  @computed
  bool get isLoggedIn => user != null;

  @computed
  bool get isDark => themeMode == ThemeMode.dark;

  bool isKnownAccount(String email) => _sessions.isKnown(email);

  
  @action
  Future<void> signIn(String email, String password) async {
    final logged = await _sessions.signIn(email, password);
    runInAction(() {
      user = logged;
      _refreshAccounts();
    });
  }

  @action
  Future<void> signOut() async {
    user = null;
    await _sessions.signOut();
  }

  @action
  Future<void> updateUser(AppUser value) async {
    user = value;
    await _sessions.updateUser(value);
    runInAction(_refreshAccounts);
  }

  Future<void> changePassword(String current, String next) =>
      _sessions.changePassword(user!.email, current, next);

  @action
  Future<void> forgetAccount(String email) async {
    await _sessions.removeAccount(email);
    runInAction(_refreshAccounts);
  }

  @action
  void toggleTheme(bool dark) =>
      themeMode = dark ? ThemeMode.dark : ThemeMode.light;

  void _refreshAccounts() {
    accounts
      ..clear()
      ..addAll(_sessions.accounts);
  }
}
