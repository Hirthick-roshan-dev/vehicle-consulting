import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../model/business_profile_model.dart';

class ProfileRepositoryException implements Exception {
  final String message;
  ProfileRepositoryException(this.message);

  @override
  String toString() => message;
}

class ProfileRepository {
  final AppDatabase _appDatabase;

  static final BusinessProfileModel defaultProfile = BusinessProfileModel(
    id: 1,
    businessName: "BROTHER'S AUTO CONSULTING",
    address: '#4, 100 Feet Road, Abirami Nagar, Udumalpet, Tiruppur (Dt.), 642126',
    phone: '+91 9578940360, +91 8072663566',
    email: null,
    gstNumber: null,
    updatedAt: DateTime.now().toIso8601String(),
  );

  ProfileRepository(this._appDatabase);

  Future<BusinessProfileModel> getProfile() async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseConstants.tableBusinessProfile,
        where: 'id = 1',
      );
      if (results.isEmpty) {
        // Auto-insert default business profile if table is empty
        await db.insert(
          DatabaseConstants.tableBusinessProfile,
          defaultProfile.toMap(),
        );
        return defaultProfile;
      }
      return BusinessProfileModel.fromMap(results.first);
    } catch (e) {
      return defaultProfile;
    }
  }

  Future<void> updateProfile(BusinessProfileModel profile) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DatabaseConstants.tableBusinessProfile,
        profile.toMap(),
        where: 'id = 1',
      );
    } catch (e) {
      throw ProfileRepositoryException('Failed to update business profile.');
    }
  }
}
