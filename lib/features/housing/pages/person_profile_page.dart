import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../viewmodels/person_profile_view_model.dart';
import '../widgets/adoption_detail_sheet.dart';
import '../widgets/restriction_form_sheet.dart';


class PersonProfilePage extends StatefulWidget {
  const PersonProfilePage({super.key, required this.personId});

  final String personId;

  @override
  State<PersonProfilePage> createState() => _PersonProfilePageState();
}

class _PersonProfilePageState extends State<PersonProfilePage> {
  late final _vm = PersonProfileViewModel(widget.personId, locator(), locator());

  Future<void> _restrict() async {
    final p = _vm.person!;
    final data = await showAdaptiveSheet<RestrictionData>(
      context,
      builder: (_) =>
          RestrictionFormSheet(initialName: p.fullName, initialCpf: p.cpf),
    );
    if (data == null || !mounted) return;
    _vm.restrict(data.reason, locator<AppViewModel>().user?.firstName ?? 'Equipe');
    showMessage(context, 'Pessoa incluída na lista restrita', icon: Icons.block);
  }

  Future<void> _unrestrict() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remover da lista restrita?',
      message: 'A pessoa voltará a poder solicitar adoções normalmente.',
      confirmLabel: 'Remover',
    );
    if (ok) _vm.removeRestriction();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final p = _vm.person;
        if (p == null) {
          return const Scaffold(
            body: EmptyState(icon: Icons.person_off, title: 'Pessoa não encontrada'),
          );
        }
        final visible = _vm.sensitiveVisible;
        return AppNestedScaffold(
          title: p.fullName,
          subtitle: '${Fmt.age(p.birthDate)} · ${_vm.adoptions.length} adoções registradas',
          headerHeight: 130,
          headerContent: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(
                  Fmt.initials(p.fullName),
                  style: TextStyle(
                    color: p.isRestricted ? AppColors.danger : AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (p.isRestricted)
                const StatusBadge(
                  label: 'LISTA RESTRITA',
                  color: Colors.white,
                  icon: Icons.block,
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: visible ? 'Ocultar dados sensíveis' : 'Mostrar dados sensíveis',
              onPressed: _vm.toggleSensitive,
              icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
          ],
          slivers: [
            if (p.isRestricted)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                          SizedBox(width: 8),
                          Text(
                            'Não doar animais para esta pessoa',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Motivo: ${p.restriction!.reason}'),
                      Text(
                        'Incluída em ${Fmt.date(p.restriction!.date)} por ${p.restriction!.addedBy}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SectionTitle('Dados de contato')),
            SliverToBoxAdapter(
              child: Card(
                child: Column(
                  children: [
                    _row(Icons.badge_outlined, 'CPF',
                        visible ? p.cpf : Fmt.maskCpf(p.cpf)),
                    _row(Icons.cake_outlined, 'Nascimento', Fmt.date(p.birthDate)),
                    _row(Icons.phone_outlined, 'Telefone / WhatsApp',
                        visible ? p.phone : '(••) •••••-${p.phone.length > 4 ? p.phone.substring(p.phone.length - 4) : ''}'),
                    _row(Icons.email_outlined, 'E-mail', p.email),
                    _row(Icons.home_outlined, 'Endereço',
                        visible ? p.address : '•••••••• (confidencial)'),
                    if (p.instagram != null)
                      _row(Icons.camera_alt_outlined, 'Instagram', p.instagram!),
                    _row(
                      p.hasDocumentPhoto
                          ? Icons.verified_user_outlined
                          : Icons.gpp_maybe_outlined,
                      'Documento (RG/CNH)',
                      p.hasDocumentPhoto ? 'Foto arquivada' : 'Não enviado',
                    ),
                  ],
                ),
              ),
            ),
            if (_vm.homes.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('Responsável pelos lares')),
              SliverList.builder(
                itemCount: _vm.homes.length,
                itemBuilder: (context, i) {
                  final h = _vm.homes[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NavCard(
                      icon: h.propertyType.icon,
                      title: '${h.propertyType.label} · ${h.city}',
                      subtitle: h.isTemporary ? 'Lar temporário' : 'Lar definitivo',
                      onTap: () => context.push(AppRoutes.home(h.id)),
                    ),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SectionTitle('Histórico de adoções')),
            if (_vm.adoptions.isEmpty)
              const SliverToBoxAdapter(child: Text('Nenhuma adoção registrada.'))
            else
              SliverList.builder(
                itemCount: _vm.adoptions.length,
                itemBuilder: (context, i) {
                  final ad = _vm.adoptions[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NavCard(
                      icon: ad.wasReturned
                          ? Icons.assignment_return_outlined
                          : Icons.favorite_outline,
                      color: ad.wasReturned ? AppColors.danger : AppColors.success,
                      title: _vm.animalName(ad.animalId),
                      subtitle: ad.wasReturned
                          ? 'Devolvido em ${Fmt.date(ad.returnedAt!)} · ${ad.returnReason ?? ''}'
                          : 'Adotado em ${Fmt.date(ad.date)}'
                              '${ad.secondaryResponsibleName != null ? ' · 2º resp.: ${ad.secondaryResponsibleName}' : ''}',
                      onTap: () => showAdoptionDetails(context, ad),
                    ),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: p.isRestricted
                    ? OutlinedButton.icon(
                        onPressed: _unrestrict,
                        icon: const Icon(Icons.lock_open),
                        label: const Text('Remover da lista restrita'),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                        onPressed: _restrict,
                        icon: const Icon(Icons.block),
                        label: const Text('Incluir na lista restrita'),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(label),
        dense: true,
      );
}
