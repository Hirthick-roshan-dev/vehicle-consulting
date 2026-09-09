import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1300, 700),
    minimumSize: Size(1300, 700),
    center: true,
    title: 'Vehicle Consulting',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Verify system date is within the 3-day active window (September 9 to September 12, 2026)
  final now = DateTime.now();
  final startDate = DateTime(2026, 9, 9);
  final expiryDate = DateTime(2026, 9, 12, 23, 59, 59);
  final isAppActive = !now.isBefore(startDate) && !now.isAfter(expiryDate);

  if (isAppActive) {
    runApp(const ProviderScope(child: VehicleConsultingApp()));
  } else {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(color: Colors.white),
      ),
    );
  }
}
