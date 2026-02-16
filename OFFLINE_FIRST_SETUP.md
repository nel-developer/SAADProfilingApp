# Offline-First Profiling Form Setup

## Overview
The profiling form now supports **offline-first** functionality using **Hive** for local storage and **Firestore** for cloud sync. Users can fill out the form without internet, save explicitly with a button click, and the data syncs to the cloud when online.

## Architecture

### Storage Stack
1. **Hive** - Local offline storage (persistent)
2. **Cloud Firestore** - Cloud backend (synced when online)
3. **connectivity_plus** - Network status detection

### Data Flow
```
User fills form (Steps 1-8)
    ↓
User clicks "Save Draft" → ProfilingStorageService.saveDraftLocally()
    ↓ (Data stored in Hive)
    ↓
User clicks "Submit" 
    ↓
Check if online?
    → YES: syncToFirestore() + upload
    → NO: saveDraftLocally() + show offline message
```

## Key Components

### 1. ProfilingData Model (`lib/models/profiling_data.dart`)
Complete data model holding all 8 profiling steps' fields:
- **Step 1**: firstName, middleName, surname, extension
- **Step 2**: region, province, municipality, barangay, sitio, dateOfBirth, sex
- **Step 3**: indigenousStatus, pwdStatus, spouseName
- **Step 4**: primaryCommodities, secondaryCommodities, othersText
- **Step 5**: familyCount, yearsInFarming, tenureship, comoditiesGrown, yearCovered
- **Step 6**: incomeSources (4 fields)
- **Step 7**: farmIncomeData (amounts & remarks)
- **Step 8**: idType, idFrontPhoto, idBackPhoto, farmerPhoto, signature

**Key Methods**:
- `toJson()` - Convert to JSON for Hive storage
- `fromJson()` - Hydrate from stored JSON
- `toFirestore()` - Convert to Firestore document format

### 2. ProfilingStorageService (`lib/services/profiling_storage_service.dart`)
Service that manages local storage and cloud sync:

**Methods**:
- `init()` - Initialize Hive box (call once on app startup)
- `saveDraftLocally(ProfilingData)` - Explicit save to Hive (user-triggered only)
- `loadDraftLocally()` - Load previously saved draft from Hive
- `deleteDraftLocally()` - Clear saved draft
- `isOnline()` - Check current network connectivity
- `syncToFirestore(ProfilingData, userId)` - Upload to Firestore when online
- `deleteDraftFromFirestore(userId)` - Delete remote copy after upload

### 3. ProfilingFlow (`lib/screens/profiling/profiling_step_wrapper.dart`)
Main flow controller that manages:
- **Initialization**: Load existing draft from Hive on app start
- **State Management**: Hold `ProfilingData` instance across all 8 steps
- **Save Draft**: Explicit save via button (Step 8 only)
- **Submit**: Check connectivity → sync online or save offline

**Key Methods**:
- `_initializeStorage()` - Load draft on startup
- `_saveDraft()` - User-triggered local save (with snackbar feedback)
- `_submitForm()` - Final submission (online = sync, offline = save + message)

### 4. Step08Signature Updates
Added `onSaveDraft` callback parameter to enable explicit save button access.

### 5. ProfilingStepWrapper UI Changes
- Added green "Save Draft" button (Step 8 only)
- Styled with green border + outline format to differentiate from orange Submit button
- Button appears between Submit and Back buttons

## Dependencies Added
```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.2
```

## User Experience

### Scenario 1: Online User
1. Fill all 8 steps of profiling form
2. Click "Save Draft" → Data saved locally + snackbar "Draft saved locally"
3. Click "Submit" → Detected online → Syncs to Firestore → Shows success dialog

### Scenario 2: Offline User
1. Fill all 8 steps of profiling form
2. Click "Save Draft" → Data saved locally + snackbar "Draft saved locally"
3. Click "Submit" → Detected offline → Saves locally → Shows offline dialog
4. Later when online → Data auto-syncs to Firestore (if auto-sync feature added)

### Scenario 3: Resume Saved Draft
1. App launches → Loads saved draft from Hive
2. Form pre-fills with previous data (future enhancement: populate UI from ProfilingData)
3. User can edit and save again

## Future Enhancements

1. **Pre-fill Forms from ProfilingData**
   - On step init, load values from `_currentData` and populate UI controllers
   - On step next, collect current form values into `_currentData`

2. **Auto-Sync to Firestore**
   - Listen to connectivity changes: `_connectivity.onConnectivityChanged`
   - When online, automatically call `syncToFirestore()`
   - Show toast: "Form synced to cloud"

3. **Image Storage**
   - Currently storing image paths as strings only
   - Could enhance to base64 encode images or store in app cache directory

4. **Offline Indicator Badge**
   - Display badge in header when offline
   - Show sync status when syncing

5. **Validation Across Steps**
   - Validate required fields before allowing save/submit
   - Highlight missing fields in each step

## Testing Checklist

- [ ] Fill form offline → Save Draft button works
- [ ] Fill form offline → Submit → Shows offline message & saves locally
- [ ] Load app → Previously saved draft loads from Hive
- [ ] Fill form online → Submit → Syncs to Firestore
- [ ] Check Firestore documents → Data correctly stored
- [ ] Turn off network mid-form → Can still navigate steps
- [ ] Save Draft multiple times → Latest version overwrites

## Code Patterns

### Using ProfilingStorageService in a Step
```dart
// Service initialized in ProfilingFlow
final _storage = ProfilingStorageService();

// Load draft on init
ProfilingData? draft = await _storage.loadDraftLocally();

// Update data from step
_currentData.firstName = firstNameController.text;

// Save when user clicks Save Draft (handled by ProfilingFlow)
await _storage.saveDraftLocally(_currentData);

// Sync to Firestore when online
if (await _storage.isOnline()) {
  await _storage.syncToFirestore(_currentData, userId);
}
```

## Files Modified
- `pubspec.yaml` - Added hive, hive_flutter, connectivity_plus
- `lib/models/profiling_data.dart` - NEW: Complete model for all 8 steps
- `lib/services/profiling_storage_service.dart` - NEW: Hive + Firestore sync service
- `lib/screens/profiling/profiling_step_wrapper.dart` - Added storage init, save/submit logic, Save Draft button
- `lib/screens/profiling/step_08_signature.dart` - Added onSaveDraft parameter

## Notes
- **No auto-save per step** - Only explicit save when user clicks "Save Draft"
- **Supports offline workflows** - Can use app completely offline
- **Smart sync** - Only syncs to Firestore when online
- **User has control** - All saves are explicit user actions
