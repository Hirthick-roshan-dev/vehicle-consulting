import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_status.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_type.dart';
import 'package:vehicle_consulting/features/sales_vehicles/provider/vehicle_filter_provider.dart';

void main() {
  group('VehicleFilterState & Notifier Tests', () {
    test('VehicleFilterState.copyWith clears type and status when requested', () {
      final state = VehicleFilterState(
        typeFilter: VehicleType.fourWheeler,
        statusFilter: VehicleStatus.available,
      );

      // Clearing type
      final clearedType = state.copyWith(clearType: true);
      expect(clearedType.typeFilter, isNull);
      expect(clearedType.statusFilter, VehicleStatus.available);

      // Clearing status
      final clearedStatus = state.copyWith(clearStatus: true);
      expect(clearedStatus.statusFilter, isNull);
      expect(clearedStatus.typeFilter, VehicleType.fourWheeler);

      // Setting both to null with clear flags
      final clearedBoth = state.copyWith(clearType: true, clearStatus: true);
      expect(clearedBoth.typeFilter, isNull);
      expect(clearedBoth.statusFilter, isNull);
    });

    test('VehicleFilterNotifier setTypeFilter and setStatusFilter properly clear filters when null is passed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(vehicleFilterProvider.notifier);

      // Set initial filters
      notifier.setTypeFilter(VehicleType.twoWheeler);
      notifier.setStatusFilter(VehicleStatus.partialPayment);

      var state = container.read(vehicleFilterProvider);
      expect(state.typeFilter, VehicleType.twoWheeler);
      expect(state.statusFilter, VehicleStatus.partialPayment);

      // Calling setTypeFilter(null) should clear the type filter to null ("All Types")
      notifier.setTypeFilter(null);
      state = container.read(vehicleFilterProvider);
      expect(state.typeFilter, isNull);
      expect(state.statusFilter, VehicleStatus.partialPayment);

      // Calling setStatusFilter(null) should clear the status filter to null ("All Statuses")
      notifier.setStatusFilter(null);
      state = container.read(vehicleFilterProvider);
      expect(state.statusFilter, isNull);
      expect(state.typeFilter, isNull);
    });
  });
}
