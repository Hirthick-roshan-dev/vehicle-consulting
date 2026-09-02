import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/provider/auth_provider.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/passkey_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 64, color: AppColors.loss),
                SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.loss),
                ),
                SizedBox(height: 8),
                Text(
                  'Security settings and credential management are accessible to Admin users only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your security credentials and password.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'Security & Credential Management',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                        title: const Text(
                          'Change Password',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Update your SHA-256 encrypted login password (passkey verification required).',
                          style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                        ),
                        trailing: AppButton(
                          text: 'Change Password',
                          isSecondary: true,
                          onPressed: () async {
                            final verified = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => const PasskeyDialog(),
                            );
                            if (verified == true && context.mounted) {
                              final changed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => const ChangePasswordDialog(isPasskeyMode: false),
                              );
                              if (changed == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated successfully!'),
                                    backgroundColor: AppColors.profit,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
