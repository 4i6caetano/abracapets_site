import 'package:flutter/material.dart';

enum VolunteerSkill {
  transport('Transporte', Icons.directions_car_outlined),
  fairs('Feiras', Icons.storefront_outlined),
  socialMedia('Redes sociais', Icons.photo_camera_outlined),
  fosterHome('Lar temporário', Icons.home_outlined),
  cleaning('Limpeza e banho', Icons.cleaning_services_outlined);

  const VolunteerSkill(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum Weekday {
  mon('Seg', 'segunda'),
  tue('Ter', 'terça'),
  wed('Qua', 'quarta'),
  thu('Qui', 'quinta'),
  fri('Sex', 'sexta'),
  sat('Sáb', 'sábado'),
  sun('Dom', 'domingo');

  const Weekday(this.short, this.long);
  final String short;
  final String long;
}

enum ShiftPeriod {
  morning('Manhã', Icons.wb_twilight),
  afternoon('Tarde', Icons.wb_sunny_outlined),
  night('Noite', Icons.nights_stay_outlined);

  const ShiftPeriod(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum VolunteerStatus {
  active('Ativa'),
  onLeave('De licença');

  const VolunteerStatus(this.label);
  final String label;
}

class VolunteerActivity {
  const VolunteerActivity({
    required this.title,
    required this.date,
    required this.skill,
    this.detail,
  });

  final String title;
  final DateTime date;
  final VolunteerSkill skill;
  final String? detail;
}


class Volunteer {
  const Volunteer({
    required this.id,
    required this.name,
    required this.whatsapp,
    required this.birthDate,
    required this.skills,
    required this.availability,
    this.instagram,
    this.document,
    this.status = VolunteerStatus.active,
    this.activities = const [],
    this.fosteredAnimalId,
    this.since,
    this.unavailableDates = const [],
  });

  final String id;
  final String name;
  final String whatsapp;
  final String? instagram;
  final String? document;
  final DateTime birthDate;
  final VolunteerStatus status;
  final Set<VolunteerSkill> skills;
  final Map<Weekday, Set<ShiftPeriod>> availability;
  final List<VolunteerActivity> activities;
  final String? fosteredAnimalId;
  final DateTime? since;

  
  final List<DateTime> unavailableDates;

  bool isBlockedOn(DateTime date) => unavailableDates.any(
        (d) => d.year == date.year && d.month == date.month && d.day == date.day,
      );

  
  
  bool isAvailable(Weekday day, Set<ShiftPeriod> periods, {DateTime? date}) {
    if (date != null && isBlockedOn(date)) return false;
    final free = availability[day] ?? const {};
    return periods.isEmpty ? free.isNotEmpty : free.containsAll(periods);
  }

  String get availabilitySummary {
    final days = Weekday.values.where((d) => availability[d]?.isNotEmpty ?? false);
    if (days.isEmpty) return 'Sem disponibilidade';
    final periods = availability.values.expand((e) => e).toSet();
    final p = ShiftPeriod.values
        .where(periods.contains)
        .map((e) => e.label.toLowerCase())
        .join(' e ');
    return '${days.map((d) => d.short).join(', ')} · $p';
  }

  Volunteer copyWith({
    String? name,
    String? whatsapp,
    String? instagram,
    VolunteerStatus? status,
    Set<VolunteerSkill>? skills,
    Map<Weekday, Set<ShiftPeriod>>? availability,
    List<DateTime>? unavailableDates,
  }) =>
      Volunteer(
        id: id,
        name: name ?? this.name,
        whatsapp: whatsapp ?? this.whatsapp,
        instagram: instagram ?? this.instagram,
        document: document,
        birthDate: birthDate,
        status: status ?? this.status,
        skills: skills ?? this.skills,
        availability: availability ?? this.availability,
        activities: activities,
        fosteredAnimalId: fosteredAnimalId,
        since: since,
        unavailableDates: unavailableDates ?? this.unavailableDates,
      );
}
