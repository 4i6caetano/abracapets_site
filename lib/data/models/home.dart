import 'package:flutter/material.dart';

enum PropertyType {
  house('Casa', Icons.house_outlined),
  apartment('Apartamento', Icons.apartment_outlined),
  farm('Sítio', Icons.agriculture_outlined);

  const PropertyType(this.label, this.icon);
  final String label;
  final IconData icon;
}


class Home {
  const Home({
    required this.id,
    required this.propertyType,
    required this.sizeM2,
    required this.hasProtectionNet,
    required this.familyPetsCount,
    required this.isTemporary,
    required this.responsibleIds,
    required this.address,
    required this.city,
    this.vacancies = 0,
    this.acceptsDogs = true,
    this.acceptsCats = true,
    this.hostedAnimalIds = const [],
    this.photoUrl,
    this.notes,
  });

  final String id;
  final PropertyType propertyType;
  final int sizeM2;
  final bool hasProtectionNet;
  final int familyPetsCount;
  final bool isTemporary;
  final int vacancies;
  final List<String> responsibleIds;
  final String address;
  final String city;
  final bool acceptsDogs;
  final bool acceptsCats;
  final List<String> hostedAnimalIds;
  final String? photoUrl;
  final String? notes;

  int get freeVacancies =>
      (vacancies - hostedAnimalIds.length).clamp(0, vacancies);
  bool get isFull => isTemporary && freeVacancies == 0;
}
