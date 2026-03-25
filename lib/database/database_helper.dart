// lib/database/database_helper.dart
//
// Storage layer using SharedPreferences + JSON.
// Works on Android, iOS, Web, Desktop — no native SQLite needed.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

/// Custom exception for storage-related errors
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;
  DatabaseException(this.message, [this.originalError]);
  @override
  String toString() => 'DatabaseException: $message';
}

/// Singleton storage helper — mimics a full CRUD database using
/// SharedPreferences as the persistence engine.
///
/// Data layout in SharedPreferences:
///   "posts_ids"      → JSON list of all post IDs  e.g. [1, 2, 3]
///   "post_1"         → JSON string of Post with id=1
///   "posts_counter"  → int, auto-increment counter
class DatabaseHelper {
  static DatabaseHelper? _instance;
  SharedPreferences? _prefs;

  static const _idsKey = 'posts_ids';
  static const _counterKey = 'posts_counter';

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── helpers ────────────────────────────────────────────────────

  Future<List<int>> _getIds() async {
    final prefs = await _storage;
    final raw = prefs.getString(_idsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (raw.split(','))
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList();
    return list;
  }

  Future<void> _saveIds(List<int> ids) async {
    final prefs = await _storage;
    await prefs.setString(_idsKey, ids.join(','));
  }

  Future<int> _nextId() async {
    final prefs = await _storage;
    final current = prefs.getInt(_counterKey) ?? 0;
    final next = current + 1;
    await prefs.setInt(_counterKey, next);
    return next;
  }

  // ── CREATE ─────────────────────────────────────────────────────

  Future<int> insertPost(Post post) async {
    try {
      final prefs = await _storage;
      final id = await _nextId();
      final withId = post.copyWith(id: id);
      await prefs.setString('post_$id', withId.toJson());
      final ids = await _getIds();
      ids.add(id);
      await _saveIds(ids);
      return id;
    } catch (e) {
      throw DatabaseException('Failed to insert post: $e', e);
    }
  }

  // ── READ ───────────────────────────────────────────────────────

  Future<List<Post>> getAllPosts() async {
    try {
      final prefs = await _storage;
      final ids = await _getIds();
      final posts = <Post>[];
      for (final id in ids) {
        final raw = prefs.getString('post_$id');
        if (raw != null) posts.add(Post.fromJson(raw));
      }
      // Sort newest first
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      throw DatabaseException('Failed to retrieve posts: $e', e);
    }
  }

  Future<Post?> getPostById(int id) async {
    try {
      final prefs = await _storage;
      final raw = prefs.getString('post_$id');
      if (raw == null) return null;
      return Post.fromJson(raw);
    } catch (e) {
      throw DatabaseException('Failed to retrieve post #$id: $e', e);
    }
  }

  Future<List<Post>> searchPosts(String query) async {
    final all = await getAllPosts();
    final q = query.toLowerCase();
    return all.where((p) =>
        p.title.toLowerCase().contains(q) ||
        p.body.toLowerCase().contains(q) ||
        p.author.toLowerCase().contains(q)).toList();
  }

  // ── UPDATE ─────────────────────────────────────────────────────

  Future<int> updatePost(Post post) async {
    if (post.id == null) {
      throw DatabaseException('Cannot update a post without an ID');
    }
    try {
      final prefs = await _storage;
      final existing = prefs.getString('post_${post.id}');
      if (existing == null) {
        throw DatabaseException('Post #${post.id} not found for update');
      }
      await prefs.setString('post_${post.id}', post.toJson());
      return 1;
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to update post: $e', e);
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────

  Future<int> deletePost(int id) async {
    try {
      final prefs = await _storage;
      final existing = prefs.getString('post_$id');
      if (existing == null) {
        throw DatabaseException('Post #$id not found for deletion');
      }
      await prefs.remove('post_$id');
      final ids = await _getIds();
      ids.remove(id);
      await _saveIds(ids);
      return 1;
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Failed to delete post: $e', e);
    }
  }

  Future<void> deleteAllPosts() async {
    try {
      final prefs = await _storage;
      final ids = await _getIds();
      for (final id in ids) {
        await prefs.remove('post_$id');
      }
      await prefs.remove(_idsKey);
      await prefs.remove(_counterKey);
    } catch (e) {
      throw DatabaseException('Failed to delete all posts: $e', e);
    }
  }

  Future<int> getPostCount() async {
    final ids = await _getIds();
    return ids.length;
  }
}