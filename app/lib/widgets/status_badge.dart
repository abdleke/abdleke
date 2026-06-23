import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BadgeVariant { success, warning, danger, info, neutral, purple }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const StatusBadge({super.key, required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.$2, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

  (Color, Color) _colors() {
    switch (variant) {
      case BadgeVariant.success:
        return (const Color(0xFFD1FAE5), const Color(0xFF059669));
      case BadgeVariant.warning:
        return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
      case BadgeVariant.danger:
        return (const Color(0xFFFFE4E6), const Color(0xFFE11D48));
      case BadgeVariant.info:
        return (const Color(0xFFCFFAFE), const Color(0xFF0891B2));
      case BadgeVariant.purple:
        return (const Color(0xFFEDE9FE), const Color(0xFF7C3AED));
      case BadgeVariant.neutral:
        return (const Color(0xFFF1F5F9), const Color(0xFF64748B));
    }
  }
}
