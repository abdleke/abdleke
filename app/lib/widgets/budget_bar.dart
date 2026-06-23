import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String currency;

  const BudgetBar({
    super.key,
    required this.spent,
    required this.budget,
    this.currency = 'دج',
  });

  @override
  Widget build(BuildContext context) {
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final over = spent > budget;
    final color = over
        ? const Color(0xFFF43F5E)
        : pct > 0.75
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(pct * 100).round()}%',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (over)
              Text(
                '⚠️',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_fmt(spent)} $currency',
              style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF64748B)),
            ),
            Text(
              '${_fmt(budget)} $currency',
              style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
