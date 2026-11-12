import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/detail_sheet.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../data/models/volunteer.dart';
import '../viewmodels/volunteer_profile_view_model.dart';
import '../widgets/availability_grid.dart';
import '../widgets/volunteer_form_sheet.dart';

class VolunteerProfilePage extends StatefulWidget {
  const VolunteerProfilePage({super.key, required this.volunteerId});

  final String volunteerId;

  @override
  State<VolunteerProfilePage> createState() => _VolunteerProfilePageState();
}

class _VolunteerProfilePageState extends State<VolunteerProfilePage> {
  late final _vm =
      VolunteerProfileViewModel(widget.volunteerId, locator(), locator());

  Future<void> _edit() async {
    final updated = await showAdaptiveSheet<Volunteer>(
      context,
      builder: (_) => VolunteerFormSheet(initial: _vm.volunteer),
    );
    if (updated == null || !mounted) return;
    _vm.save(updated);
    showMessage(context, 'Dados de ${updated.name} atualizados',
        icon: Icons.check_circle_outline);
  }

  Future<void> _changeStatus() async {
    final v = _vm.volunteer!;
    final ok = await showConfirmDialog(
      context,
      title: _vm.isActive ? 'Colocar de licença?' : 'Reativar voluntária?',
      message: _vm.isActive
          ? '${v.name} deixará de aparecer nas buscas de disponibilidade.'
          : '${v.name} voltará a aparecer nas buscas de disponibilidade.',
      confirmLabel: _vm.isActive ? 'Colocar de licença' : 'Reativar',
    );
    if (ok) _vm.toggleStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final v = _vm.volunteer;
        if (v == null) {
          return const Scaffold(
            body: EmptyState(icon: Icons.person_off, title: 'Voluntário não encontrado'),
          );
        }
        final age = Fmt.age(v.birthDate);
        return AppNestedScaffold(
          title: v.name,
          subtitle: '$age · voluntária desde ${v.since == null ? '—' : Fmt.monthYear(v.since!).toLowerCase()}',
          headerHeight: 140,
          headerContent: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  Fmt.initials(v.name),
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              StatusBadge(
                label: v.status.label,
                color: Colors.white,
                icon: _vm.isActive ? Icons.check_circle : Icons.pause_circle,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          slivers: [
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, c) {
                  final left = _left(context);
                  final right = _right(context);
                  if (c.maxWidth >= 840) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 28),
                        Expanded(child: right),
                      ],
                    );
                  }
                  return Column(children: [left, right]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _left(BuildContext context) {
    final v = _vm.volunteer!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                onPressed: () => showMessage(
                  context,
                  'Abrindo WhatsApp ${v.whatsapp}',
                  icon: Icons.chat,
                ),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('WhatsApp'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showMessage(context, 'Ligando para ${v.whatsapp}',
                    icon: Icons.call),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Ligar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _changeStatus,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Alterar status'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _vm.isActive
              ? 'Ativa: aparece nas buscas de disponibilidade.'
              : 'De licença: não aparece nas buscas de disponibilidade.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SectionTitle('Contato'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(v.whatsapp),
                subtitle: const Text('WhatsApp'),
              ),
              if (v.instagram != null)
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text(v.instagram!),
                  subtitle: const Text('Instagram'),
                ),
            ],
          ),
        ),
        const SectionTitle('Áreas de interesse'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in v.skills)
              Chip(avatar: Icon(s.icon, size: 18), label: Text(s.label)),
          ],
        ),
      ],
    );
  }

  Widget _right(BuildContext context) {
    final v = _vm.volunteer!;
    final pet = _vm.fosteredAnimal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Dias livres'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AvailabilityGrid(availability: v.availability),
          ),
        ),
        if (v.unavailableDates.isNotEmpty) ...[
          const SectionTitle('Indisponível nas datas'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in v.unavailableDates)
                StatusBadge(
                  icon: Icons.event_busy,
                  label: Fmt.date(d),
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
        const SectionTitle('Trabalhos anteriores'),
        if (v.activities.isEmpty)
          const Text('Nenhuma atividade registrada ainda.')
        else
          for (final a in v.activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NavCard(
                icon: a.skill.icon,
                title: a.title,
                subtitle: '${Fmt.date(a.date)}${a.detail != null ? ' · ${a.detail}' : ''}',
                onTap: () => showAdaptiveSheet<void>(
                  context,
                  builder: (_) => DetailSheet(
                    title: a.title,
                    subtitle: 'Atividade de ${v.name}',
                    icon: a.skill.icon,
                    color: AppColors.info,
                    rows: [
                      DetailRow(Icons.event_outlined, 'Data', Fmt.date(a.date)),
                      DetailRow(a.skill.icon, 'Tipo de ajuda', a.skill.label),
                      if (a.detail != null)
                        DetailRow(Icons.pets_outlined, 'Animal', a.detail!),
                    ],
                  ),
                ),
              ),
            ),
        if (pet != null) ...[
          const SectionTitle('Animal sob seus cuidados agora'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () => context.push(AppRoutes.petDetail(pet.id)),
              leading: SizedBox(
                width: 52,
                height: 52,
                child: NetworkPhoto(
                  url: pet.mainPhotoUrl,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${pet.breed} · lar temporário'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ],
    );
  }
}
