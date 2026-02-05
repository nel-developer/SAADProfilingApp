# Image Storage Organization

## Overview
All profiling images are organized by farmer in separate folders on the device storage. This prevents mixing data from different farmers and keeps everything organized for local storage and later manual sync.

## Folder Structure

```
Phone Storage (External Storage)
└── SAADProfiling/
    ├── juan_dela_cruz_1738765432/
    │   ├── juan_dela_cruz_frontimage.jpg
    │   ├── juan_dela_cruz_backimage.jpg
    │   ├── juan_dela_cruz_profilepicture.jpg
    │   └── juan_dela_cruz_signature.png
    │
    ├── maria_santos_1738765433/
    │   ├── maria_santos_frontimage.jpg
    │   ├── maria_santos_backimage.jpg
    │   ├── maria_santos_profilepicture.jpg
    │   └── maria_santos_signature.png
    │
    └── pedro_reyes_1738765434/
        ├── pedro_reyes_frontimage.jpg
        ├── pedro_reyes_backimage.jpg
        ├── pedro_reyes_profilepicture.jpg
        └── pedro_reyes_signature.png
```

## File Naming Convention

Each farmer gets a unique folder with:
- **Folder Name Format**: `firstname_lastname_timestamp`
  - Example: `juan_dela_cruz_1738765432`
  - The timestamp ensures no duplicate folders for farmers with same name
  
- **Image Files**:
  - `{farmer_name}_frontimage.jpg` - ID Front Photo
  - `{farmer_name}_backimage.jpg` - ID Back Photo
  - `{farmer_name}_profilepicture.jpg` - Farmer's Profile Photo
  - `{farmer_name}_signature.png` - Digital Signature

## How It Works

### Step 1: Farmer Folder Creation
When Step 8 (Signature) starts, a unique folder is created:
```dart
farmer_folder_name = imageStorage.generateFarmerFolderName(firstName, lastName);
// Output: "juan_dela_cruz_1738765432"
```

### Step 2: Image Capture & Storage
When user captures images:
1. **ID Front**: `await imageStorage.saveIdFrontImage(file, farmerFolderName)`
2. **ID Back**: `await imageStorage.saveIdBackImage(file, farmerFolderName)`
3. **Profile**: `await imageStorage.saveProfilePicture(file, farmerFolderName)`
4. **Signature**: `await imageStorage.saveSignature(bytes, farmerFolderName)`

All images are automatically saved to the farmer's unique folder.

### Step 3: Data Structure
The `ProfilingData` model stores:
```dart
String? farmerFolderName;        // "juan_dela_cruz_1738765432"
String? idFrontImagePath;        // Full path to front image
String? idBackImagePath;         // Full path to back image
String? farmerPhotoPath;         // Full path to profile photo
String? signatureImagePath;      // Full path to signature
```

## Data Isolation (Important!)

Each farmer's data is **completely isolated**:
- Different farmers = Different folders ✅
- Images auto-organized by farmer name ✅
- No risk of mixing data from multiple profiles ✅
- Each folder contains only that farmer's 4 images ✅

## Manual Sync (Later)

When syncing to Firebase:
1. Load all farmer folders: `getAllFarmerFolders()`
2. For each farmer, retrieve images: `getFarmerImages(farmerFolderName)`
3. Attach image paths to profiling data
4. Upload to Firestore with folder reference

## Storage Location

Images are saved to Android's external storage:
```
/storage/emulated/0/SAADProfiling/
```

Or automatically handled by `getExternalStorageDirectory()` on different devices.

## Available Service Methods

### ImageStorageService API

```dart
// Generate folder name
String generateFarmerFolderName(String firstName, String lastName, {String? uniqueId})

// Save individual images
Future<String> saveIdFrontImage(File imageFile, String farmerFolderName)
Future<String> saveIdBackImage(File imageFile, String farmerFolderName)
Future<String> saveProfilePicture(File imageFile, String farmerFolderName)
Future<String> saveSignature(Uint8List imageData, String farmerFolderName)

// Retrieve images
Future<Map<String, String>> getFarmerImages(String farmerFolderName)

// List all farmers
Future<List<String>> getAllFarmerFolders()

// Cleanup
Future<bool> deleteFarmerFolder(String farmerFolderName)

// Storage info
Future<int> getFarmerFolderSize(String farmerFolderName)
Future<bool> imageExists(String imagePath)
```

## Example Flow

```dart
// Step 8 starts
final imageStorage = ImageStorageService();

// Create farmer folder
String farmerFolder = imageStorage.generateFarmerFolderName("Juan", "Dela Cruz");
// Result: "juan_dela_cruz_1738765432"

// Take ID Front
File idFront = ...;
String frontPath = await imageStorage.saveIdFrontImage(idFront, farmerFolder);
// Saved to: /SAADProfiling/juan_dela_cruz_1738765432/juan_dela_cruz_frontimage.jpg

// Take ID Back
File idBack = ...;
String backPath = await imageStorage.saveIdBackImage(idBack, farmerFolder);
// Saved to: /SAADProfiling/juan_dela_cruz_1738765432/juan_dela_cruz_backimage.jpg

// Take Profile Photo
File profile = ...;
String profilePath = await imageStorage.saveProfilePicture(profile, farmerFolder);
// Saved to: /SAADProfiling/juan_dela_cruz_1738765432/juan_dela_cruz_profilepicture.jpg

// Save Signature
Uint8List signature = ...;
String sigPath = await imageStorage.saveSignature(signature, farmerFolder);
// Saved to: /SAADProfiling/juan_dela_cruz_1738765432/juan_dela_cruz_signature.png

// Store in ProfilingData
profiling.farmerFolderName = farmerFolder;
profiling.idFrontImagePath = frontPath;
profiling.idBackImagePath = backPath;
profiling.farmerPhotoPath = profilePath;
profiling.signatureImagePath = sigPath;

// Save locally to Hive
await storage.saveDraftLocally(profiling);
```

## Security & Privacy

✅ Each farmer's images are in a separate folder
✅ Naming convention uses farmer's name for easy identification
✅ Timestamp prevents folder name collisions
✅ No automatic deletion - manual control only
✅ Ready for manual sync to database when needed

## Future: Manual Sync to Firestore

When user wants to sync:
```dart
// 1. Get all farmer folders
List<String> allFarmers = await imageStorage.getAllFarmerFolders();

// 2. For each farmer, get their images
for (String farmer in allFarmers) {
    Map<String, String> images = await imageStorage.getFarmerImages(farmer);
    // Images contain: idFront, idBack, profile, signature paths
    
    // 3. Upload to Firebase (manual sync - not automatic)
    // This will be implemented later by user
}
```

---

**Summary**: Images are well-organized in farmer-specific folders, preventing data mixing. Ready for local storage and future manual database sync.
