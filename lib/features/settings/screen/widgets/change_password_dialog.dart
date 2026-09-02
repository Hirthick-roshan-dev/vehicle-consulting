import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/provider/auth_provider.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  final bool isPasskeyMode;

  const ChangePasswordDialog({
    super.key,
    this.isPasskeyMode = false,
  });

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please re-enter.'),
          backgroundColor: AppColors.loss,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (widget.isPasskeyMode) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        try {
          await ref.read(authRepositoryProvider).changePasskey(
                username: user.username,
                newPasskey: newPass,
              );
          success = true;
        } catch (e) {
          success = false;
        }
      } else {
        success = false;
      }
    } else {
      success = await ref.read(authProvider.notifier).changePassword(newPass);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isPasskeyMode ? 'Failed to change passkey.' : 'Failed to change password.',
          ),
          backgroundColor: AppColors.loss,
        ),
      );
    }
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPasskeyMode ? 'Change Passkey' : 'Change Password';

    return AppDialog(
      title: title,
      confirmText: widget.isPasskeyMode ? 'Update Passkey' : 'Update Password',
      isLoading: _isLoading,
      onConfirm: _submit,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: widget.isPasskeyMode ? 'New Security Passkey *' : 'New Password *',
              hint: widget.isPasskeyMode ? 'Enter new passkey' : 'Enter new password',
              controller: _newPassController,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              validator: (val) => val == null || val.trim().isEmpty
                  ? '${widget.isPasskeyMode ? "Passkey" : "Password"} cannot be empty'
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: widget.isPasskeyMode ? 'Confirm New Passkey *' : 'Confirm New Password *',
              hint: widget.isPasskeyMode ? 'Re-enter new passkey' : 'Re-enter new password',
              controller: _confirmPassController,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Confirmation is required'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
