import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vehicle_consulting/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VehicleConsultingApp(),
      ),
    );
    expect(find.text('VEHICLE CONSULTING'), findsOneWidget);
  });
}
