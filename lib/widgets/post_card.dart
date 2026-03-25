// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static const _gradients = [
    [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    [Color(0xFF10B981), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
  ];

  String _formatDate(String s) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(s));
    } catch (_) { return s; }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = _gradients[index % _gradients.length];
    final preview = post.body.length > 110
        ? '${post.body.substring(0, 110)}...'
        : post.body;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: grad[0].withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 20, offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Gradient avatar
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: grad),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Text(_initials(post.author),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.author,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600, fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            )),
                        Text(_formatDate(post.createdAt),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            )),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 8,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_rounded,
                              size: 17, color: Color(0xFF6C63FF)),
                          const SizedBox(width: 10),
                          Text('Edit',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete_rounded,
                              size: 17, color: Color(0xFFEF4444)),
                          const SizedBox(width: 10),
                          Text('Delete',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFEF4444),
                              )),
                        ]),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                  ),
                ]),

                const SizedBox(height: 14),

                // Colored left-border accent + title
                Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: grad[0], width: 3),
                    ),
                  ),
                  child: Text(post.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      )),
                ),

                const SizedBox(height: 10),

                Text(preview,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, height: 1.6,
                      color: isDark
                          ? Colors.white60
                          : const Color(0xFF475569),
                    )),

                const SizedBox(height: 14),

                // Read more chip
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: grad),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Read more',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 12, color: Colors.white),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}