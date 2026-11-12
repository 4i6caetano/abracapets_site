import 'package:mobx/mobx.dart';

import '../mock/mock_data.dart';
import '../models/adoption.dart';
import '../models/home.dart';
import '../models/person.dart';
import '../models/request.dart';
import '../models/volunteer.dart';


class PeopleRepository {
  final people = ObservableList<Person>.of(MockData.people);
  final homes = ObservableList<Home>.of(MockData.homes);
  final adoptions = ObservableList<Adoption>.of(MockData.adoptions);
  final volunteers = ObservableList<Volunteer>.of(MockData.volunteers);
  final requests = ObservableList<AppRequest>.of(MockData.requests);

  Person? personById(String id) => _find(people, (p) => p.id == id);
  Home? homeById(String id) => _find(homes, (h) => h.id == id);
  Volunteer? volunteerById(String id) => _find(volunteers, (v) => v.id == id);

  List<Adoption> adoptionsOfAnimal(String animalId) =>
      adoptions.where((a) => a.animalId == animalId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<Adoption> adoptionsOfPerson(String personId) =>
      adoptions.where((a) => a.adopterId == personId).toList();

  List<Adoption> adoptionsOfHome(String homeId) =>
      adoptions.where((a) => a.homeId == homeId).toList();

  String homeTitle(Home home) {
    final names = home.responsibleIds
        .map(personById)
        .whereType<Person>()
        .map((p) => p.fullName)
        .toList();
    return names.isEmpty ? 'Lar sem responsável' : names.join(' & ');
  }

  void updatePerson(Person person) => runInAction(() {
        final i = people.indexWhere((p) => p.id == person.id);
        if (i >= 0) {
          people[i] = person;
        } else {
          people.add(person);
        }
      });

  void updateVolunteer(Volunteer volunteer) => runInAction(() {
        final i = volunteers.indexWhere((v) => v.id == volunteer.id);
        if (i >= 0) {
          volunteers[i] = volunteer;
        } else {
          volunteers.add(volunteer);
        }
      });

  void updateRequest(AppRequest request) => runInAction(() {
        final i = requests.indexWhere((r) => r.id == request.id);
        if (i >= 0) requests[i] = request;
      });

  T? _find<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}
