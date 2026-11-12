import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../viewmodels/login_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _vm = LoginViewModel(locator<AppViewModel>());
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _useAccount(String email) {
    _emailController.text = email;
    _vm.setEmail(email);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _vm.login();
    if (ok && mounted) context.go(AppRoutes.dashboard);
  }

  void _forgotPassword() {
    final emailOk = Validators.email(_vm.email) == null;
    showMessage(
      context,
      emailOk
          ? 'Enviamos um link de recuperação para ${_vm.email}'
          : 'Informe um e-mail válido para recuperar a senha',
      icon: emailOk ? Icons.mark_email_read_outlined : Icons.info_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isDesktop;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: isWide ? _buildWide(context) : _buildMobile(context),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                child: const _Brand(),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: _buildForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ColoredBox(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Brand(large: true),
                  const SizedBox(height: 40),
                  for (final (icon, text) in const [
                    (Icons.pets, 'Fichas, prontuários e vitrine dos animais'),
                    (Icons.account_balance_wallet_outlined,
                        'Doações e despesas com transparência'),
                    (Icons.groups_outlined, 'Voluntários, lares e adoções'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            child: Icon(icon, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: ColoredBox(
            color: scheme.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Observer(
        builder: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Acesso à equipe',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Entre com qualquer e-mail. No primeiro acesso, a senha '
              'escolhida fica vinculada a ele neste dispositivo.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (_vm.accounts.isNotEmpty) ...[
              Text('Contas neste dispositivo', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              ChipStrip(
                children: [
                  for (final a in _vm.accounts)
                    InputChip(
                      avatar: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Text(Fmt.initials(a.name)),
                      ),
                      label: Text(a.email),
                      selected: _vm.email.trim().toLowerCase() == a.email,
                      onPressed: () => _useAccount(a.email),
                      deleteButtonTooltipMessage: 'Esquecer conta',
                      onDeleted: () => _vm.forget(a.email),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _emailController,
              onChanged: _vm.setEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(Icons.alternate_email),
                helperText: _vm.isNewAccount
                    ? 'Nova sessão: esta conta será criada ao entrar'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: _vm.setPassword,
              obscureText: _vm.obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: Validators.password,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _vm.obscurePassword ? 'Mostrar' : 'Ocultar',
                  onPressed: _vm.toggleObscure,
                  icon: Icon(
                    _vm.obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _PasswordChecklist(rules: _vm.passwordRules),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('Esqueci minha senha'),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _vm.errorMessage == null
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: scheme.onErrorContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _vm.errorMessage!,
                              style:
                                  TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _vm.isLoading ? null : _submit,
              child: _vm.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(_vm.isNewAccount ? 'Criar sessão e entrar' : 'Entrar'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Acesso restrito à equipe da ONG',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          large ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: large ? 88 : 76,
          height: large ? 88 : 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.pets, size: 42, color: AppColors.primary),
        ),
        const SizedBox(height: 18),
        Text(
          'AbraçaPets',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: large ? 44 : null,
                letterSpacing: -1,
              ),
        ),
        Text(
          'Gestão interna de resgate',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: large ? 18 : 15,
          ),
        ),
      ],
    );
  }
}


class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.rules});

  final List<(String, bool)> rules;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final (label, ok) in rules)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: ok ? AppColors.success : scheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ok ? AppColors.success : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
