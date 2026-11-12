

class Adoption {
  const Adoption({
    required this.id,
    required this.animalId,
    required this.adopterId,
    required this.homeId,
    required this.date,
    this.secondaryResponsibleName,
    this.secondaryResponsiblePhone,
    this.termFileName,
    this.returnedAt,
    this.returnReason,
  });

  final String id;
  final String animalId;
  final String adopterId;
  final String homeId;
  final DateTime date;
  final String? secondaryResponsibleName;
  final String? secondaryResponsiblePhone;
  final String? termFileName;
  final DateTime? returnedAt;
  final String? returnReason;

  bool get wasReturned => returnedAt != null;
}


class HomeStay {
  const HomeStay({
    required this.animalId,
    required this.homeId,
    required this.start,
    this.end,
  });

  final String animalId;
  final String homeId;
  final DateTime start;
  final DateTime? end;
}
