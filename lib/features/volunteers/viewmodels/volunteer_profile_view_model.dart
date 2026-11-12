import 'package:mobx/mobx.dart';

import '../../../data/models/animal.dart';
import '../../../data/models/volunteer.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'volunteer_profile_view_model.g.dart';

class VolunteerProfileViewModel = VolunteerProfileViewModelBase
    with _$VolunteerProfileViewModel;

abstract class VolunteerProfileViewModelBase with Store {
  VolunteerProfileViewModelBase(this.volunteerId, this._people, this._animals);

  final String volunteerId;
  final PeopleRepository _people;
  final AnimalRepository _animals;

  @computed
  Volunteer? get volunteer {
    _people.volunteers.length;
    return _people.volunteerById(volunteerId);
  }

  @computed
  Animal? get fosteredAnimal {
    final id = volunteer?.fosteredAnimalId;
    return id == null ? null : _animals.byId(id);
  }

  @computed
  bool get isActive => volunteer?.status == VolunteerStatus.active;

  @action
  void toggleStatus() {
    final v = volunteer;
    if (v == null) return;
    _people.updateVolunteer(
      v.copyWith(
        status: v.status == VolunteerStatus.active
            ? VolunteerStatus.onLeave
            : VolunteerStatus.active,
      ),
    );
  }

  @action
  void save(Volunteer value) => _people.updateVolunteer(value);
}
