import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/detail_sheet.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/adoption.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/people_repository.dart';


Future<void> showAdoptionDetails(BuildContext context, Adoption ad) {
  final people = locator<PeopleRepository>();
  final animal = locator<AnimalRepository>().byId(ad.animalId);
  final adopter = people.personById(ad.adopterId);
  final home = people.homeById(ad.homeId);

  void go(BuildContext sheet, String route) {
    Navigator.pop(sheet);
    context.push(route);
  }

  return showAdaptiveSheet<void>(
    context,
    builder: (sheet) => DetailSheet(
      title: 'Adoção de ${animal?.name ?? '—'}',
      subtitle: 'Registrada em ${Fmt.date(ad.date)}',
      icon: ad.wasReturned
          ? Icons.assignment_return_outlined
          : Icons.assignment_turned_in_outlined,
      color: ad.wasReturned ? AppColors.danger : AppColors.success,
      badge: StatusBadge(
        label: ad.wasReturned ? 'Devolvido' : 'Ativa',
        color: ad.wasReturned ? AppColors.danger : AppColors.success,
      ),
      note: ad.wasReturned
          ? 'Devolvido em ${Fmt.date(ad.returnedAt!)}. '
              'Motivo: ${ad.returnReason ?? 'não informado'}'
          : null,
      rows: [
        if (animal != null)
          DetailRow(Icons.pets_outlined, 'Animal', animal.name,
              onTap: () => go(sheet, AppRoutes.petDetail(animal.id))),
        if (adopter != null)
          DetailRow(Icons.person_outline, 'Adotante', adopter.fullName,
              onTap: () => go(sheet, AppRoutes.person(adopter.id))),
        if (home != null)
          DetailRow(Icons.home_outlined, 'Lar', home.isTemporary
              ? 'Lar temporário · ${home.city}'
              : '${home.propertyType.label} · ${home.city}',
              onTap: () => go(sheet, AppRoutes.home(home.id))),
        DetailRow(
          Icons.supervisor_account_outlined,
          'Segundo responsável',
          ad.secondaryResponsibleName == null
              ? 'Não informado'
              : '${ad.secondaryResponsibleName} · ${ad.secondaryResponsiblePhone ?? ''}',
        ),
        DetailRow(
          Icons.description_outlined,
          'Termo de adoção',
          ad.termFileName ?? 'Pendente',
          color: ad.termFileName == null ? AppColors.warning : null,
        ),
      ],
      actions: [
        if (ad.termFileName != null)
          OutlinedButton.icon(
            onPressed: () => showMessage(
              sheet,
              'Abrindo ${ad.termFileName} (simulação)',
              icon: Icons.picture_as_pdf_outlined,
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ver termo'),
          ),
      ],
    ),
  );
}
