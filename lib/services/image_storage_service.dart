import 'dart:io';
import 'dart:convert' show JsonEncoder;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// ImageStorageService — Organizes all images per farmer locally
///
/// Folder Structure:
/// /SAADProfiling/
///   ├─ farmername_lastname_[ID]/
///   │  ├─ firstname_id_front.jpg
///   │  ├─ firstname_id_back.jpg
///   │  ├─ firstname_profile_pic.jpg
///   │  ├─ firstname_signature.png
///   │  └─ draft.json
///   │
///   └─ anotherfarmername_[ID]/
///      └─ ...
///
/// This ensures each farmer's data is completely isolated and organized.
class ImageStorageService {
  static const String _appFolderName = 'SAADProfiling';

  /// Get the base directory for storing profiling data
  Future<Directory> getAppDirectory() async {
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
    final appDir = await getAppDirectory();
    final farmerDir = Directory('${appDir.path}/$farmerFolderName');

    if (!await farmerDir.exists()) {
      await farmerDir.create(recursive: true);
    }
    return farmerDir;
  }

  /// Generate sanitized folder name for farmer from first and last name
  /// Input: "Juan Dela Cruz"
  /// Output: "juan_dela_cruz_timestamp"
  String generateFarmerFolderName(
    String firstName,
    String lastName, {
    String? uniqueId,
  }) {
    final sanitizedFirst = firstName.replaceAll(' ', '_').toLowerCase();
    final sanitizedLast = lastName.replaceAll(' ', '_').toLowerCase();
    final timestamp =
        uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${sanitizedFirst}_${sanitizedLast}_$timestamp';
  }

  /// Generate sanitized folder name from full name string
  /// Example: "Juan S. Dela Cruz" -> "juan_s_dela_cruz_timestamp"
  String generateFarmerFolderNameFromFullName(
    String fullName, {
    String? uniqueId,
  }) {
    final sanitized = fullName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '')
        .toLowerCase();
    final timestamp =
        uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${sanitized}_$timestamp';
  }

  /// Save ID Front Image
  Future<String> saveIdFrontImage(
    File imageFile,
    String farmerFolderName, {
    String? firstName,
    String? lastName,
  }) async {
    return _saveImage(
      imageFile,
      farmerFolderName,
      '_id_front',
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Save ID Back Image
  Future<String> saveIdBackImage(
    File imageFile,
    String farmerFolderName, {
    String? firstName,
    String? lastName,
  }) async {
    return _saveImage(
      imageFile,
      farmerFolderName,
      '_id_back',
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Save Profile Picture
  Future<String> saveProfilePicture(
    File imageFile,
    String farmerFolderName, {
    String? firstName,
    String? lastName,
  }) async {
    return _saveImage(
      imageFile,
      farmerFolderName,
      '_profile_pic',
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Save Signature (as PNG)
  Future<String> saveSignature(
    Uint8List imageData,
    String farmerFolderName, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);

      // Build image name from first name, or extract first name from folder
      final baseName = _buildImageBaseName(
        farmerFolderName,
        firstName: firstName,
      );

      final filePath = '${farmerDir.path}/${baseName}_signature.png';
      final file = File(filePath);

      await file.writeAsBytes(imageData);

      // Verify file was successfully saved
      if (!await file.exists()) {
        throw Exception(
          'Signature file was written but does not exist at: $filePath',
        );
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Signature file saved but is empty at: $filePath');
      }
      debugPrint('✅ Signature saved: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error saving signature: $e');
      rethrow;
    }
  }

  /// Internal method to save image file
  Future<String> _saveImage(
    File imageFile,
    String farmerFolderName,
    String suffix, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);

      // Build image name from first name, or extract first name from folder
      final baseName = _buildImageBaseName(
        farmerFolderName,
        firstName: firstName,
      );

      // Preserve original file extension if available (avoid renaming HEIC/WEBP to .jpg)
      final originalExt = p.extension(imageFile.path).toLowerCase();
      final ext = (originalExt.isEmpty) ? '.jpg' : originalExt;
      final fileName = '$baseName$suffix$ext';
      final targetPath = '${farmerDir.path}/$fileName';

      // Remove old files for the same image type (handles extension changes on retake)
      final existing = await farmerDir.list().where((entity) {
        if (entity is! File) return false;
        final name = p.basename(entity.path).toLowerCase();
        return name.startsWith('${baseName.toLowerCase()}$suffix');
      }).toList();
      for (final entity in existing) {
        await (entity as File).delete();
      }

      // Read bytes and write to new file to ensure consistent storage across platforms
      final imageData = await imageFile.readAsBytes();
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(imageData, flush: true);

      // Verify file was successfully saved
      final savedFile = File(targetPath);
      if (!await savedFile.exists()) {
        throw Exception('File was copied but does not exist at: $targetPath');
      }

      final fileSize = await savedFile.length();
      if (fileSize == 0) {
        throw Exception('File saved but is empty at: $targetPath');
      }
      debugPrint('✅ Image saved: $targetPath');
      return targetPath;
    } catch (e) {
      debugPrint('❌ Error saving image: $e');
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

  /// Build base image filename prefix using first name only.
  /// Input examples:
  ///   firstName="Juan" -> "juan"
  ///   folder="juan_dela_cruz_12345" -> "juan"
  String _buildImageBaseName(String farmerFolderName, {String? firstName}) {
    final providedFirstName = (firstName ?? '').trim();
    if (providedFirstName.isNotEmpty) {
      return _sanitizeNameToken(providedFirstName);
    }

    final baseName = _extractBaseName(farmerFolderName);
    final firstToken = baseName.split('_').first;
    return _sanitizeNameToken(firstToken);
  }

  String _sanitizeNameToken(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Get all farmer folders
  Future<List<String>> getAllFarmerFolders() async {
    try {
      final appDir = await getAppDirectory();
      final entities = await appDir.list().toList();

      final folders = entities
          .whereType<Directory>()
          .map((dir) => dir.path.split(Platform.pathSeparator).last)
          .toList();

      return folders;
    } catch (e) {
      debugPrint('❌ Error listing farmer folders: $e');
      return [];
    }
  }

  /// Get all images for a farmer
  Future<Map<String, String>> getFarmerImages(String farmerFolderName) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);
      final entities = await farmerDir.list().toList();

      Future<void> setNewest(
        Map<String, String> target,
        Map<String, DateTime> targetDates,
        String key,
        File file,
      ) async {
        final modified = await file.lastModified();
        final current = targetDates[key];
        if (current == null || modified.isAfter(current)) {
          target[key] = file.path;
          targetDates[key] = modified;
        }
      }

      final images = <String, String>{};
      final imageDates = <String, DateTime>{};
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (fileName.contains('_id_front') ||
              fileName.contains('_frontimage')) {
            await setNewest(images, imageDates, 'front', entity);
          }
          if (fileName.contains('_id_back') ||
              fileName.contains('_backimage')) {
            await setNewest(images, imageDates, 'back', entity);
          }
          if (fileName.contains('_profile_pic') ||
              fileName.contains('_profilepicture')) {
            await setNewest(images, imageDates, 'profile', entity);
          }
          if (fileName.contains('_signature')) {
            await setNewest(images, imageDates, 'signature', entity);
          }
        }
      }

      return images;
    } catch (e) {
      debugPrint('❌ Error getting farmer images: $e');
      return {};
    }
  }

  String? _imageKindFromFileName(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.contains('_id_front') ||
        normalized.contains('_frontimage')) {
      return 'front';
    }
    if (normalized.contains('_id_back') || normalized.contains('_backimage')) {
      return 'back';
    }
    if (normalized.contains('_profile_pic') ||
        normalized.contains('_profilepicture')) {
      return 'profile';
    }
    if (normalized.contains('_signature')) {
      return 'signature';
    }
    return null;
  }

  /// One-time cleanup for a farmer folder:
  /// keeps only the newest file for each image kind (front/back/profile/signature)
  /// and deletes older duplicates.
  Future<int> cleanupFarmerImageDuplicates(String farmerFolderName) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);
      final entities = await farmerDir
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();

      final grouped = <String, List<File>>{};
      for (final file in entities) {
        final name = p.basename(file.path);
        final kind = _imageKindFromFileName(name);
        if (kind == null) continue;
        grouped.putIfAbsent(kind, () => <File>[]).add(file);
      }

      int deletedCount = 0;
      for (final files in grouped.values) {
        if (files.length <= 1) continue;

        files.sort((a, b) {
          final aTime = a.lastModifiedSync();
          final bTime = b.lastModifiedSync();
          return bTime.compareTo(aTime); // newest first
        });

        for (final oldFile in files.skip(1)) {
          try {
            await oldFile.delete();
            deletedCount++;
          } catch (e) {
            debugPrint(
              '⚠️ Could not delete duplicate file ${oldFile.path}: $e',
            );
          }
        }
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error cleaning duplicates for $farmerFolderName: $e');
      return 0;
    }
  }

  /// One-time cleanup for all farmer folders.
  /// Returns total number of deleted duplicate image files.
  Future<int> cleanupAllFarmerImageDuplicates() async {
    int totalDeleted = 0;
    try {
      final folders = await getAllFarmerFolders();
      for (final folder in folders) {
        totalDeleted += await cleanupFarmerImageDuplicates(folder);
      }
      debugPrint('✅ Duplicate image cleanup complete. Deleted: $totalDeleted');
      return totalDeleted;
    } catch (e) {
      debugPrint('❌ Error running global duplicate cleanup: $e');
      return totalDeleted;
    }
  }

  /// Delete farmer folder and all contents
  Future<void> deleteFarmerFolder(String farmerFolderName) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);
      if (await farmerDir.exists()) {
        await farmerDir.delete(recursive: true);
        debugPrint('✅ Farmer folder deleted: $farmerFolderName');
      }
    } catch (e) {
      debugPrint('❌ Error deleting farmer folder: $e');
      rethrow;
    }
  }

  /// Save profiling data JSON to farmer folder with farmer name in filename
  /// Follows the same naming pattern as images: {firstName}_{lastName}_profiling_data.json
  Future<void> saveDraftJson(
    String farmerFolderName,
    Map<String, dynamic> draftData, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final farmerDir = await _getFarmerFolder(farmerFolderName);

      // Build filename from first and last name for profiling JSON (separate from image naming)
      String fileName;
      if ((firstName ?? '').isNotEmpty && (lastName ?? '').isNotEmpty) {
        final sanitizedFirst = firstName!.toLowerCase().replaceAll(' ', '_');
        final sanitizedLast = lastName!.toLowerCase().replaceAll(' ', '_');
        fileName = '${sanitizedFirst}_${sanitizedLast}_profiling_data.json';
      } else {
        final baseName = _extractBaseName(farmerFolderName);
        fileName = '${baseName}_profiling_data.json';
      }

      final draftFile = File('${farmerDir.path}/$fileName');

      // Convert map to JSON string with pretty formatting
      final jsonString = const JsonEncoder.withIndent('  ').convert(draftData);
      await draftFile.writeAsString(jsonString);

      // Verify file actually saved
      if (!await draftFile.exists()) {
        throw Exception('Draft file was not created at: ${draftFile.path}');
      }

      debugPrint('✅ Profiling data saved: ${draftFile.path}');
    } catch (e) {
      debugPrint('❌ Error saving profiling data JSON: $e');
      rethrow; // Propagate error so calling code knows save failed
    }
  }

  /// Check if an image file exists and is readable
  Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }
    try {
      final file = File(imagePath);
      final exists = await file.exists();
      if (exists) {
        final size = await file.length();
        return size > 0;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error checking image existence at $imagePath: $e');
      return false;
    }
  }

  /// Get image file if it exists, returns null if not valid
  Future<File?> getImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    try {
      final file = File(imagePath);
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
      debugPrint('⚠️ Image file not found or empty: $imagePath');
      return null;
    } catch (e) {
      debugPrint('❌ Error accessing image file $imagePath: $e');
      return null;
    }
  }

  /// Save multiple images in parallel using an isolate (non-blocking).
  /// Useful for saving all 4 images (front ID, back ID, profile photo, signature) at once.
  ///
  /// Params:
  ///   - farmerFolderName: folder where images are stored
  ///   - imagesToSave: map of {imageType -> File} e.g., {'front' -> File(...)}
  ///   - signatureData: optional Uint8List for signature
  ///   - firstName, lastName: for filename generation
  ///
  /// Returns: map of {imageType -> savedPath}
  Future<Map<String, String>> saveImageBatch({
    required String farmerFolderName,
    Map<String, File>? imagesToSave,
    Uint8List? signatureData,
    String? firstName,
    String? lastName,
  }) async {
    final basePath = (await getAppDirectory()).path;
    final farmerPath = '$basePath/$farmerFolderName';

    // Prepare batch payload
    final batchPayload = _ImageBatchPayload(
      farmerPath: farmerPath,
      imagesToSave: imagesToSave ?? {},
      signatureData: signatureData,
      firstName: firstName,
      lastName: lastName,
    );

    // Offload to isolate
    final results = await compute(_saveImageBatchWorker, batchPayload);
    return results;
  }
}

/// Payload for batch image save (must be serializable)
class _ImageBatchPayload {
  final String farmerPath;
  final Map<String, File> imagesToSave;
  final Uint8List? signatureData;
  final String? firstName;
  final String? lastName;

  _ImageBatchPayload({
    required this.farmerPath,
    required this.imagesToSave,
    this.signatureData,
    this.firstName,
    this.lastName,
  });
}

/// Isolate worker: save all images in batch.
/// Runs in background thread and returns {type -> savedPath} map.
Future<Map<String, String>> _saveImageBatchWorker(
  _ImageBatchPayload payload,
) async {
  final results = <String, String>{};

  // Ensure farmer directory exists
  final farmerDir = Directory(payload.farmerPath);
  if (!farmerDir.existsSync()) {
    farmerDir.createSync(recursive: true);
  }

  // Extract first-name base for filenames
  String sanitizeToken(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  String baseName;
  final firstName = (payload.firstName ?? '').trim();
  if (firstName.isNotEmpty) {
    baseName = sanitizeToken(firstName);
  } else {
    final folderName = payload.farmerPath.split(Platform.pathSeparator).last;
    final parts = folderName.split('_');
    final extracted = parts.isNotEmpty ? parts.first : 'farmer';
    baseName = sanitizeToken(extracted);
  }

  // Save regular image files
  for (final entry in payload.imagesToSave.entries) {
    final imageType = entry.key; // 'front', 'back', 'profile'
    try {
      final imageFile = entry.value;

      if (!imageFile.existsSync()) {
        debugPrint('⚠️ Image file does not exist: ${imageFile.path}');
        continue;
      }

      final bytes = imageFile.readAsBytesSync();
      if (bytes.isEmpty) {
        debugPrint('⚠️ Image file is empty: ${imageFile.path}');
        continue;
      }

      final ext = p.extension(imageFile.path).toLowerCase();
      final suffix = imageType == 'front'
          ? '_id_front'
          : imageType == 'back'
          ? '_id_back'
          : '_profile_pic';
      final fileName = '$baseName$suffix${ext.isEmpty ? '.jpg' : ext}';
      final targetPath = '${payload.farmerPath}/$fileName';

      // Remove old files for this image type so retakes are deterministic
      final existing = farmerDir.listSync().whereType<File>().where((file) {
        final name = p.basename(file.path).toLowerCase();
        return name.startsWith('${baseName.toLowerCase()}$suffix');
      }).toList();
      for (final oldFile in existing) {
        oldFile.deleteSync();
      }

      File(targetPath).writeAsBytesSync(bytes);
      results[imageType] = targetPath;
      debugPrint('✅ $imageType saved to: $targetPath');
    } catch (e) {
      debugPrint('❌ Error saving $imageType: $e');
    }
  }

  // Save signature if provided
  if (payload.signatureData != null && payload.signatureData!.isNotEmpty) {
    try {
      final fileName = '${baseName}_signature.png';
      final targetPath = '${payload.farmerPath}/$fileName';
      File(targetPath).writeAsBytesSync(payload.signatureData!);
      results['signature'] = targetPath;
      debugPrint('✅ Signature saved to: $targetPath');
    } catch (e) {
      debugPrint('❌ Error saving signature: $e');
    }
  }

  return results;
}
