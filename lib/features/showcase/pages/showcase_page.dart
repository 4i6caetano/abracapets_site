import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../data/models/animal.dart';
import '../../../data/models/blog_post.dart';
import '../viewmodels/showcase_view_model.dart';


class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  final _vm = ShowcaseViewModel(locator(), locator());

  void _delete(BlogPost post) {
    _vm.deletePost(post);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${post.title}" excluído'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => _vm.restorePost(post),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Observer(
        builder: (_) => AppNestedScaffold(
          title: 'Vitrine & Blog',
          subtitle:
              '${_vm.visibleCount} animais no site · '
              '${_vm.publishedCount} posts publicados',
          headerHeight: 76,
          bottomHeight: AppTabBar.height,
          bottom: const AppTabBar(
            tabs: [
              Tab(text: 'Vitrine do site'),
              Tab(text: 'Blog'),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.postNew),
            icon: const Icon(Icons.edit_note),
            label: const Text('Nova publicação'),
          ),
          tabViews: [_showcaseTab(), _blogTab()],
        ),
      ),
    );
  }

  List<Widget> _showcaseTab() => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text(
          'Ligue para publicar no cardápio público de adoção.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
    SliverToBoxAdapter(
      child: Observer(
        builder: (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ChipStrip(
            children: [
              for (final (f, label) in const [
                (ShowcaseFilter.all, 'Todos'),
                (ShowcaseFilter.dogs, 'Cães'),
                (ShowcaseFilter.cats, 'Gatos'),
                (ShowcaseFilter.visible, 'No site'),
                (ShowcaseFilter.hidden, 'Ocultos'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _vm.filter == f,
                  onSelected: (_) => _vm.setFilter(f),
                ),
            ],
          ),
        ),
      ),
    ),
    Observer(
      builder: (_) => SliverAdaptiveGrid(
        maxItemWidth: 420,
        spacing: 10,
        children: [
          for (final a in _vm.animals)
            _ShowcaseTile(
              animal: a,
              onChanged: (v) => _vm.toggleShowcase(a, v),
            ),
        ],
      ),
    ),
  ];

  List<Widget> _blogTab() => [
    SliverToBoxAdapter(
      child: Observer(
        builder: (_) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: ChipStrip(
            children: [
              ChoiceChip(
                label: const Text('Tudo'),
                selected: _vm.postType == null,
                onSelected: (_) => _vm.setPostType(null),
              ),
              for (final t in PostType.values)
                ChoiceChip(
                  avatar: Icon(t.icon, size: 16),
                  label: Text('${t.label}s'),
                  selected: _vm.postType == t,
                  onSelected: (_) => _vm.setPostType(t),
                ),
            ],
          ),
        ),
      ),
    ),
    Observer(
      builder: (_) => _vm.posts.isEmpty
          ? const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.article_outlined,
                title: 'Nada publicado por aqui',
              ),
            )
          : SliverList.builder(
              itemCount: _vm.posts.length,
              itemBuilder: (context, i) {
                final p = _vm.posts[i];
                
                
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PostCard(
                        post: p,
                        onEdit: () => context.push(AppRoutes.postEdit(p.id)),
                        onTogglePublish: () => _vm.togglePublished(p),
                        onDelete: () => _delete(p),
                      ),
                    ),
                  ),
                );
              },
            ),
    ),
  ];
}

class _ShowcaseTile extends StatelessWidget {
  const _ShowcaseTile({required this.animal, required this.onChanged});

  final Animal animal;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final adopted = animal.status == AnimalStatus.adopted;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.petDetail(animal.id)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: NetworkPhoto(
                  url: animal.mainPhotoUrl,
                  fallbackIcon: animal.species.icon,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      adopted && animal.showOnShowcase
                          ? 'Adotado · aparece em "Já adotados"'
                          : '${animal.status.label} · ${animal.species.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(value: animal.showOnShowcase, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}



class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onDelete,
  });

  final BlogPost post;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;
  bool _liked = false;

  Color get _typeColor => switch (widget.post.type) {
    PostType.post => AppColors.primary,
    PostType.notice => AppColors.accentDark,
    PostType.message => const Color(0xFF16A394),
  };

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              children: [
                InitialsAvatar(name: post.author, radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${post.type.label} · ${Fmt.relative(post.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: post.published ? 'Publicado' : 'Rascunho',
                  color: post.published ? AppColors.success : scheme.outline,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opções',
                  onSelected: (v) => switch (v) {
                    'edit' => widget.onEdit(),
                    'publish' => widget.onTogglePublish(),
                    _ => widget.onDelete(),
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'publish',
                      child: Text(post.published ? 'Despublicar' : 'Publicar'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          GestureDetector(
            onDoubleTap: () => setState(() => _liked = true),
            child: AspectRatio(
              aspectRatio: post.coverUrl != null ? 4 / 3 : 16 / 9,
              child: post.coverUrl != null
                  ? NetworkPhoto(url: post.coverUrl)
                  : ColoredBox(
                      color: _typeColor,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(post.type.icon, color: Colors.white, size: 36),
                            const SizedBox(height: 12),
                            Text(
                              post.title,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Curtir',
                  onPressed: () => setState(() => _liked = !_liked),
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? AppColors.danger : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Compartilhar',
                  onPressed: () => showMessage(
                    context,
                    'Link do post copiado (simulação)',
                    icon: Icons.link,
                  ),
                  icon: const Icon(Icons.send_outlined),
                ),
                const Spacer(),
                if (post.pinned)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: StatusBadge(
                      icon: Icons.push_pin,
                      label: 'Fixado',
                      color: AppColors.danger,
                    ),
                  ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (post.content.length > 90)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expanded ? 'ver menos' : 'ver mais',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
