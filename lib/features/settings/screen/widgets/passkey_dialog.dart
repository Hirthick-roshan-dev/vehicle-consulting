import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/provider/auth_provider.dart';

class PasskeyDialog extends ConsumerStatefulWidget {
  const PasskeyDialog({super.key});

  @override
  ConsumerState<PasskeyDialog> createState() => _PasskeyDialogState();
}

class _PasskeyDialogState extends ConsumerState<PasskeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passkeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final isValid = await ref.read(authProvider.notifier).verifyPasskey(
          _passkeyController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (isValid && mounted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText = 'Incorrect passkey entered. Access denied.';
      });
    }
  }

  @override
  void dispose() {
    _passkeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Security Verification',
      confirmText: 'Verify Passkey',
      isLoading: _isLoading,
      onConfirm: _verify,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Please enter your security passkey before making changes to sensitive account credentials.',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Security Passkey *',
              hint: 'Enter passkey (default is 1234)',
              controller: _passkeyController,
              obscureText: true,
              prefixIcon: const Icon(Icons.key, size: 20),
              validator: (val) => val == null || val.isEmpty ? 'Passkey is required' : null,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: AppColors.loss, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
