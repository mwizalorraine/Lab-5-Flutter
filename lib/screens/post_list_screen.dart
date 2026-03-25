// lib/screens/post_list_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/post.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';
import '../widgets/post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});
  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Post> _posts = [];
  List<Post> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabAnim.forward();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final posts = await _db.getAllPosts();
      setState(() { _posts = posts; _filtered = posts; _loading = false; });
    } on DatabaseException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Unexpected error. Please retry.'; _loading = false; });
    }
  }

  void _onSearch(String q) {
    if (q.isEmpty) { setState(() => _filtered = _posts); return; }
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _posts.where((p) =>
          p.title.toLowerCase().contains(lower) ||
          p.body.toLowerCase().contains(lower) ||
          p.author.toLowerCase().contains(lower)).toList();
    });
  }

  Future<void> _delete(Post post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Post',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
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
      await _db.deletePost(post.id!);
      if (!mounted) return;
      _showSnack('Post deleted successfully', isError: false);
      _load();
    } on DatabaseException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            snap: true,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
              title: _searching
                  ? TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: GoogleFonts.plusJakartaSans(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search posts...',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                      onChanged: _onSearch,
                    )
                  : Text('Offline Posts',
                      style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: isDark ? Colors.white : const Color(0xFF0F172A))),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                        : [const Color(0xFF6C63FF).withOpacity(0.12),
                            const Color(0xFFF8FAFF)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, right: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AppBarButton(
                          icon: _searching ? Icons.close : Icons.search,
                          onTap: () {
                            setState(() {
                              _searching = !_searching;
                              if (!_searching) {
                                _searchCtrl.clear();
                                _filtered = _posts;
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _AppBarButton(icon: Icons.refresh, onTap: _load),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Stats bar
          SliverToBoxAdapter(
            child: _StatsBar(count: _filtered.length, isSearching: _searching),
          ),
          // Content
          if (_loading)
            const SliverFillRemaining(
                child: Center(child: _LoadingWidget()))
          else if (_error != null)
            SliverFillRemaining(
                child: _ErrorState(message: _error!, onRetry: _load))
          else if (_posts.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else if (_filtered.isEmpty)
            const SliverFillRemaining(child: _NoResultsState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final post = _filtered[i];
                  return PostCard(
                    post: post,
                    index: i,
                    onTap: () async {
                      await Navigator.push(ctx, _slide(PostDetailScreen(postId: post.id!)));
                      _load();
                    },
                    onEdit: () async {
                      await Navigator.push(ctx, _slide(PostFormScreen(post: post)));
                      _load();
                    },
                    onDelete: () => _delete(post),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context, _slide(const PostFormScreen()));
            _load();
          },
          icon: const Icon(Icons.add_rounded),
          label: Text('New Post',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18,
            color: isDark ? Colors.white70 : const Color(0xFF475569)),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int count;
  final bool isSearching;
  const _StatsBar({required this.count, required this.isSearching});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          isSearching
              ? '$count result${count == 1 ? '' : 's'} found'
              : '$count post${count == 1 ? '' : 's'} stored offline',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Icon(Icons.wifi_off_rounded, size: 14,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text('Offline Ready',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            )),
      ]),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        width: 48, height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFF6C63FF),
        ),
      ),
      const SizedBox(height: 20),
      Text('Loading posts...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: const Color(0xFF94A3B8))),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.article_rounded,
              size: 48, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text('No Posts Yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            )),
        const SizedBox(height: 8),
        Text('Tap the button below to write your first post.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, color: const Color(0xFF94A3B8))),
      ]),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.search_off_rounded, size: 64,
          color: Color(0xFF94A3B8)),
      const SizedBox(height: 16),
      Text('No Results Found',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B))),
      const SizedBox(height: 8),
      Text('Try different keywords.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: const Color(0xFF94A3B8))),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.error_outline_rounded,
              size: 40, color: Color(0xFFEF4444)),
        ),
        const SizedBox(height: 20),
        Text('Something went wrong',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 24),
        FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry')),
      ]),
    ),
  );
}