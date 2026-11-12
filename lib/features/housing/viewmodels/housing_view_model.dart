import 'package:mobx/mobx.dart';

import '../../../data/models/animal.dart';
import '../../../data/models/home.dart';
import '../../../data/models/person.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'housing_view_model.g.dart';

enum TempHomeFilter { all, withVacancy, dogs, cats }

class HousingViewModel = HousingViewModelBase with _$HousingViewModel;

abstract class HousingViewModelBase with Store {
  HousingViewModelBase(this._people, this._animals);

  final PeopleRepository _people;
  final AnimalRepository _animals;

  @observable
  TempHomeFilter tempFilter = TempHomeFilter.all;

  @observable
  String adopterQuery = '';

  @computed
  List<Home> get temporaryHomes => _people.homes.where((h) {
        if (!h.isTemporary) return false;
        return switch (tempFilter) {
          TempHomeFilter.all => true,
          TempHomeFilter.withVacancy => h.freeVacancies > 0,
          TempHomeFilter.dogs => h.acceptsDogs,
          TempHomeFilter.cats => h.acceptsCats,
        };
      }).toList();

  @computed
  int get totalTemporary => _people.homes.where((h) => h.isTemporary).length;

  @computed
  int get freeVacancies => _people.homes
      .where((h) => h.isTemporary)
      .fold(0, (s, h) => s + h.freeVacancies);

  @computed
  List<Home> get definitiveHomes =>
      _people.homes.where((h) => !h.isTemporary).toList();

  @computed
  List<Person> get adopters {
    final q = adopterQuery.trim().toLowerCase();
    return _people.people
        .where((p) => !p.isRestricted)
        .where((p) =>
            q.isEmpty ||
            p.fullName.toLowerCase().contains(q) ||
            p.email.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  @computed
  List<Person> get restricted =>
      _people.people.where((p) => p.isRestricted).toList()
        ..sort((a, b) => b.restriction!.date.compareTo(a.restriction!.date));

  String homeTitle(Home h) => _people.homeTitle(h);

  Person? responsible(Home h) =>
      h.responsibleIds.isEmpty ? null : _people.personById(h.responsibleIds.first);

  List<Animal> hostedAnimals(Home h) =>
      h.hostedAnimalIds.map(_animals.byId).whereType<Animal>().toList();

  int adoptionsCount(Person p) => _people.adoptionsOfPerson(p.id).length;

  @action
  void setTempFilter(TempHomeFilter v) => tempFilter = v;

  @action
  void setAdopterQuery(String v) => adopterQuery = v;

  
  @action
  void addRestriction({
    required String name,
    required String cpf,
    required String reason,
    required String addedBy,
  }) {
    final restriction = Restriction(
      reason: reason,
      date: DateTime.now(),
      addedBy: addedBy,
    );
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    Person? existing;
    for (final p in _people.people) {
      if (p.cpf.replaceAll(RegExp(r'\D'), '') == digits) existing = p;
    }
    if (existing != null) {
      _people.updatePerson(existing.copyWith(restriction: restriction));
    } else {
      _people.updatePerson(
        Person(
          id: 'p${DateTime.now().microsecondsSinceEpoch}',
          fullName: name,
          cpf: cpf,
          birthDate: DateTime(1990),
          phone: '—',
          email: '—',
          address: '—',
          restriction: restriction,
        ),
      );
    }
  }

  @action
  void removeRestriction(Person p) =>
      _people.updatePerson(p.copyWith(clearRestriction: true));
}
