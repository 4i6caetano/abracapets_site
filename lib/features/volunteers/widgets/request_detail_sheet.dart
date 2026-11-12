import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/detail_sheet.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/request.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/people_repository.dart';



Future<void> showRequestDetails(
  BuildContext context,
  AppRequest r, {
  VoidCallback? onApprove,
  VoidCallback? onReject,
}) {
  final animal =
      r.animalId == null ? null : locator<AnimalRepository>().byId(r.animalId!);
  final person =
      r.personId == null ? null : locator<PeopleRepository>().personById(r.personId!);
  final restricted = person?.isRestricted ?? false;
  final pending = r.status == RequestStatus.pending;
  final score = (r.screeningScore * 100).round();
  final scoreColor = r.screeningScore >= 0.7
      ? AppColors.success
      : r.screeningScore >= 0.4
          ? AppColors.warning
          : AppColors.danger;

  void go(BuildContext sheet, String route) {
    Navigator.pop(sheet);
    context.push(route);
  }

  return showAdaptiveSheet<void>(
    context,
    builder: (sheet) => DetailSheet(
      title: r.name,
      subtitle: 'Solicitação de ${r.type.label.toLowerCase()} · '
          '${Fmt.relative(r.date)}',
      icon: restricted ? Icons.warning_amber_rounded : r.type.icon,
      color: restricted ? AppColors.danger : AppColors.info,
      highlight: 'Pré-triagem $score%',
      highlightColor: scoreColor,
      badge: restricted
          ? const StatusBadge(
              label: 'RESTRITA', color: AppColors.danger, solid: true)
          : StatusBadge(
              label: switch (r.status) {
                RequestStatus.pending => 'Pendente',
                RequestStatus.approved => 'Aprovada',
                RequestStatus.rejected => 'Recusada',
              },
              color: switch (r.status) {
                RequestStatus.pending => AppColors.info,
                RequestStatus.approved => AppColors.success,
                RequestStatus.rejected => AppColors.danger,
              },
            ),
      note: restricted
          ? 'Atenção: pessoa na lista restrita. '
              'Motivo: ${person!.restriction!.reason}'
          : r.summary,
      rows: [
        DetailRow(Icons.phone_outlined, 'Contato', r.phone),
        DetailRow(Icons.event_outlined, 'Recebida em', Fmt.date(r.date)),
        if (r.skills.isNotEmpty)
          DetailRow(Icons.handyman_outlined, 'Pode ajudar com',
              r.skills.join(', ')),
        if (animal != null)
          DetailRow(
            Icons.pets_outlined,
            'Animal de interesse',
            animal.name,
            onTap: () => go(sheet, AppRoutes.petDetail(animal.id)),
          ),
        if (person != null)
          DetailRow(
            Icons.badge_outlined,
            'Ficha do solicitante',
            person.fullName,
            color: restricted ? AppColors.danger : null,
            onTap: () => go(sheet, AppRoutes.person(person.id)),
          ),
      ],
      actions: [
        if (pending && onReject != null)
          OutlinedButton(
            onPressed: () {
              Navigator.pop(sheet);
              onReject();
            },
            child: const Text('Recusar'),
          ),
        if (pending && !restricted && onApprove != null)
          FilledButton(
            onPressed: () {
              Navigator.pop(sheet);
              onApprove();
            },
            child: Text(r.type == RequestType.report ? 'Atender' : 'Aprovar'),
          ),
        if (!pending || (onApprove == null && onReject == null))
          OutlinedButton.icon(
            onPressed: () => showMessage(sheet, 'Abrindo WhatsApp ${r.phone}',
                icon: Icons.chat),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('WhatsApp'),
          ),
      ],
    ),
  );
}
