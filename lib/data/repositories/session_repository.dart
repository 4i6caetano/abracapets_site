import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}







class SessionRepository {
  static const _accountsKey = 'abracapets.accounts';
  static const _sessionKey = 'abracapets.session';

  late final SharedPreferences _prefs;
  final Map<String, _Account> _accounts = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_accountsKey);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((email, value) {
        _accounts[email] = _Account.fromJson(value as Map<String, dynamic>);
      });
    }
  }

  
  AppUser? restore() {
    final email = _prefs.getString(_sessionKey);
    return email == null ? null : _accounts[email]?.user;
  }

  
  List<AppUser> get accounts {
    final list = _accounts.values.toList()
      ..sort((a, b) => b.lastLogin.compareTo(a.lastLogin));
    return list.map((a) => a.user).toList();
  }

  bool isKnown(String email) => _accounts.containsKey(_normalize(email));

  Future<AppUser> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final key = _normalize(email);
    final hash = _hash(key, password);
    final existing = _accounts[key];

    if (existing != null) {
      if (existing.passwordHash != hash) {
        throw const AuthException(
          'Senha incorreta para esta conta. Use a mesma senha do primeiro acesso.',
        );
      }
      existing.lastLogin = DateTime.now();
    } else {
      _accounts[key] = _Account(
        user: AppUser(
          id: 'u${DateTime.now().microsecondsSinceEpoch}',
          name: _nameFromEmail(key),
          email: key,
          phone: '',
          role: 'Organizadora',
          since: DateTime.now(),
        ),
        passwordHash: hash,
        lastLogin: DateTime.now(),
      );
    }
    await _prefs.setString(_sessionKey, key);
    await _persist();
    return _accounts[key]!.user;
  }

  Future<void> signOut() => _prefs.remove(_sessionKey);

  Future<void> updateUser(AppUser user) async {
    final account = _accounts[user.email];
    if (account == null) return;
    account.user = user;
    await _persist();
  }

  Future<void> changePassword(
    String email,
    String current,
    String next,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final account = _accounts[_normalize(email)];
    if (account == null || account.passwordHash != _hash(email, current)) {
      throw const AuthException('Senha atual incorreta');
    }
    account.passwordHash = _hash(email, next);
    await _persist();
  }

  Future<void> removeAccount(String email) async {
    _accounts.remove(_normalize(email));
    await _persist();
  }

  Future<void> _persist() => _prefs.setString(
        _accountsKey,
        jsonEncode(_accounts.map((k, v) => MapEntry(k, v.toJson()))),
      );

  static String _normalize(String email) => email.trim().toLowerCase();

  static String _hash(String email, String password) =>
      sha256.convert(utf8.encode('${_normalize(email)}::$password')).toString();

  
  static String _nameFromEmail(String email) {
    final local = email.split('@').first;
    final parts = local
        .split(RegExp(r'[._\-+0-9]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1));
    final name = parts.join(' ');
    return name.isEmpty ? 'Organizadora' : name;
  }
}

class _Account {
  _Account({
    required this.user,
    required this.passwordHash,
    required this.lastLogin,
  });

  factory _Account.fromJson(Map<String, dynamic> json) => _Account(
        user: AppUser(
          id: json['id'] as String,
          name: json['name'] as String,
          email: json['email'] as String,
          phone: json['phone'] as String? ?? '',
          role: json['role'] as String? ?? 'Organizadora',
          since: DateTime.tryParse(json['since'] as String? ?? ''),
        ),
        passwordHash: json['passwordHash'] as String,
        lastLogin: DateTime.tryParse(json['lastLogin'] as String? ?? '') ??
            DateTime.now(),
      );

  AppUser user;
  String passwordHash;
  DateTime lastLogin;

  Map<String, dynamic> toJson() => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
        'since': user.since?.toIso8601String(),
        'passwordHash': passwordHash,
        'lastLogin': lastLogin.toIso8601String(),
      };
}
