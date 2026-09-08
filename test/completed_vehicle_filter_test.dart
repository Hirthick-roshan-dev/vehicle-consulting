import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/features/completed_vehicles/provider/completed_vehicle_provider.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_type.dart';

void main() {
  group('CompletedVehicleFilter & CompletedPeriod Tests', () {
    test('CompletedPeriod calculates weekly start and end date boundaries properly', () {
      final period = CompletedPeriod.weekly;
      final start = period.startDate;
      final end = period.endDate;

      expect(start, isNotNull);
      expect(end, isNotNull);

      // Start of week should be Monday (weekday == 1)
      expect(start!.weekday, DateTime.monday);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);

      // End of week should be Sunday (weekday == 7)
      expect(end!.weekday, DateTime.sunday);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);

      // End should be after start
      expect(end.isAfter(start), isTrue);
    });

    test('CompletedPeriod calculates monthly start and end date boundaries properly', () {
      final period = CompletedPeriod.monthly;
      final start = period.startDate;
      final end = period.endDate;

      expect(start, isNotNull);
      expect(end, isNotNull);

      // Start of month should be day 1
      expect(start!.day, 1);
      expect(start.hour, 0);
      expect(start.minute, 0);

      // End of month should be the last day of month
      final now = DateTime.now();
      expect(end!.month, now.month);
      expect(end.hour, 23);
      expect(end.minute, 59);

      // End should be after start
      expect(end.isAfter(start), isTrue);
    });

    test('CompletedPeriod.all has null start and end dates', () {
      final period = CompletedPeriod.all;
      expect(period.startDate, isNull);
      expect(period.endDate, isNull);
    });

    test('CompletedVehicleFilter copyWith works correctly with periods and clearType', () {
      const initial = CompletedVehicleFilter();
      expect(initial.period, CompletedPeriod.all);
      expect(initial.typeFilter, isNull);
      expect(initial.page, 1);

      // Change period to weekly
      final weekly = initial.copyWith(period: CompletedPeriod.weekly);
      expect(weekly.period, CompletedPeriod.weekly);

      // Change period to monthly
      final monthly = weekly.copyWith(period: CompletedPeriod.monthly);
      expect(monthly.period, CompletedPeriod.monthly);

      // Filter by 2W and clearType
      final twoW = monthly.copyWith(typeFilter: VehicleType.twoWheeler);
      expect(twoW.typeFilter, VehicleType.twoWheeler);
      expect(twoW.period, CompletedPeriod.monthly);

      final cleared = twoW.copyWith(clearType: true);
      expect(cleared.typeFilter, isNull);
      expect(cleared.period, CompletedPeriod.monthly);
    });

    test('CompletedVehiclesResult handles pagination getters and aggregates correctly', () {
      final result = CompletedVehiclesResult(
        items: [],
        totalCount: 25,
        currentPage: 2,
        pageSize: 10,
        totalSales: 2500000.0,
        totalCost: 2000000.0,
        totalNetPL: 500000.0,
        totalBalanceDue: 100000.0,
      );

      expect(result.totalPages, 3);
      expect(result.hasPrevPage, isTrue);
      expect(result.hasNextPage, isTrue);
      expect(result.totalSales, 2500000.0);
      expect(result.totalNetPL, 500000.0);
    });
  });
}
