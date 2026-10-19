import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InfoSectionCard extends StatelessWidget {
  final IconData headerIcon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const InfoSectionCard({
    super.key,
    required this.headerIcon,
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: AppColors.iconChipBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(headerIcon, size: 19, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          ...children,
        ],
      ),
    );
  }
}
