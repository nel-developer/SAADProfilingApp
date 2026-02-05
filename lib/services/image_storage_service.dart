import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// ImageStorageService — Organizes all images per farmer locally
///
/// Folder Structure:
/// /SAADProfiling/
///   ├─ farmername_lastname_[ID]/
///   │  ├─ farmername_lastname_frontimage.jpg
///   │  ├─ farmername_lastname_backimage.jpg
///   │  ├─ farmername_lastname_profilepicture.jpg
///   │  ├─ farmername_lastname_signature.png
///   │  └─ draft.json
///   │
///   └─ anotherfarmername_[ID]/
///      └─ ...
///
/// This ensures each farmer's data is completely isolated and organized.
class ImageStorageService {
  static const String _appFolderName = 'SAADProfiling';

  /// Get the base directory for storing profiling data
  Future<Directory> _getAppDirectory() async {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw Exception('Cannot access external storage');
    }

    final appDir = Directory('${externalDir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  /// Get/Create farmer-specific folder
  /// folderName format: "firstname_lastname_uniqueid" (e.g., "juan_dela_cruz_12345")
  Future<Directory> _getFarmerFolder(String farmerFolderName) async {
    final appDir = await _getAppDirectory();
    final farmerDir = Directory('${appDir.path}/$farmerFolderName');

    if (!await farmerDir.exists()) {
      await farmerDir.create(recursive: true);
    }
    return farmerDir;
  }

  /// Generate sanitized folder name for farmer from first and last name
  /// Input: "Juan Dela Cruz"
  /// Output: "juan_dela_cruz_<timestamp>"
  String generateFarmerFolderName(String firstName, String lastName, {String? uniqueId}) {
    final sanitizedFirst = firstName.replaceAll(' ', '_').toLowerCase();
    final sanitizedLast = lastName.replaceAll(' ', '_').toLowerCase();
    final timestamp = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${sanitizedFirst}_${sanitizedLast}_$timestamp';
  }

  /// Generate sanitized folder name from full name string
  /// Example: "Juan S. Dela Cruz" -> "juan_s_dela_cruz_<timestamp>"
  String generateFarmerFolderNameFromFullName(String fullName, {String? uniqueId}) {
    final sanitized = fullName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '')
        .toLowerCase();
    final timestamp = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${sanitized}_$timestamp';
  }

  /// Save ID Front Image
  Future<String> saveIdFrontImage(File imageFile, String farmerFolderName,
      {String? firstName, String? lastName}) async {
    return _saveImage(imageFile, farmerFolderName, '_frontimage',
        firstName: firstName, lastName: lastName);
  }

  /// Save ID Back Image
  Future<String> saveIdBackImage(File imageFile, String farmerFolderName,
      {String? firstName, String? lastName}) async {
    return _saveImage(imageFile, farmerFolderName, '_backimage',
        firstName: firstName, lastName: lastName);
  }

  /// Save Profile Picture
  Future<String> saveProfilePicture(File imageFile, String farmerFolderName,
      {String? firstName, String? lastName}) async {
    return _saveImage(imageFile, farmerFolderName, '_profilepicture',
        firstName: firstName, lastName: lastName);
  }

  /// Save Signature (as PNG)
  Future<String> saveSignature(Uint8List imageData, String farmerFolderName,
      {String? firstName, String? lastName}) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);

      // Build image name from first and last name, or extract from folder
      String baseName;
      if ((firstName ?? '').isNotEmpty && (lastName ?? '').isNotEmpty) {
        baseName =
            '${firstName!.toLowerCase().replaceAll(' ', '_')}_${lastName!.toLowerCase().replaceAll(' ', '_')}';
      } else {
        baseName = _extractBaseName(farmerFolderName);
      }

      final filePath = '${farmerDir.path}/${baseName}_signature.png';
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      print('✅ Signature saved: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error saving signature: $e');
      rethrow;
    }
  }

  /// Internal method to save image file
  Future<String> _saveImage(File imageFile, String farmerFolderName, String suffix,
      {String? firstName, String? lastName}) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);

      // Build image name from first and last name, or extract from folder
      String baseName;
      if ((firstName ?? '').isNotEmpty && (lastName ?? '').isNotEmpty) {
        baseName =
            '${firstName!.toLowerCase().replaceAll(' ', '_')}_${lastName!.toLowerCase().replaceAll(' ', '_')}';
      } else {
        baseName = _extractBaseName(farmerFolderName);
      }

      final fileName = '$baseName$suffix.jpg';
      final targetPath = '${farmerDir.path}/$fileName';

      await imageFile.copy(targetPath);

      print('✅ Image saved: $targetPath');
      return targetPath;
    } catch (e) {
      print('❌ Error saving image: $e');
      rethrow;
    }
  }

  /// Extract base name from farmer folder (removes timestamp)
  /// Input: "juan_dela_cruz_12345"
  /// Output: "juan_dela_cruz"
  String _extractBaseName(String farmerFolderName) {
    // Remove the last part (timestamp/id) - split by underscore and rejoin all but last
    final parts = farmerFolderName.split('_');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join('_');
    }
    return farmerFolderName;
  }

  /// Get all farmer folders
  Future<List<String>> getAllFarmerFolders() async {
    try {
      final appDir = await _getAppDirectory();
      final entities = await appDir.list().toList();

      final folders = entities
          .whereType<Directory>()
          .map((dir) => dir.path.split(Platform.pathSeparator).last)
          .toList();

      return folders;
    } catch (e) {
      print('❌ Error listing farmer folders: $e');
      return [];
    }
  }

  /// Get all images for a farmer
  Future<Map<String, String>> getFarmerImages(String farmerFolderName) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);
      final entities = await farmerDir.list().toList();

      final images = <String, String>{};
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (fileName.contains('_frontimage')) images['front'] = entity.path;
          if (fileName.contains('_backimage')) images['back'] = entity.path;
          if (fileName.contains('_profilepicture'))
            images['profile'] = entity.path;
          if (fileName.contains('_signature')) images['signature'] = entity.path;
        }
      }

      return images;
    } catch (e) {
      print('❌ Error getting farmer images: $e');
      return {};
    }
  }

  /// Delete farmer folder and all contents
  Future<void> deleteFarmerFolder(String farmerFolderName) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);
      if (await farmerDir.exists()) {
        await farmerDir.delete(recursive: true);
        print('✅ Farmer folder deleted: $farmerFolderName');
      }
    } catch (e) {
      print('❌ Error deleting farmer folder: $e');
      rethrow;
    }
  }

  /// Save draft JSON to farmer folder
  Future<void> saveDraftJson(String farmerFolderName, Map<String, dynamic> draftData) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);
      final draftFile = File('${farmerDir.path}/draft.json');
      
      // Convert map to JSON string with pretty formatting
      final jsonString = const JsonEncoder.withIndent('  ').convert(draftData);
      await draftFile.writeAsString(jsonString);
      
      print('✅ Draft JSON saved: ${draftFile.path}');
    } catch (e) {
      print('⚠️ Error saving draft JSON: $e');
      // Don't rethrow; this is a non-critical operation
    }
  }
}

// Import JsonEncoder for pretty JSON formatting
import 'dart:convert' show JsonEncoder;
