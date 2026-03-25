// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Post? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _db.getPostById(widget.postId);
      if (p == null) {
        setState(() { _error = 'Post not found.'; _loading = false; });
        return;
      }
      setState(() { _post = p; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load post.'; _loading = false; });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Post',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.deletePost(_post!.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Post deleted',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to delete'), backgroundColor: Color(0xFFEF4444)));
    }
  }

  String _fmt(String s) {
    try { return DateFormat('MMMM dd, yyyy  •  hh:mm a').format(DateTime.parse(s)); }
    catch (_) { return s; }
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static const _grad = [Color(0xFF6C63FF), Color(0xFF8B5CF6)];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _error != null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  Widget _buildError() => Scaffold(
    appBar: AppBar(),
    body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, size: 64,
            color: Color(0xFFEF4444)),
        const SizedBox(height: 16),
        Text(_error!),
        const SizedBox(height: 16),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back')),
      ],
    )),
  );

  Widget _buildContent(bool isDark) {
    final post = _post!;
    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 220,
        pinned: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PostFormScreen(post: post)));
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Edit', style: GoogleFonts.plusJakartaSans(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: _delete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: _grad,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(_initials(post.author),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(post.author,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 14,
                            fontWeight: FontWeight.w600,
                          )),
                      Text(_fmt(post.createdAt),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70, fontSize: 11)),
                    ]),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Title
            Text(post.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.3,
                )),
            const SizedBox(height: 16),

            // Updated chip
            if (post.createdAt != post.updatedAt)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.update_rounded,
                      size: 13, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 6),
                  Text('Updated ${_fmt(post.updatedAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w500,
                      )),
                ]),
              ),

            const SizedBox(height: 24),

            // Divider
            Container(height: 1,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            const SizedBox(height: 24),

            // Body
            Text(post.body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, height: 1.8,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF334155),
                )),
            const SizedBox(height: 48),
          ]),
        ),
      ),
    ]);
  }
}