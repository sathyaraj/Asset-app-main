import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14.5, color: AppColors.textSecondary)),
          ),
          if (value != null)
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap, child: row);
  }
}
