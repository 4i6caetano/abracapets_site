import 'package:mobx/mobx.dart';

import '../../../data/models/adoption.dart';
import '../../../data/models/animal.dart';
import '../../../data/models/finance.dart';
import '../../../data/models/home.dart';
import '../../../data/models/medical_record.dart';
import '../../../data/models/request.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'pet_detail_view_model.g.dart';

enum RecordFilter { all, vaccines, exams, treatments }

class HomeStayView {
  const HomeStayView({
    required this.stay,
    required this.home,
    required this.title,
  });
  final HomeStay stay;
  final Home? home;
  final String title;
}

class PetDetailViewModel = PetDetailViewModelBase with _$PetDetailViewModel;

abstract class PetDetailViewModelBase with Store {
  PetDetailViewModelBase(
    this.petId,
    this._animals,
    this._finance,
    this._people,
  );

  final String petId;
  final AnimalRepository _animals;
  final FinanceRepository _finance;
  final PeopleRepository _people;

  @observable
  int photoIndex = 0;

  @observable
  bool storyExpanded = false;

  @observable
  RecordFilter recordFilter = RecordFilter.all;

  @computed
  Animal? get pet => _animals.byId(petId);

  @computed
  List<MedicalRecord> get records {
    
    _animals.medicalRecords.length;
    final all = _animals.recordsOf(petId);
    return switch (recordFilter) {
      RecordFilter.all => all,
      RecordFilter.vaccines =>
        all
            .where(
              (r) =>
                  r.type == MedicalRecordType.vaccine ||
                  r.type == MedicalRecordType.deworming,
            )
            .toList(),
      RecordFilter.exams =>
        all
            .where(
              (r) =>
                  r.type == MedicalRecordType.exam ||
                  r.type == MedicalRecordType.xRay,
            )
            .toList(),
      RecordFilter.treatments =>
        all
            .where(
              (r) =>
                  r.type == MedicalRecordType.castration ||
                  r.type == MedicalRecordType.surgery ||
                  r.type == MedicalRecordType.prescription,
            )
            .toList(),
    };
  }

  @computed
  List<Expense> get expenses {
    _finance.expenses.length;
    return _finance.expensesOfAnimal(petId);
  }

  @computed
  double get expensesTotal => expenses.fold(0, (sum, e) => sum + e.amount);

  @computed
  List<HomeStayView> get homeHistory => _animals.staysOf(petId).map((s) {
    final home = _people.homeById(s.homeId);
    return HomeStayView(
      stay: s,
      home: home,
      title: home == null ? 'Lar removido' : _people.homeTitle(home),
    );
  }).toList();

  @computed
  List<AppRequest> get interested => _people.requests
      .where(
        (r) =>
            r.animalId == petId &&
            r.type == RequestType.adoption &&
            r.status == RequestStatus.pending,
      )
      .toList();

  @computed
  List<Adoption> get adoptions => _people.adoptionsOfAnimal(petId);

  @action
  void setPhotoIndex(int value) => photoIndex = value;

  @action
  void toggleStory() => storyExpanded = !storyExpanded;

  @action
  void setRecordFilter(RecordFilter value) => recordFilter = value;

  @action
  void changeStatus(AnimalStatus status) {
    final p = pet;
    if (p == null) return;
    _animals.update(p.copyWith(status: status, updatedAt: DateTime.now()));
  }

  @action
  void addRecord({
    required MedicalRecordType type,
    required String title,
    required DateTime date,
    DateTime? nextDate,
    String? notes,
    bool withAttachment = false,
  }) {
    _animals.addRecord(
      MedicalRecord(
        id: 'm${DateTime.now().microsecondsSinceEpoch}',
        animalId: petId,
        type: type,
        title: title,
        date: date,
        nextDate: nextDate,
        notes: notes,
        attachmentName: withAttachment
            ? 'laudo_${title.toLowerCase().replaceAll(' ', '_')}.pdf'
            : null,
      ),
    );
  }
}
