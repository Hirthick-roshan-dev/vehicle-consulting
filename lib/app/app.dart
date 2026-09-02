import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/provider/auth_provider.dart';
import '../features/auth/screen/login_screen.dart';
import 'app_navigation.dart';

class VehicleConsultingApp extends ConsumerWidget {
  const VehicleConsultingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Vehicle Consulting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isAuthenticated
          ? const AppNavigation()
          : const LoginScreen(),
    );
  }
}
