import 'package:mobx/mobx.dart';

import '../../../data/models/animal.dart';
import '../../../data/models/blog_post.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/blog_repository.dart';

part 'showcase_view_model.g.dart';

enum ShowcaseFilter { all, dogs, cats, visible, hidden }

class ShowcaseViewModel = ShowcaseViewModelBase with _$ShowcaseViewModel;

abstract class ShowcaseViewModelBase with Store {
  ShowcaseViewModelBase(this._animals, this._blog);

  final AnimalRepository _animals;
  final BlogRepository _blog;

  @observable
  ShowcaseFilter filter = ShowcaseFilter.all;

  
  @observable
  PostType? postType;

  @computed
  List<Animal> get animals => _animals.animals.where((a) {
    return switch (filter) {
      ShowcaseFilter.all => true,
      ShowcaseFilter.dogs => a.species == Species.dog,
      ShowcaseFilter.cats => a.species == Species.cat,
      ShowcaseFilter.visible => a.showOnShowcase,
      ShowcaseFilter.hidden => !a.showOnShowcase,
    };
  }).toList();

  @computed
  int get visibleCount =>
      _animals.animals.where((a) => a.showOnShowcase).length;

  @computed
  List<BlogPost> get posts =>
      _blog.posts.where((p) => postType == null || p.type == postType).toList()
        ..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.date.compareTo(a.date);
        });

  @computed
  int get publishedCount => _blog.posts.where((p) => p.published).length;

  @computed
  int get draftCount => _blog.posts.where((p) => !p.published).length;

  @action
  void setFilter(ShowcaseFilter v) => filter = v;

  @action
  void setPostType(PostType? v) => postType = v;

  @action
  void toggleShowcase(Animal a, bool value) =>
      _animals.update(a.copyWith(showOnShowcase: value));

  @action
  void togglePublished(BlogPost p) =>
      _blog.save(p.copyWith(published: !p.published));

  @action
  void deletePost(BlogPost p) => _blog.remove(p.id);

  @action
  void restorePost(BlogPost p) => _blog.save(p);
}
