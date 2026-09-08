import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sample_data_service.dart';
import '../../completed_vehicles/provider/completed_vehicle_provider.dart';
import '../../reports/provider/report_provider.dart';
import '../../sales_vehicles/provider/vehicle_filter_provider.dart';
import '../../sales_vehicles/provider/vehicle_provider.dart';

class SampleDataState {
  final bool isLoaded;
  final bool isOperating;
  final String? errorMessage;

  const SampleDataState({
    this.isLoaded = false,
    this.isOperating = false,
    this.errorMessage,
  });

  SampleDataState copyWith({
    bool? isLoaded,
    bool? isOperating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SampleDataState(
      isLoaded: isLoaded ?? this.isLoaded,
      isOperating: isOperating ?? this.isOperating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SampleDataNotifier extends StateNotifier<SampleDataState> {
  final SampleDataService _service;
  final Ref _ref;

  SampleDataNotifier(this._service, this._ref) : super(const SampleDataState()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    final loaded = await _service.isSampleDataLoaded();
    state = state.copyWith(isLoaded: loaded);
  }

  Future<bool> toggleSampleData(bool enable) async {
    state = state.copyWith(isOperating: true, clearError: true);
    try {
      if (enable) {
        await _service.loadSampleData();
      } else {
        await _service.removeSampleData();
      }

      final loaded = await _service.isSampleDataLoaded();
      state = state.copyWith(isLoaded: loaded, isOperating: false);

      // Invalidate and refresh all dependent views
      _ref.read(vehicleProvider.notifier).loadSalesVehicles(_ref.read(vehicleFilterProvider));
      _ref.invalidate(completedVehiclesProvider);
      _ref.invalidate(vehiclesReportDataProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isOperating: false, errorMessage: e.toString());
      return false;
    }
  }
}

final sampleDataServiceProvider = Provider<SampleDataService>((ref) {
  return SampleDataService();
});

final sampleDataProvider = StateNotifierProvider<SampleDataNotifier, SampleDataState>((ref) {
  final service = ref.watch(sampleDataServiceProvider);
  return SampleDataNotifier(service, ref);
});
