// lib/models/post.dart
import 'dart:convert';

class Post {
  final int? id;
  final String title;
  final String body;
  final String author;
  final String createdAt;
  final String updatedAt;

  Post({
    this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'author': author,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Post.fromMap(Map<String, dynamic> map) => Post(
        id: map['id'] as int?,
        title: map['title'] as String,
        body: map['body'] as String,
        author: map['author'] as String,
        createdAt: map['created_at'] as String,
        updatedAt: map['updated_at'] as String,
      );

  String toJson() => jsonEncode(toMap());

  factory Post.fromJson(String source) =>
      Post.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Post copyWith({
    int? id,
    String? title,
    String? body,
    String? author,
    String? createdAt,
    String? updatedAt,
  }) =>
      Post(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        author: author ?? this.author,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}