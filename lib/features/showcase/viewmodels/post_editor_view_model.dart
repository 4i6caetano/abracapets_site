import 'package:mobx/mobx.dart';

import '../../../data/models/blog_post.dart';
import '../../../data/repositories/blog_repository.dart';

part 'post_editor_view_model.g.dart';

class PostEditorViewModel = PostEditorViewModelBase with _$PostEditorViewModel;

abstract class PostEditorViewModelBase with Store {
  PostEditorViewModelBase(this._repository, String? postId, this.author)
    : _original = postId == null ? null : _repository.byId(postId) {
    final p = _original;
    if (p != null) {
      type = p.type;
      title = p.title;
      content = p.content;
      pinned = p.pinned;
    }
  }

  static const titleMax = 80;
  static const contentMax = 2000;

  final BlogRepository _repository;
  final BlogPost? _original;
  final String author;

  bool get isNew => _original == null;
  bool get wasPublished => _original?.published ?? false;

  @observable
  PostType type = PostType.post;

  @observable
  String title = '';

  @observable
  String content = '';

  @observable
  bool pinned = false;

  @observable
  bool isSaving = false;

  @computed
  int get wordCount =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  @computed
  int get readingMinutes => (wordCount / 200).ceil().clamp(1, 60);

  @action
  void setType(PostType v) {
    type = v;
    if (v != PostType.notice) pinned = false;
  }

  @action
  void setTitle(String v) => title = v;

  @action
  void setContent(String v) => content = v;

  @action
  void setPinned(bool v) => pinned = v;

  @action
  Future<void> save({required bool publish}) async {
    isSaving = true;
    await _repository.save(
      BlogPost(
        id: _original?.id ?? 'b${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title.trim(),
        content: content.trim(),
        date: DateTime.now(),
        author: _original?.author ?? author,
        published: publish,
        pinned: pinned,
        coverUrl: _original?.coverUrl,
      ),
    );
    isSaving = false;
  }
}
