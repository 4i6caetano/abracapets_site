import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_masks.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../viewmodels/user_profile_view_model.dart';


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final _vm = UserProfileViewModel(locator<AppViewModel>());

  Future<void> _edit() async {
    final saved = await showAdaptiveSheet<bool>(
      context,
      builder: (_) => _EditProfileSheet(vm: _vm),
    );
    if (saved == true && mounted) {
      showMessage(context, 'Perfil atualizado', icon: Icons.check_circle_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final user = _vm.user;
        return AppNestedScaffold(
          title: user?.name ?? 'Perfil',
          subtitle: '${user?.role ?? ''} · sessão iniciada em '
              '${user?.since == null ? '—' : Fmt.date(user!.since!)}',
          headerHeight: 130,
          maxContentWidth: 820,
          headerContent: CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              Fmt.initials(user?.name ?? '?'),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Editar perfil',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          slivers: [
            const SliverToBoxAdapter(child: SectionTitle('Dados pessoais')),
            SliverToBoxAdapter(
              child: Card(
                child: Column(
                  children: [
                    _info(Icons.person_outline, 'Nome', user?.name ?? '—'),
                    _info(Icons.alternate_email, 'E-mail (login)', user?.email ?? '—'),
                    _info(
                      Icons.phone_outlined,
                      'Telefone / WhatsApp',
                      (user?.phone.isEmpty ?? true) ? 'Não informado' : user!.phone,
                    ),
                    _info(Icons.admin_panel_settings_outlined, 'Perfil de acesso',
                        user?.role ?? '—'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar perfil'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionTitle('Segurança')),
            SliverToBoxAdapter(
              child: NavCard(
                icon: Icons.lock_reset,
                title: 'Alterar senha',
                subtitle: '8+ caracteres, maiúscula, minúscula e número',
                onTap: () => showAdaptiveSheet<void>(
                  context,
                  builder: (_) => _ChangePasswordSheet(vm: _vm),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SectionTitle('Sessões neste dispositivo'),
            ),
            SliverToBoxAdapter(
              child: Card(
                child: Column(
                  children: [
                    for (final a in _vm.accounts)
                      ListTile(
                        leading: InitialsAvatar(name: a.name),
                        title: Text(a.name,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(a.email),
                        trailing: a.email == user?.email
                            ? const StatusBadge(
                                label: 'Ativa', color: AppColors.success)
                            : IconButton(
                                tooltip: 'Esquecer conta',
                                onPressed: () async {
                                  final ok = await showConfirmDialog(
                                    context,
                                    title: 'Esquecer conta?',
                                    message:
                                        '${a.email} será removida deste dispositivo.',
                                    confirmLabel: 'Esquecer',
                                    destructive: true,
                                  );
                                  if (ok) await _vm.forget(a.email);
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _info(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon),
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(label),
      );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.vm});

  final UserProfileViewModel vm;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vm.user?.name);
  late final _phone = TextEditingController(text: widget.vm.user?.phone);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.vm.save(name: _name.text, phone: _phone.text);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(title: 'Editar perfil'),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validators.minLength(3, label: 'Nome'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [MaskInputFormatter.phone()],
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: widget.vm.user?.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail (identifica a sessão)',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: FilledButton(
              onPressed: widget.vm.isSaving ? null : _save,
              child: widget.vm.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.vm});

  final UserProfileViewModel vm;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _serverError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await widget.vm.changePassword(_current.text, _next.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _serverError = error;
    });
    if (error == null) {
      Navigator.pop(context);
      showMessage(context, 'Senha alterada com sucesso', icon: Icons.lock);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(title: 'Alterar senha'),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _current,
                    obscureText: _obscure,
                    decoration:
                        deco('Senha atual').copyWith(errorText: _serverError),
                    validator: Validators.required('Informe a senha atual'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _next,
                    obscureText: _obscure,
                    decoration: deco('Nova senha').copyWith(
                      helperText: '8+ caracteres, maiúscula, minúscula e número',
                    ),
                    validator: (v) {
                      final base = Validators.password(v);
                      if (base != null) return base;
                      return v == _current.text
                          ? 'A nova senha deve ser diferente da atual'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: deco('Confirmar nova senha'),
                    validator: (v) =>
                        v != _next.text ? 'As senhas não conferem' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Alterar senha'),
          ),
        ),
      ],
    );
  }
}
