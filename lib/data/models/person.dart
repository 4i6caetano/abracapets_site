
class Person {
  const Person({
    required this.id,
    required this.fullName,
    required this.cpf,
    required this.birthDate,
    required this.phone,
    required this.email,
    required this.address,
    this.instagram,
    this.hasDocumentPhoto = false,
    this.restriction,
  });

  final String id;
  final String fullName;
  final String cpf;
  final DateTime birthDate;
  final String phone;
  final String email;
  final String address;
  final String? instagram;
  final bool hasDocumentPhoto;

  
  final Restriction? restriction;

  bool get isRestricted => restriction != null;

  Person copyWith({Restriction? restriction, bool clearRestriction = false}) =>
      Person(
        id: id,
        fullName: fullName,
        cpf: cpf,
        birthDate: birthDate,
        phone: phone,
        email: email,
        address: address,
        instagram: instagram,
        hasDocumentPhoto: hasDocumentPhoto,
        restriction:
            clearRestriction ? null : (restriction ?? this.restriction),
      );
}

class Restriction {
  const Restriction({
    required this.reason,
    required this.date,
    required this.addedBy,
  });

  final String reason;
  final DateTime date;
  final String addedBy;
}
