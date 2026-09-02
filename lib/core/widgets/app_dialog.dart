import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isLoading;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Save',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Flexible(child: SingleChildScrollView(child: content)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (cancelText != null) ...[
                  AppButton(
                    text: cancelText!,
                    isSecondary: true,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                ],
                if (confirmText != null)
                  AppButton(
                    text: confirmText!,
                    isLoading: isLoading,
                    onPressed: onConfirm,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
