import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/vehicle_status.dart';
import '../model/vehicle_type.dart';

class VehicleFilterState {
  final String searchQuery;
  final VehicleType? typeFilter;
  final VehicleStatus? statusFilter;

  const VehicleFilterState({
    this.searchQuery = '',
    this.typeFilter,
    this.statusFilter,
  });

  VehicleFilterState copyWith({
    String? searchQuery,
    VehicleType? typeFilter,
    VehicleStatus? statusFilter,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return VehicleFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class VehicleFilterNotifier extends StateNotifier<VehicleFilterState> {
  VehicleFilterNotifier() : super(const VehicleFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(VehicleType? type) {
    if (type == state.typeFilter) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(typeFilter: type);
    }
  }

  void setStatusFilter(VehicleStatus? status) {
    if (status == state.statusFilter) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(statusFilter: status);
    }
  }

  void reset() {
    state = const VehicleFilterState();
  }
}

final vehicleFilterProvider =
    StateNotifierProvider<VehicleFilterNotifier, VehicleFilterState>((ref) {
  return VehicleFilterNotifier();
});
