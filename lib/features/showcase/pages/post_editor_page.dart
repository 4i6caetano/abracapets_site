import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/blog_post.dart';
import '../viewmodels/post_editor_view_model.dart';


class PostEditorPage extends StatefulWidget {
  const PostEditorPage({super.key, this.postId});

  final String? postId;

  @override
  State<PostEditorPage> createState() => _PostEditorPageState();
}

class _PostEditorPageState extends State<PostEditorPage> {
  late final _vm = PostEditorViewModel(
    locator(),
    widget.postId,
    locator<AppViewModel>().user?.firstName ?? 'Equipe',
  );
  final _formKey = GlobalKey<FormState>();

  Future<void> _save({required bool publish}) async {
    FocusScope.of(context).unfocus();
    
    if (publish) {
      if (!_formKey.currentState!.validate()) return;
    } else if (_vm.title.trim().length < 3) {
      showMessage(
        context,
        'Dê ao menos um título ao rascunho',
        icon: Icons.info_outline,
      );
      return;
    }
    await _vm.save(publish: publish);
    if (!mounted) return;
    showMessage(
      context,
      publish ? '${_vm.type.label} publicado no site!' : 'Rascunho salvo',
      icon: publish ? Icons.public : Icons.save_outlined,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => AppNestedScaffold(
        title: _vm.isNew ? 'Nova publicação' : 'Editar publicação',
        subtitle: 'Blog e comunicados do site',
        headerHeight: 76,
        maxContentWidth: 820,
        bottomBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _vm.isSaving
                            ? null
                            : () => _save(publish: false),
                        child: const Text('Salvar rascunho'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _vm.isSaving
                            ? null
                            : () => _save(publish: true),
                        icon: _vm.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.public),
                        label: Text(
                          _vm.wasPublished ? 'Atualizar' : 'Publicar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Tipo'),
                  SegmentedButton<PostType>(
                    segments: [
                      for (final t in PostType.values)
                        ButtonSegment(
                          value: t,
                          label: Text(t.label),
                          icon: Icon(t.icon),
                        ),
                    ],
                    selected: {_vm.type},
                    onSelectionChanged: (s) => _vm.setType(s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(switch (_vm.type) {
                    PostType.post =>
                      'Conteúdo educativo ou histórias para o blog.',
                    PostType.notice =>
                      'Avisos rápidos: feiras, campanhas, mutirões.',
                    PostType.message =>
                      'Mensagens de agradecimento e prestação de contas.',
                  }, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _vm.title,
                    onChanged: _vm.setTitle,
                    maxLength: PostEditorViewModelBase.titleMax,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: Validators.compose([
                      Validators.minLength(5, label: 'Título'),
                      Validators.maxLength(PostEditorViewModelBase.titleMax),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _vm.content,
                    onChanged: _vm.setContent,
                    minLines: 8,
                    maxLines: 16,
                    maxLength: PostEditorViewModelBase.contentMax,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Conteúdo',
                      alignLabelWithHint: true,
                      helperText:
                          '${_vm.wordCount} palavras · ~${_vm.readingMinutes} min de leitura',
                    ),
                    validator: Validators.minLength(20, label: 'Conteúdo'),
                  ),
                  if (_vm.type == PostType.notice)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.push_pin_outlined),
                      title: const Text('Fixar aviso no topo do site'),
                      value: _vm.pinned,
                      onChanged: _vm.setPinned,
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => showMessage(
                      context,
                      'Seleção de imagem de capa (simulação)',
                      icon: Icons.image_outlined,
                    ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Adicionar imagem de capa'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
