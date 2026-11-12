import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../data/models/animal.dart';
import '../viewmodels/pet_detail_view_model.dart';
import '../../finance/widgets/finance_detail_sheets.dart';
import '../../volunteers/viewmodels/volunteers_view_model.dart';
import '../../volunteers/widgets/request_detail_sheet.dart';
import '../widgets/medical_record_sheet.dart';

class PetDetailPage extends StatefulWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  late final _vm = PetDetailViewModel(
    widget.petId,
    locator(),
    locator(),
    locator(),
  );
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final pet = _vm.pet;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            body: const EmptyState(
              icon: Icons.search_off,
              title: 'Animal não encontrado',
            ),
          );
        }
        return AppNestedScaffold(
          title: pet.name,
          showExpandedTitle: false,
          headerHeight: 250,
          background: _PhotoCarousel(
            pet: pet,
            controller: _pageController,
            onChanged: _vm.setPhotoIndex,
          ),
          headerContent: _CarouselDots(
            count: pet.allPhotos.length,
            index: _vm.photoIndex,
          ),
          actions: [
            IconButton(
              tooltip: 'Compartilhar ficha',
              onPressed: () => showMessage(
                context,
                'Link da vitrine copiado (simulação)',
                icon: Icons.link,
              ),
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => context.push(AppRoutes.petEdit(pet.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          slivers: [
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final info = _InfoColumn(pet: pet, vm: _vm);
                  final actions = _ActionsColumn(pet: pet, vm: _vm);
                  if (constraints.maxWidth >= 840) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: info),
                        const SizedBox(width: 32),
                        Expanded(flex: 2, child: actions),
                      ],
                    );
                  }
                  return Column(children: [info, actions]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({
    required this.pet,
    required this.controller,
    required this.onChanged,
  });

  final Animal pet;
  final PageController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final photos = pet.allPhotos;
    return PageView.builder(
      controller: controller,
      onPageChanged: onChanged,
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final photo = NetworkPhoto(
          url: photos[i],
          fallbackIcon: pet.species.icon,
        );
        return i == 0 ? Hero(tag: 'pet-photo-${pet.id}', child: photo) : photo;
      },
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == index ? 1 : 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({required this.pet, required this.vm});

  final Animal pet;
  final PetDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final daysInNgo = DateTime.now().difference(pet.rescueDate).inDays;

    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  pet.name,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusBadge(label: pet.status.label, color: pet.status.color),
            ],
          ),
          Text(
            '${pet.species.label} · ${pet.sex.label} · ${Fmt.age(pet.birthDate)} · '
            'resgatado em ${Fmt.date(pet.rescueDate)}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HealthChip(
                ok: pet.castrated,
                okLabel: 'Castrado',
                noLabel: 'Não castrado',
                icon: Icons.content_cut,
              ),
              _HealthChip(
                ok: pet.vaccinated,
                okLabel: 'Vacinado',
                noLabel: 'Não vacinado',
                icon: Icons.vaccines_outlined,
              ),
              if (pet.showOnShowcase)
                const StatusBadge(
                  icon: Icons.public,
                  label: 'Na vitrine do site',
                  color: AppColors.info,
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              InfoTile(
                icon: Icons.cake_outlined,
                label: 'Nascimento (estimado)',
                value: Fmt.date(pet.birthDate),
              ),
              InfoTile(
                icon: pet.species.icon,
                label: 'Raça',
                value: pet.breed,
                color: AppColors.accent,
              ),
              InfoTile(
                icon: Icons.calendar_month_outlined,
                label: 'Na ONG há',
                value: '$daysInNgo dias',
                color: AppColors.info,
              ),
              InfoTile(
                icon: Icons.photo_library_outlined,
                label: 'Mídia',
                value:
                    '${pet.allPhotos.length} fotos · ${pet.videoUrls.length} vídeos',
                color: const Color(0xFF16A394),
              ),
            ],
          ),
          const SectionTitle('Descrição'),
          Text(pet.description, style: textTheme.bodyLarge),
          const SectionTitle('História do resgate'),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: vm.storyExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              pet.rescueStory,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge,
            ),
            secondChild: Text(pet.rescueStory, style: textTheme.bodyLarge),
          ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: vm.toggleStory,
            child: Text(vm.storyExpanded ? 'Ler menos' : 'Ler mais'),
          ),
        ],
      ),
    );
  }
}

class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({required this.pet, required this.vm});

  final Animal pet;
  final PetDetailViewModel vm;

  Future<void> _changeStatus(BuildContext context) async {
    final status = await showAdaptiveSheet<AnimalStatus>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Alterar status'),
          for (final s in AnimalStatus.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: CircleAvatar(radius: 8, backgroundColor: s.color),
              title: Text(s.label),
              trailing: s == pet.status ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, s),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
    if (status == null || status == pet.status || !context.mounted) return;
    if (status == AnimalStatus.adopted) {
      final ok = await showConfirmDialog(
        context,
        title: 'Marcar como adotado?',
        message: 'Lembre-se de anexar o termo de adoção assinado na ficha do adotante.',
        confirmLabel: 'Marcar adotado',
      );
      if (!ok) return;
    }
    vm.changeStatus(status);
    if (context.mounted) {
      showMessage(
        context,
        'Status alterado para "${status.label}"',
        icon: Icons.check_circle_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Acompanhamento'),
          NavCard(
            icon: Icons.medical_information_outlined,
            title: 'Prontuário médico digital',
            subtitle: '${vm.records.length} registros',
            color: AppColors.danger,
            onTap: () => showAdaptiveSheet<void>(
              context,
              builder: (_) => MedicalRecordSheet(vm: vm),
            ),
          ),
          const SizedBox(height: 10),
          NavCard(
            icon: Icons.receipt_long_outlined,
            title: 'Despesas vinculadas',
            subtitle: '${Fmt.currency(vm.expensesTotal)} até hoje',
            color: AppColors.accent,
            onTap: () => showAdaptiveSheet<void>(
              context,
              builder: (_) => _ExpensesSheet(vm: vm),
            ),
          ),
          const SizedBox(height: 10),
          NavCard(
            icon: Icons.home_outlined,
            title: 'Histórico de lares',
            subtitle:
                '${vm.homeHistory.length} passagens · '
                '${vm.adoptions.length} adoções',
            color: const Color(0xFF16A394),
            onTap: () => showAdaptiveSheet<void>(
              context,
              builder: (_) => _HomesSheet(vm: vm),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () => context.push(AppRoutes.petEdit(pet.id)),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar ficha'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _changeStatus(context),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Alterar status'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showAdaptiveSheet<void>(
                    context,
                    builder: (_) => _InterestedSheet(vm: vm),
                  ),
                  icon: const Icon(Icons.favorite_outline),
                  label: Text('Interessados (${vm.interested.length})'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (pet.updatedAt != null)
            Text(
              'Atualizado ${Fmt.relative(pet.updatedAt!)}'
              '${pet.updatedBy != null ? ' por ${pet.updatedBy}' : ''}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _ExpensesSheet extends StatelessWidget {
  const _ExpensesSheet({required this.vm});

  final PetDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: 'Despesas vinculadas',
          subtitle: 'Total: ${Fmt.currency(vm.expensesTotal)}',
        ),
        Flexible(
          child: vm.expenses.isEmpty
              ? const EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'Nenhuma despesa vinculada a este pet',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: vm.expenses.length,
                  itemBuilder: (context, i) {
                    final e = vm.expenses[i];
                    return ListTile(
                      onTap: () => showExpenseDetails(context, e),
                      leading: CircleAvatar(
                        backgroundColor: e.category.color.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(e.category.icon, color: e.category.color),
                      ),
                      title: Text(e.description),
                      subtitle: Text(
                        '${Fmt.date(e.date)} · ${e.paymentMethod.label}'
                        '${e.hasInvoice ? '' : ' · sem nota'}',
                      ),
                      trailing: Text(
                        Fmt.currency(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HomesSheet extends StatelessWidget {
  const _HomesSheet({required this.vm});

  final PetDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = vm.homeHistory;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(title: 'Histórico de lares'),
        Flexible(
          child: history.isEmpty
              ? const EmptyState(
                  icon: Icons.home_outlined,
                  title: 'Ainda não passou por nenhum lar',
                  message: 'O animal está no abrigo da ONG.',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: history.length,
                  itemBuilder: (context, i) {
                    final h = history[i];
                    final current = h.stay.end == null;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(top: 18),
                                decoration: BoxDecoration(
                                  color: current
                                      ? scheme.primary
                                      : scheme.outlineVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (i < history.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: scheme.outlineVariant,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                h.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${h.home?.isTemporary ?? true ? 'Lar temporário' : 'Lar definitivo'} · '
                                '${Fmt.date(h.stay.start)} – '
                                '${h.stay.end == null ? 'atual' : Fmt.date(h.stay.end!)}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: h.home == null
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      context.push(AppRoutes.home(h.home!.id));
                                    },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _InterestedSheet extends StatelessWidget {
  const _InterestedSheet({required this.vm});

  final PetDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final items = vm.interested;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          title: 'Interessados',
          subtitle: 'Solicitações de adoção pendentes',
        ),
        Flexible(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Nenhum interessado ainda',
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final r = items[i];
                    return ListTile(
                      onTap: () {
                        final requests = VolunteersViewModel(locator());
                        showRequestDetails(
                          context,
                          r,
                          onApprove: () => requests.approve(r),
                          onReject: () => requests.reject(r),
                        );
                      },
                      leading: InitialsAvatar(name: r.name),
                      title: Text(r.name),
                      subtitle: Text(r.summary),
                      trailing: Text(
                        '${(r.screeningScore * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: r.screeningScore >= 0.7
                              ? AppColors.success
                              : r.screeningScore >= 0.4
                              ? AppColors.warning
                              : AppColors.danger,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}


class _HealthChip extends StatelessWidget {
  const _HealthChip({
    required this.ok,
    required this.okLabel,
    required this.noLabel,
    required this.icon,
  });

  final bool ok;
  final String okLabel;
  final String noLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) => StatusBadge(
    icon: ok ? Icons.check_circle : icon,
    label: ok ? okLabel : noLabel,
    color: ok ? AppColors.success : Theme.of(context).colorScheme.outline,
  );
}
