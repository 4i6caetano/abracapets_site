import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum Species {
  dog('Cão', Icons.pets),
  cat('Gato', Icons.cruelty_free);

  const Species(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum Sex {
  male('Macho'),
  female('Fêmea');

  const Sex(this.label);
  final String label;
}

enum AnimalStatus {
  inTreatment('Em tratamento', AppColors.warning),
  available('Disponível', AppColors.success),
  interviewing('Em entrevista', AppColors.info),
  fostered('Lar temporário', AppColors.primary),
  adopted('Adotado', AppColors.accentDark);

  const AnimalStatus(this.label, this.color);
  final String label;
  final Color color;
}


class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.sex,
    required this.description,
    required this.rescueStory,
    required this.birthDate,
    required this.rescueDate,
    required this.status,
    required this.mainPhotoUrl,
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.castrated = false,
    this.vaccinated = false,
    this.showOnShowcase = false,
    this.currentHomeId,
    this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String name;
  final Species species;
  final String breed;
  final Sex sex;
  final String description;
  final String rescueStory;

  
  final DateTime birthDate;
  final DateTime rescueDate;
  final AnimalStatus status;
  final String mainPhotoUrl;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final bool castrated;
  final bool vaccinated;
  final bool showOnShowcase;
  final String? currentHomeId;
  final DateTime? updatedAt;
  final String? updatedBy;

  List<String> get allPhotos => [mainPhotoUrl, ...photoUrls];

  Animal copyWith({
    String? name,
    Species? species,
    String? breed,
    Sex? sex,
    String? description,
    String? rescueStory,
    DateTime? birthDate,
    DateTime? rescueDate,
    AnimalStatus? status,
    String? mainPhotoUrl,
    List<String>? photoUrls,
    bool? castrated,
    bool? vaccinated,
    bool? showOnShowcase,
    String? currentHomeId,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      Animal(
        id: id,
        name: name ?? this.name,
        species: species ?? this.species,
        breed: breed ?? this.breed,
        sex: sex ?? this.sex,
        description: description ?? this.description,
        rescueStory: rescueStory ?? this.rescueStory,
        birthDate: birthDate ?? this.birthDate,
        rescueDate: rescueDate ?? this.rescueDate,
        status: status ?? this.status,
        mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
        photoUrls: photoUrls ?? this.photoUrls,
        videoUrls: videoUrls,
        castrated: castrated ?? this.castrated,
        vaccinated: vaccinated ?? this.vaccinated,
        showOnShowcase: showOnShowcase ?? this.showOnShowcase,
        currentHomeId: currentHomeId ?? this.currentHomeId,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );
}
