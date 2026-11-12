import 'package:mobx/mobx.dart';

import '../mock/mock_data.dart';
import '../models/adoption.dart';
import '../models/animal.dart';
import '../models/medical_record.dart';



class AnimalRepository {
  final animals = ObservableList<Animal>.of(MockData.animals);
  final medicalRecords = ObservableList<MedicalRecord>.of(MockData.medicalRecords);
  final homeStays = List<HomeStay>.of(MockData.homeStays);

  Animal? byId(String id) {
    for (final a in animals) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<MedicalRecord> recordsOf(String animalId) =>
      medicalRecords.where((r) => r.animalId == animalId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<HomeStay> staysOf(String animalId) =>
      homeStays.where((s) => s.animalId == animalId).toList()
        ..sort((a, b) => b.start.compareTo(a.start));

  Future<void> save(Animal animal) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    runInAction(() {
      final index = animals.indexWhere((a) => a.id == animal.id);
      if (index >= 0) {
        animals[index] = animal;
      } else {
        animals.insert(0, animal);
      }
    });
  }

  void update(Animal animal) => runInAction(() {
        final index = animals.indexWhere((a) => a.id == animal.id);
        if (index >= 0) animals[index] = animal;
      });

  void addRecord(MedicalRecord record) =>
      runInAction(() => medicalRecords.add(record));

  String newId() => 'a${DateTime.now().microsecondsSinceEpoch}';
}
