import 'package:mobx/mobx.dart';

import '../../../data/models/adoption.dart';
import '../../../data/models/home.dart';
import '../../../data/models/person.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'person_profile_view_model.g.dart';

class PersonProfileViewModel = PersonProfileViewModelBase
    with _$PersonProfileViewModel;


abstract class PersonProfileViewModelBase with Store {
  PersonProfileViewModelBase(this.personId, this._people, this._animals);

  final String personId;
  final PeopleRepository _people;
  final AnimalRepository _animals;

  @observable
  bool sensitiveVisible = false;

  @computed
  Person? get person {
    _people.people.length;
    return _people.personById(personId);
  }

  @computed
  List<Adoption> get adoptions => _people.adoptionsOfPerson(personId);

  @computed
  List<Home> get homes => _people.homes
      .where((h) => h.responsibleIds.contains(personId))
      .toList();

  String animalName(String id) => _animals.byId(id)?.name ?? '—';

  @action
  void toggleSensitive() => sensitiveVisible = !sensitiveVisible;

  @action
  void restrict(String reason, String addedBy) {
    final p = person;
    if (p == null) return;
    _people.updatePerson(
      p.copyWith(
        restriction: Restriction(
          reason: reason,
          date: DateTime.now(),
          addedBy: addedBy,
        ),
      ),
    );
  }

  @action
  void removeRestriction() {
    final p = person;
    if (p != null) _people.updatePerson(p.copyWith(clearRestriction: true));
  }
}
