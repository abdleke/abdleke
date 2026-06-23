import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? color;

  const MemberAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? const Color(0xFF7C3AED);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size / 2.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.cairo(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: bg,
          ),
        ),
      ),
    );
  }
}
