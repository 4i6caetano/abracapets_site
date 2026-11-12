
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.since,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime? since;

  String get firstName => name.split(' ').first;

  AppUser copyWith({String? name, String? email, String? phone}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role,
        since: since,
      );
}
