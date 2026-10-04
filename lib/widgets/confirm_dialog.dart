import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum ConfirmVariant { danger, warning, info }

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmVariant variant;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.variant = ConfirmVariant.danger,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    Color btnColor;
    IconData iconData;

    switch (variant) {
      case ConfirmVariant.danger:
        btnColor = AppColors.danger;
        iconData = Icons.warning_amber_rounded;
        break;
      case ConfirmVariant.warning:
        btnColor = AppColors.warning;
        iconData = Icons.error_outline_rounded;
        break;
      case ConfirmVariant.info:
        btnColor = AppColors.info;
        iconData = Icons.info_outline_rounded;
        break;
    }

    return AlertDialog(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: btnColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: btnColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.darkSubtext,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkSubtext,
            side: const BorderSide(color: AppColors.darkCardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
