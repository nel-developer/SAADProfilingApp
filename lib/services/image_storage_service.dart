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
  String generateFarmerFolderName(String firstName, String lastName, {String? uniqueId}) {
    final sanitizedFirst = firstName.replaceAll(' ', '_').toLowerCase();
    final sanitizedLast = lastName.replaceAll(' ', '_').toLowerCase();
    final timestamp = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();
    return '${sanitizedFirst}_${sanitizedLast}_$timestamp';
  }

  /// Generate sanitized folder name from full name string
  /// Example: "Juan S. Dela Cruz" -> "juan_s_dela_cruz_timestamp"
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

      // Verify file was successfully saved
      if (!await file.exists()) {
        throw Exception('Signature file was written but does not exist at: $filePath');
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

      // Preserve original file extension if available (avoid renaming HEIC/WEBP to .jpg)
      final originalExt = p.extension(imageFile.path).toLowerCase();
      final ext = (originalExt.isEmpty) ? '.jpg' : originalExt;
      final fileName = '$baseName$suffix$ext';
      final targetPath = '${farmerDir.path}/$fileName';

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

      final images = <String, String>{};
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (fileName.contains('_frontimage')) images['front'] = entity.path;
          if (fileName.contains('_backimage')) images['back'] = entity.path;
          if (fileName.contains('_profilepicture')) {
            images['profile'] = entity.path;
          }
          if (fileName.contains('_signature')) images['signature'] = entity.path;
        }
      }

      return images;
    } catch (e) {
      debugPrint('❌ Error getting farmer images: $e');
      return {};
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

      // Build filename from first and last name (same pattern as _frontimage, _signature, etc)
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
Future<Map<String, String>> _saveImageBatchWorker(_ImageBatchPayload payload) async {
  final results = <String, String>{};
  
  // Ensure farmer directory exists
  final farmerDir = Directory(payload.farmerPath);
  if (!farmerDir.existsSync()) {
    farmerDir.createSync(recursive: true);
  }
  
  // Extract base name for filenames
  String baseName;
  if ((payload.firstName ?? '').isNotEmpty && (payload.lastName ?? '').isNotEmpty) {
    baseName = 
        '${payload.firstName!.toLowerCase().replaceAll(' ', '_')}_${payload.lastName!.toLowerCase().replaceAll(' ', '_')}';
  } else {
    // Extract from folder name (remove timestamp suffix)
    final parts = payload.farmerPath.split(Platform.pathSeparator).last.split('_');
    baseName = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('_') : parts.first;
  }
  
  // Save regular image files
  for (final entry in payload.imagesToSave.entries) {
    try {
      final imageFile = entry.value;
      final imageType = entry.key; // 'front', 'back', 'profile'
      
      if (!imageFile.existsSync()) continue;
      
      final bytes = imageFile.readAsBytesSync();
      if (bytes.isEmpty) continue;
      
      final ext = p.extension(imageFile.path).toLowerCase();
      final suffix = imageType == 'front' 
          ? '_frontimage' 
          : imageType == 'back' 
            ? '_backimage' 
            : '_profilepicture';
      final fileName = '$baseName$suffix${ext.isEmpty ? '.jpg' : ext}';
      final targetPath = '${payload.farmerPath}/$fileName';
      
      File(targetPath).writeAsBytesSync(bytes);
      results[imageType] = targetPath;
    } catch (_) {
      // silently skip failed individual images
      continue;
    }
  }
  
  // Save signature if provided
  if (payload.signatureData != null && payload.signatureData!.isNotEmpty) {
    try {
      final fileName = '${baseName}_signature.png';
      final targetPath = '${payload.farmerPath}/$fileName';
      File(targetPath).writeAsBytesSync(payload.signatureData!);
      results['signature'] = targetPath;
    } catch (_) {
      // silently skip signature if it fails
    }
  }
  
  return results;
}
