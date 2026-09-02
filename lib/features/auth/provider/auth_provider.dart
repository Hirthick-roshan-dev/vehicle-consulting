import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/storage_service.dart';
import '../model/user_role.dart';
import '../repo/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(AppDatabase());
});

final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return await StorageService.init();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService? _storageService;

  AuthNotifier(this._repository, this._storageService) : super(const AuthState()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    if (_storageService != null && _storageService.isLoggedIn) {
      final username = _storageService.currentUsername;
      if (username != null) {
        final user = await _repository.getUserByUsername(username);
        if (user != null) {
          state = state.copyWith(user: user);
        }
      }
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    required UserRole selectedRole,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(
        username: username,
        password: password,
        selectedRole: selectedRole,
      );

      if (_storageService != null) {
        await _storageService.saveSession(
          username: user.username,
          role: user.role.value,
        );
      }

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during login.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    if (_storageService != null) {
      await _storageService.clearSession();
    }
    state = const AuthState();
  }

  Future<bool> verifyPasskey(String passkey) async {
    final currentUser = state.user;
    if (currentUser == null) return false;
    try {
      return await _repository.verifyPasskey(
        username: currentUser.username,
        passkey: passkey,
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    final currentUser = state.user;
    if (currentUser == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.changePassword(
        username: currentUser.username,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storageServiceAsync = ref.watch(storageServiceProvider);
  final storageService = storageServiceAsync.valueOrNull;
  return AuthNotifier(repository, storageService);
});
