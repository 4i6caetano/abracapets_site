import 'package:mobx/mobx.dart';

import '../../../data/models/adoption.dart';
import '../../../data/models/animal.dart';
import '../../../data/models/home.dart';
import '../../../data/models/person.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'home_profile_view_model.g.dart';

class HomeProfileViewModel = HomeProfileViewModelBase with _$HomeProfileViewModel;

abstract class HomeProfileViewModelBase with Store {
  HomeProfileViewModelBase(this.homeId, this._people, this._animals);

  final String homeId;
  final PeopleRepository _people;
  final AnimalRepository _animals;

  
  @observable
  bool addressVisible = false;

  @computed
  Home? get home => _people.homeById(homeId);

  @computed
  String get title => home == null ? '' : _people.homeTitle(home!);

  @computed
  List<Person> get responsibles => (home?.responsibleIds ?? const [])
      .map(_people.personById)
      .whereType<Person>()
      .toList();

  @computed
  List<Animal> get animals => (home?.hostedAnimalIds ?? const [])
      .map(_animals.byId)
      .whereType<Animal>()
      .toList();

  @computed
  List<Adoption> get adoptions => _people.adoptionsOfHome(homeId);

  String animalName(String id) => _animals.byId(id)?.name ?? '—';

  @action
  void toggleAddress() => addressVisible = !addressVisible;
}
