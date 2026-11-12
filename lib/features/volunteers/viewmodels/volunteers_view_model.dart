import 'package:mobx/mobx.dart';

import '../../../data/models/request.dart';
import '../../../data/models/volunteer.dart';
import '../../../data/repositories/people_repository.dart';

part 'volunteers_view_model.g.dart';

class VolunteersViewModel = VolunteersViewModelBase with _$VolunteersViewModel;

abstract class VolunteersViewModelBase with Store {
  VolunteersViewModelBase(this._repository);

  final PeopleRepository _repository;

  
  @observable
  Weekday day = Weekday.values[DateTime.now().weekday - 1];

  
  @observable
  DateTime? customDate;

  
  @observable
  ShiftPeriod? period = ShiftPeriod.morning;

  
  @observable
  int? customStart;

  @observable
  int? customEnd;

  
  @observable
  VolunteerSkill? skill;

  @computed
  Weekday get effectiveDay =>
      customDate == null ? day : Weekday.values[customDate!.weekday - 1];

  @computed
  bool get hasCustomTime => customStart != null && customEnd != null;

  
  @computed
  Set<ShiftPeriod> get requiredPeriods {
    if (hasCustomTime) return periodsForRange(customStart!, customEnd!);
    return period == null ? const {} : {period!};
  }

  
  static Set<ShiftPeriod> periodsForRange(int start, int end) {
    const ranges = {
      ShiftPeriod.morning: (360, 720),
      ShiftPeriod.afternoon: (720, 1080),
      ShiftPeriod.night: (1080, 1440),
    };
    final result = {
      for (final e in ranges.entries)
        if (start < e.value.$2 && end > e.value.$1) e.key,
    };
    if (start < 360) result.add(ShiftPeriod.night);
    return result;
  }

  static String formatMinutes(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @computed
  String? get customTimeLabel => hasCustomTime
      ? '${formatMinutes(customStart!)}–${formatMinutes(customEnd!)}'
      : null;

  @computed
  List<Volunteer> get activeVolunteers => _repository.volunteers
      .where((v) => v.status == VolunteerStatus.active)
      .toList();

  bool _matchesSkill(Volunteer v) => skill == null || v.skills.contains(skill);

  @computed
  List<Volunteer> get available => activeVolunteers
      .where((v) =>
          v.isAvailable(effectiveDay, requiredPeriods, date: customDate))
      .where(_matchesSkill)
      .toList();

  
  @computed
  List<Volunteer> get otherPeriod => requiredPeriods.isEmpty
      ? const []
      : activeVolunteers
          .where((v) =>
              !v.isAvailable(effectiveDay, requiredPeriods, date: customDate) &&
              v.isAvailable(effectiveDay, const {}, date: customDate))
          .where(_matchesSkill)
          .toList();

  
  
  @computed
  List<Volunteer> get blockedOnDate => customDate == null
      ? const []
      : activeVolunteers
          .where((v) =>
              v.isBlockedOn(customDate!) &&
              v.isAvailable(effectiveDay, requiredPeriods))
          .where(_matchesSkill)
          .toList();

  @computed
  String get availabilityLabel {
    final n = available.length;
    final d = effectiveDay;
    final weekend = d == Weekday.sat || d == Weekday.sun;
    final dayLabel = customDate == null
        ? '${weekend ? 'no' : 'na'} ${d.long}'
        : 'em ${d.long}, ${customDate!.day.toString().padLeft(2, '0')}/'
            '${customDate!.month.toString().padLeft(2, '0')}';
    final timeLabel = hasCustomTime
        ? ' das ${formatMinutes(customStart!)} às ${formatMinutes(customEnd!)}'
        : period == null
            ? ''
            : ' de ${period!.label.toLowerCase()}';
    final s = skill == null ? '' : ' para ${skill!.label.toLowerCase()}';
    return '$n ${n == 1 ? 'livre' : 'livres'} $dayLabel$timeLabel$s';
  }

  
  @observable
  String query = '';

  @observable
  VolunteerStatus? statusFilter;

  @computed
  List<Volunteer> get all {
    final q = query.trim().toLowerCase();
    return _repository.volunteers
        .where((v) => statusFilter == null || v.status == statusFilter)
        .where((v) =>
            q.isEmpty ||
            v.name.toLowerCase().contains(q) ||
            v.skills.any((s) => s.label.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @computed
  int get totalVolunteers => _repository.volunteers.length;

  
  @observable
  RequestType requestType = RequestType.volunteering;

  @computed
  List<AppRequest> get requests => _repository.requests
      .where((r) => r.type == requestType)
      .toList()
    ..sort((a, b) {
      if (a.status != b.status) {
        return a.status == RequestStatus.pending ? -1 : 1;
      }
      return b.date.compareTo(a.date);
    });

  int pendingCount(RequestType type) => _repository.requests
      .where((r) => r.type == type && r.status == RequestStatus.pending)
      .length;

  @computed
  int get pendingTotal => _repository.requests
      .where((r) => r.status == RequestStatus.pending)
      .length;

  bool isRestricted(AppRequest r) =>
      r.personId != null &&
      (_repository.personById(r.personId!)?.isRestricted ?? false);

  
  @action
  void setDay(Weekday value) {
    day = value;
    customDate = null;
  }

  @action
  void setCustomDate(DateTime value) =>
      customDate = DateTime(value.year, value.month, value.day);

  @action
  void clearCustomDate() => customDate = null;

  @action
  void setPeriod(ShiftPeriod? value) {
    period = value;
    customStart = null;
    customEnd = null;
  }

  
  @action
  String? setCustomTime(int start, int end) {
    if (end <= start) return 'O horário final deve ser depois do inicial';
    customStart = start;
    customEnd = end;
    return null;
  }

  @action
  void clearCustomTime() {
    customStart = null;
    customEnd = null;
  }

  @action
  void setSkill(VolunteerSkill? value) => skill = value;

  @action
  void setQuery(String value) => query = value;

  @action
  void setStatusFilter(VolunteerStatus? value) => statusFilter = value;

  @action
  void setRequestType(RequestType value) => requestType = value;

  @action
  void approve(AppRequest request) {
    _repository.updateRequest(request.copyWith(status: RequestStatus.approved));
    if (request.type == RequestType.volunteering) {
      _repository.updateVolunteer(
        Volunteer(
          id: 'v${DateTime.now().microsecondsSinceEpoch}',
          name: request.name,
          whatsapp: request.phone,
          birthDate: DateTime(1995),
          since: DateTime.now(),
          skills: {
            for (final s in VolunteerSkill.values)
              if (request.skills.contains(s.label)) s,
          },
          availability: const {
            Weekday.sat: {ShiftPeriod.morning},
          },
        ),
      );
    }
  }

  @action
  void reject(AppRequest request) => _repository
      .updateRequest(request.copyWith(status: RequestStatus.rejected));

  @action
  void addVolunteer(Volunteer volunteer) =>
      _repository.updateVolunteer(volunteer);
}
