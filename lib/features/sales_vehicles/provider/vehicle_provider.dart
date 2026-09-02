import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../model/vehicle_model.dart';
import '../repo/expense_repository.dart';
import '../repo/sales_repository.dart';
import '../repo/vehicle_repository.dart';
import 'vehicle_filter_provider.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(AppDatabase());
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(AppDatabase());
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(AppDatabase());
});

class VehicleState {
  final List<VehicleModel> vehicles;
  final Map<int, double> vehicleExpensesMap; // vehicleId -> totalExpenses
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int pageSize;
  final int totalCount;

  int get totalPages => (totalCount / pageSize).ceil() == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get hasPrevPage => currentPage > 1;
  bool get hasNextPage => currentPage < totalPages;

  const VehicleState({
    this.vehicles = const [],
    this.vehicleExpensesMap = const {},
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.pageSize = 12,
    this.totalCount = 0,
  });

  VehicleState copyWith({
    List<VehicleModel>? vehicles,
    Map<int, double>? vehicleExpensesMap,
    bool? isLoading,
    String? errorMessage,
    int? currentPage,
    int? pageSize,
    int? totalCount,
    bool clearError = false,
  }) {
    return VehicleState(
      vehicles: vehicles ?? this.vehicles,
      vehicleExpensesMap: vehicleExpensesMap ?? this.vehicleExpensesMap,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleRepository _vehicleRepository;
  final ExpenseRepository _expenseRepository;

  VehicleNotifier(this._vehicleRepository, this._expenseRepository)
      : super(const VehicleState());

  Future<void> loadSalesVehicles(VehicleFilterState filter, {int? page}) async {
    final targetPage = page ?? state.currentPage;
    state = state.copyWith(isLoading: true, clearError: true, currentPage: targetPage);
    try {
      final totalCount = await _vehicleRepository.getVehiclesCount(
        filterStatus: filter.statusFilter,
        filterType: filter.typeFilter,
        searchQuery: filter.searchQuery,
        isCompletedOnly: false,
      );

      final offset = (targetPage - 1) * state.pageSize;

      final vehicles = await _vehicleRepository.getVehicles(
        filterStatus: filter.statusFilter,
        filterType: filter.typeFilter,
        searchQuery: filter.searchQuery,
        isCompletedOnly: false,
        limit: state.pageSize,
        offset: offset,
      );

      // Fetch expenses totals for vehicles
      final Map<int, double> expensesMap = {};
      for (var v in vehicles) {
        if (v.id != null) {
          final expenses = await _expenseRepository.getExpensesByVehicleId(v.id!);
          final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
          expensesMap[v.id!] = total;
        }
      }

      state = state.copyWith(
        vehicles: vehicles,
        vehicleExpensesMap: expensesMap,
        totalCount: totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void nextPage(VehicleFilterState filter) {
    if (state.hasNextPage) {
      loadSalesVehicles(filter, page: state.currentPage + 1);
    }
  }

  void prevPage(VehicleFilterState filter) {
    if (state.hasPrevPage) {
      loadSalesVehicles(filter, page: state.currentPage - 1);
    }
  }

  Future<bool> addVehicle(VehicleModel vehicle) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _vehicleRepository.addVehicle(vehicle);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateVehicle(VehicleModel vehicle) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _vehicleRepository.updateVehicle(vehicle);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _vehicleRepository.deleteVehicle(vehicleId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  return VehicleNotifier(vehicleRepo, expenseRepo);
});
