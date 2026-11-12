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
import '../viewmodels/home_profile_view_model.dart';
import '../widgets/adoption_detail_sheet.dart';


class HomeProfilePage extends StatefulWidget {
  const HomeProfilePage({super.key, required this.homeId});

  final String homeId;

  @override
  State<HomeProfilePage> createState() => _HomeProfilePageState();
}

class _HomeProfilePageState extends State<HomeProfilePage> {
  late final _vm = HomeProfileViewModel(widget.homeId, locator(), locator());

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final home = _vm.home;
        if (home == null) {
          return const Scaffold(
            body: EmptyState(icon: Icons.home_outlined, title: 'Lar não encontrado'),
          );
        }
        return AppNestedScaffold(
          title: _vm.title,
          subtitle: home.isTemporary
              ? 'Lar temporário · ${home.city}'
              : 'Lar definitivo · ${home.city}',
          headerHeight: 170,
          headerContent: Wrap(
            spacing: 8,
            children: [
              StatusBadge(
                label: home.isTemporary ? 'Lar temporário' : 'Lar definitivo',
                color: home.isTemporary ? AppColors.primary : AppColors.accentDark,
                solid: true,
              ),
              if (home.isTemporary)
                StatusBadge(
                  label: home.isFull
                      ? 'Lotado'
                      : '${home.freeVacancies} vagas livres',
                  color: home.isFull ? Colors.black54 : AppColors.success,
                  solid: true,
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Agendar vistoria',
              onPressed: () => showMessage(context, 'Vistoria agendada (simulação)',
                  icon: Icons.event_available),
              icon: const Icon(Icons.fact_check_outlined),
            ),
          ],
          slivers: [
            const SliverToBoxAdapter(child: SectionTitle('Vistoria do imóvel')),
            SliverGrid.count(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: [
                InfoTile(
                  icon: home.propertyType.icon,
                  label: 'Tipo de imóvel',
                  value: home.propertyType.label,
                ),
                InfoTile(
                  icon: Icons.square_foot,
                  label: 'Tamanho',
                  value: '${home.sizeM2} m²',
                  color: AppColors.info,
                ),
                InfoTile(
                  icon: home.hasProtectionNet
                      ? Icons.shield_outlined
                      : Icons.warning_amber,
                  label: 'Rede de proteção',
                  value: home.hasProtectionNet ? 'Sim' : 'Não',
                  color: home.hasProtectionNet
                      ? AppColors.success
                      : AppColors.warning,
                ),
                InfoTile(
                  icon: Icons.pets,
                  label: 'Pets da família',
                  value: '${home.familyPetsCount}',
                  color: AppColors.accent,
                ),
              ],
            ),
            if (home.notes != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(home.notes!),
                ),
              ),
            const SliverToBoxAdapter(child: SectionTitle('Endereço')),
            SliverToBoxAdapter(
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    _vm.addressVisible
                        ? home.address
                        : '•••••••••••• (confidencial)',
                  ),
                  subtitle: Text(home.city),
                  trailing: IconButton(
                    tooltip: _vm.addressVisible ? 'Ocultar' : 'Mostrar',
                    onPressed: _vm.toggleAddress,
                    icon: Icon(_vm.addressVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionTitle('Responsáveis pelo lar')),
            SliverAdaptiveGrid(
              spacing: 8,
              children: [
                for (final p in _vm.responsibles)
                  Card(
                    child: ListTile(
                      onTap: () => context.push(AppRoutes.person(p.id)),
                      leading: InitialsAvatar(name: p.fullName),
                      title: Text(p.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(p.phone),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: SectionTitle(
                home.isTemporary ? 'Animais acolhidos agora' : 'Animais da ONG neste lar',
              ),
            ),
            if (_vm.animals.isEmpty)
              const SliverToBoxAdapter(
                child: Text('Nenhum animal da ONG neste lar no momento.'),
              )
            else
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisExtent: 170,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _vm.animals.length,
                itemBuilder: (context, i) {
                  final a = _vm.animals[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(AppRoutes.petDetail(a.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: NetworkPhoto(
                              url: a.mainPhotoUrl,
                              fallbackIcon: a.species.icon,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(a.name,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_vm.adoptions.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('Adoções e termos')),
              SliverList.builder(
                itemCount: _vm.adoptions.length,
                itemBuilder: (context, i) {
                  final ad = _vm.adoptions[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NavCard(
                      icon: ad.wasReturned
                          ? Icons.assignment_return_outlined
                          : Icons.assignment_turned_in_outlined,
                      color: ad.wasReturned ? AppColors.danger : AppColors.success,
                      title: '${_vm.animalName(ad.animalId)} · ${Fmt.date(ad.date)}',
                      subtitle: ad.wasReturned
                          ? 'Devolvido em ${Fmt.date(ad.returnedAt!)}'
                          : 'Termo: ${ad.termFileName ?? 'pendente'}',
                      onTap: () => showAdoptionDetails(context, ad),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
