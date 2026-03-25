// lib/screens/post_form_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';
import '../models/post.dart';

class PostFormScreen extends StatefulWidget {
  final Post? post;
  const PostFormScreen({super.key, this.post});
  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  late final TextEditingController _title, _body, _author;
  bool _saving = false;
  bool get _isEditing => widget.post != null;

  late AnimationController _anim;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.post?.title ?? '');
    _body = TextEditingController(text: widget.post?.body ?? '');
    _author = TextEditingController(text: widget.post?.author ?? '');
    _anim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _title.dispose(); _body.dispose(); _author.dispose(); _anim.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now().toIso8601String();
    try {
      if (_isEditing) {
        await _db.updatePost(widget.post!.copyWith(
          title: _title.text.trim(), body: _body.text.trim(),
          author: _author.text.trim(), updatedAt: now,
        ));
        if (!mounted) return;
        _snack('Post updated!', false);
      } else {
        await _db.insertPost(Post(
          title: _title.text.trim(), body: _body.text.trim(),
          author: _author.text.trim(), createdAt: now, updatedAt: now,
        ));
        if (!mounted) return;
        _snack('Post published!', false);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on DatabaseException catch (e) {
      setState(() => _saving = false);
      _snack('Error: ${e.message}', true);
    } catch (_) {
      setState(() => _saving = false);
      _snack('An unexpected error occurred.', true);
    }
  }

  void _snack(String msg, bool err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500)),
      backgroundColor: err ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit Post' : 'New Post',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                        : [const Color(0xFF6C63FF).withOpacity(0.08),
                            const Color(0xFFF8FAFF)],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  _buildField(
                    controller: _author,
                    label: 'Author Name',
                    hint: 'e.g. Jane Doe',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Author required';
                      if (v.trim().length < 2) return 'Min 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _title,
                    label: 'Post Title',
                    hint: 'Write a captivating title...',
                    icon: Icons.title_rounded,
                    maxLength: 120,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Title required';
                      if (v.trim().length < 5) return 'Min 5 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _body,
                    label: 'Post Content',
                    hint: 'Share your story or news...',
                    icon: Icons.article_outlined,
                    maxLines: 10,
                    minLines: 5,
                    alignLabelWithHint: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Content required';
                      if (v.trim().length < 10) return 'Min 10 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saving ? null : _save,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: _saving
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Row(mainAxisSize: MainAxisSize.min,
                                  children: [
                                  Icon(
                                    _isEditing
                                        ? Icons.save_rounded
                                        : Icons.send_rounded,
                                    color: Colors.white, size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isEditing ? 'Update Post' : 'Publish Post',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white, fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
    bool alignLabelWithHint = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
        alignLabelWithHint: alignLabelWithHint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
          fontSize: 14,
        ),
      ),
    );
  }
}