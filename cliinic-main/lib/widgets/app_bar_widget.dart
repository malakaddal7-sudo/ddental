
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget? action;
  const CustomAppBar({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.text, size: 18),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(title, style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: AppColors.text)),
        ),
        if (action != null) action!,
      ]),
    );
  }
}