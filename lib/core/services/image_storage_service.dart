import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  /// Returns the persistent application directory for storing vehicle photos:
  /// e.g. `<ApplicationSupportDirectory>/images`
  static Future<String> getImagesDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final imagesDir = Directory(join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  /// Copies a chosen photo to the dedicated `vehicle_consulting/images` directory and returns the saved file path.
  static Future<String> saveVehicleImage({
    required String sourceFilePath,
    required String vehicleNumber,
  }) async {
    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) {
      throw Exception('Selected source image file does not exist.');
    }

    final imagesDirPath = await getImagesDirectory();
    
    // If the file is already in the app's images directory, no need to recopy
    if (sourceFilePath.startsWith(imagesDirPath)) {
      return sourceFilePath;
    }

    final extension = extensionFromPath(sourceFilePath).toLowerCase();
    final sanitizedNum = vehicleNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toUpperCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = 'vehicle_${sanitizedNum}_$timestamp$extension';
    final targetPath = join(imagesDirPath, newFileName);

    final copiedFile = await sourceFile.copy(targetPath);
    return copiedFile.path;
  }

  /// Helper to extract extension safely
  static String extensionFromPath(String path) {
    final ext = extension(path);
    return ext.isEmpty ? '.jpg' : ext;
  }

  /// Removes an image file from the `images` directory if it exists.
  static Future<void> deleteVehicleImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore file deletion errors gracefully
    }
  }
}
