import 'package:flutter/material.dart';

enum RequestType {
  adoption('Adoção', Icons.favorite_outline),
  volunteering('Voluntariado', Icons.volunteer_activism_outlined),
  report('Denúncia', Icons.report_outlined);

  const RequestType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum RequestStatus { pending, approved, rejected }


class AppRequest {
  const AppRequest({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.date,
    required this.summary,
    required this.screeningScore,
    this.animalId,
    this.personId,
    this.skills = const [],
    this.status = RequestStatus.pending,
  });

  final String id;
  final RequestType type;
  final String name;
  final String phone;
  final DateTime date;
  final String summary;

  
  final double screeningScore;
  final String? animalId;
  final String? personId;
  final List<String> skills;
  final RequestStatus status;

  AppRequest copyWith({RequestStatus? status}) => AppRequest(
        id: id,
        type: type,
        name: name,
        phone: phone,
        date: date,
        summary: summary,
        screeningScore: screeningScore,
        animalId: animalId,
        personId: personId,
        skills: skills,
        status: status ?? this.status,
      );
}
