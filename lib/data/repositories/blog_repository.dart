import 'package:mobx/mobx.dart';

import '../mock/mock_data.dart';
import '../models/blog_post.dart';

class BlogRepository {
  final posts = ObservableList<BlogPost>.of(MockData.posts);

  BlogPost? byId(String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> save(BlogPost post) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    runInAction(() {
      final i = posts.indexWhere((p) => p.id == post.id);
      if (i >= 0) {
        posts[i] = post;
      } else {
        posts.insert(0, post);
      }
    });
  }

  void remove(String id) =>
      runInAction(() => posts.removeWhere((p) => p.id == id));
}
