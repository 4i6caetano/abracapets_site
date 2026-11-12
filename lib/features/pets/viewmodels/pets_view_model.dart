import 'package:mobx/mobx.dart';

import '../../../data/models/animal.dart';
import '../../../data/repositories/animal_repository.dart';

part 'pets_view_model.g.dart';

class PetsViewModel = PetsViewModelBase with _$PetsViewModel;

abstract class PetsViewModelBase with Store {
  PetsViewModelBase(this._repository);

  final AnimalRepository _repository;

  @observable
  String query = '';

  
  @observable
  AnimalStatus? status;

  @observable
  Species? species;

  @observable
  Sex? sex;

  @observable
  bool onlyCastrated = false;

  @observable
  bool onlyVaccinated = false;

  @computed
  int get activeFilterCount =>
      (species != null ? 1 : 0) +
      (sex != null ? 1 : 0) +
      (onlyCastrated ? 1 : 0) +
      (onlyVaccinated ? 1 : 0);

  @computed
  int get total => _repository.animals.length;

  @computed
  List<Animal> get pets {
    final q = query.trim().toLowerCase();
    return _repository.animals.where((a) {
      if (status != null && a.status != status) return false;
      if (species != null && a.species != species) return false;
      if (sex != null && a.sex != sex) return false;
      if (onlyCastrated && !a.castrated) return false;
      if (onlyVaccinated && !a.vaccinated) return false;
      if (q.isNotEmpty &&
          !a.name.toLowerCase().contains(q) &&
          !a.breed.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  int countFor(AnimalStatus? s) => s == null
      ? _repository.animals.length
      : _repository.animals.where((a) => a.status == s).length;

  @action
  void setQuery(String value) => query = value;

  @action
  void setStatus(AnimalStatus? value) => status = value;

  @action
  void applyFilters({
    Species? species,
    Sex? sex,
    required bool castrated,
    required bool vaccinated,
  }) {
    this.species = species;
    this.sex = sex;
    onlyCastrated = castrated;
    onlyVaccinated = vaccinated;
  }

  @action
  void clearSpecies() => species = null;

  @action
  void clearSex() => sex = null;

  @action
  void clearCastrated() => onlyCastrated = false;

  @action
  void clearVaccinated() => onlyVaccinated = false;

  @action
  void clearFilters() {
    species = null;
    sex = null;
    onlyCastrated = false;
    onlyVaccinated = false;
  }
}
