import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../model/business_profile_model.dart';
import '../repo/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(AppDatabase());
});

final businessProfileProvider =
    FutureProvider<BusinessProfileModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getProfile();
});
