import 'package:mobx/mobx.dart';

import '../../../data/mock/mock_data.dart';
import '../../../data/models/animal.dart';
import '../../../data/repositories/animal_repository.dart';

part 'pet_edit_view_model.g.dart';

class PetEditViewModel = PetEditViewModelBase with _$PetEditViewModel;

abstract class PetEditViewModelBase with Store {
  PetEditViewModelBase(
    this._repository,
    String? petId, {
    this.author = 'Equipe',
  }) : _original = petId == null ? null : _repository.byId(petId) {
    final a = _original;
    if (a != null) {
      name = a.name;
      species = a.species;
      breed = a.breed;
      sex = a.sex;
      status = a.status;
      birthDate = a.birthDate;
      rescueDate = a.rescueDate;
      description = a.description;
      rescueStory = a.rescueStory;
      castrated = a.castrated;
      vaccinated = a.vaccinated;
      showOnShowcase = a.showOnShowcase;
      photos.addAll(a.allPhotos);
    }
  }

  static const descriptionMax = 300;
  static const storyMax = 1000;

  final AnimalRepository _repository;
  final String author;
  final Animal? _original;

  bool get isNew => _original == null;

  @observable
  String name = '';

  @observable
  Species species = Species.cat;

  @observable
  String breed = '';

  @observable
  Sex sex = Sex.male;

  @observable
  AnimalStatus status = AnimalStatus.inTreatment;

  @observable
  DateTime? birthDate;

  @observable
  DateTime? rescueDate = DateTime.now();

  @observable
  String description = '';

  @observable
  String rescueStory = '';

  @observable
  bool castrated = false;

  @observable
  bool vaccinated = false;

  @observable
  bool showOnShowcase = false;

  final photos = ObservableList<String>();

  @observable
  bool isSaving = false;

  @observable
  bool isDirty = false;

  @computed
  String? get coverUrl => photos.isEmpty ? null : photos.first;

  @computed
  int get descriptionLength => description.length;

  
  @computed
  bool get canShowOnShowcase => status != AnimalStatus.adopted;

  
  String? validateBirthDate() {
    if (birthDate == null) return 'Informe a data estimada de nascimento';
    if (birthDate!.isAfter(DateTime.now())) return 'A data não pode ser futura';
    return null;
  }

  String? validateRescueDate() {
    if (rescueDate == null) return 'Informe a data do resgate';
    if (rescueDate!.isAfter(DateTime.now())) {
      return 'A data não pode ser futura';
    }
    if (birthDate != null && rescueDate!.isBefore(birthDate!)) {
      return 'O resgate não pode ser antes do nascimento';
    }
    return null;
  }

  String? validatePhotos() =>
      photos.isEmpty ? 'Adicione ao menos a foto principal' : null;

  
  @action
  void _touch() => isDirty = true;

  @action
  void discardChanges() => isDirty = false;

  @action
  void setName(String v) {
    name = v;
    _touch();
  }

  @action
  void setSpecies(Species v) {
    species = v;
    _touch();
  }

  @action
  void setBreed(String v) {
    breed = v;
    _touch();
  }

  @action
  void setSex(Sex v) {
    sex = v;
    _touch();
  }

  @action
  void setStatus(AnimalStatus v) {
    status = v;
    if (v == AnimalStatus.adopted) showOnShowcase = false;
    _touch();
  }

  @action
  void setBirthDate(DateTime v) {
    birthDate = v;
    _touch();
  }

  @action
  void setRescueDate(DateTime v) {
    rescueDate = v;
    _touch();
  }

  @action
  void setDescription(String v) {
    description = v;
    _touch();
  }

  @action
  void setRescueStory(String v) {
    rescueStory = v;
    _touch();
  }

  @action
  void setCastrated(bool v) {
    castrated = v;
    _touch();
  }

  @action
  void setVaccinated(bool v) {
    vaccinated = v;
    _touch();
  }

  @action
  void setShowOnShowcase(bool v) {
    showOnShowcase = v;
    _touch();
  }

  
  @action
  void addPhoto() {
    
    final start = DateTime.now().millisecondsSinceEpoch % 40;
    for (var k = 0; k < 40; k++) {
      final seed = (start + k) % 40;
      final url = species == Species.cat ? catPhoto(seed) : dogPhoto(seed);
      if (!photos.contains(url)) {
        photos.add(url);
        break;
      }
    }
    _touch();
  }

  @action
  void removePhoto(int index) {
    photos.removeAt(index);
    _touch();
  }

  @action
  void makeCover(int index) {
    final url = photos.removeAt(index);
    photos.insert(0, url);
    _touch();
  }

  @action
  Future<String> save() async {
    isSaving = true;
    final animal = Animal(
      id: _original?.id ?? _repository.newId(),
      name: name.trim(),
      species: species,
      breed: breed.trim(),
      sex: sex,
      description: description.trim(),
      rescueStory: rescueStory.trim(),
      birthDate: birthDate!,
      rescueDate: rescueDate!,
      status: status,
      mainPhotoUrl: photos.first,
      photoUrls: photos.skip(1).toList(),
      videoUrls: _original?.videoUrls ?? const [],
      castrated: castrated,
      vaccinated: vaccinated,
      showOnShowcase: showOnShowcase && canShowOnShowcase,
      currentHomeId: _original?.currentHomeId,
      updatedAt: DateTime.now(),
      updatedBy: author,
    );
    await _repository.save(animal);
    isSaving = false;
    isDirty = false;
    return animal.id;
  }
}
