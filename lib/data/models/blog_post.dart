import 'package:flutter/material.dart';

enum PostType {
  post('Post', Icons.article_outlined),
  notice('Aviso', Icons.campaign_outlined),
  message('Mensagem', Icons.chat_bubble_outline);

  const PostType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class BlogPost {
  const BlogPost({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    this.published = false,
    this.pinned = false,
    this.coverUrl,
  });

  final String id;
  final PostType type;
  final String title;
  final String content;
  final DateTime date;
  final String author;
  final bool published;
  final bool pinned;
  final String? coverUrl;

  BlogPost copyWith({
    PostType? type,
    String? title,
    String? content,
    DateTime? date,
    bool? published,
    bool? pinned,
  }) =>
      BlogPost(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        content: content ?? this.content,
        date: date ?? this.date,
        author: author,
        published: published ?? this.published,
        pinned: pinned ?? this.pinned,
        coverUrl: coverUrl,
      );
}
