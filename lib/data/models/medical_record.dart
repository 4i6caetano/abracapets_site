import 'package:flutter/material.dart';

enum MedicalRecordType {
  vaccine('Vacina', Icons.vaccines_outlined),
  deworming('Vermífugo', Icons.medication_outlined),
  castration('Castração', Icons.content_cut),
  surgery('Cirurgia', Icons.healing_outlined),
  exam('Exame', Icons.biotech_outlined),
  xRay('Raio-X', Icons.monitor_heart_outlined),
  prescription('Receita', Icons.receipt_long_outlined);

  const MedicalRecordType(this.label, this.icon);
  final String label;
  final IconData icon;
}


class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.animalId,
    required this.type,
    required this.title,
    required this.date,
    this.nextDate,
    this.notes,
    this.attachmentName,
  });

  final String id;
  final String animalId;
  final MedicalRecordType type;
  final String title;
  final DateTime date;

  
  final DateTime? nextDate;
  final String? notes;

  
  final String? attachmentName;

  bool get isScheduled => date.isAfter(DateTime.now());
}
