# Offline-First Profiling Form - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    SAAD PROFILING APP                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
         ┌──────▼─────┐ ┌────▼──────┐ ┌───▼────────┐
         │ Step 1-8   │ │ProfilingFlow
         │   Forms    │ │ (Controller)│ │ Network   │
         │            │ │            │ │ Detector  │
         └────────────┘ └────┬───────┘ └───────────┘
                             │
                  ┌──────────┴────────────┐
                  │                       │
          ┌───────▼──────────┐  ┌────────▼────────┐
          │  ProfilingData   │  │ ProfilingStorage│
          │   (Model)        │  │     Service     │
          └──────────────────┘  └────────┬────────┘
                                         │
                         ┌───────────────┼───────────────┐
                         │               │               │
                 ┌───────▼────┐  ┌──────▼──────┐  ┌────▼─────────┐
                 │   Hive     │  │  Firestore  │  │ Connectivity │
                 │  (Local)   │  │   (Cloud)   │  │    Check     │
                 └────────────┘  └─────────────┘  └──────────────┘
```

## Data Flow Diagram

### User Offline
```
┌─────────────────┐
│  Open App       │
│  (Offline)      │
└────────┬────────┘
         │
    ┌────▼────────────────────┐
    │ ProfilingFlow.initState()│
    │  Load draft from Hive    │
    └────┬─────────────────────┘
         │
    ┌────▼──────────────┐
    │ Form pre-filled   │
    │ with saved data   │
    └────┬──────────────┘
         │
    ┌────▼────────────────────────────┐
    │ User fills Steps 1-8 (in memory) │
    │ (No network calls)               │
    └────┬───────────────────────────────┘
         │
         ├─────────────────────────────┐
         │                             │
    ┌────▼────────┐            ┌──────▼──────┐
    │ Save Draft  │            │   Submit    │
    │   Clicked   │            │   Clicked   │
    └────┬────────┘            └──────┬──────┘
         │                             │
    ┌────▼──────────────┐      ┌──────▼─────────────────┐
    │ saveDraftLocally()│      │ isOnline() → false     │
    │                  │      │ saveDraftLocally()      │
    │ Hive: Data saved │      │ Dialog: "Saved offline" │
    │ Snackbar: ✓      │      └────────────────────────┘
    └──────────────────┘
         │
         └──────────────────┐
                            │
                    ┌───────▼──────────┐
                    │ App closed       │
                    │ Data persists    │
                    │ in Hive ✓        │
                    └──────────────────┘
```

### User Online
```
┌─────────────────┐
│  Open App       │
│  (Online)       │
└────────┬────────┘
         │
    ┌────▼────────────────────┐
    │ ProfilingFlow.initState()│
    │  Load draft from Hive    │
    └────┬─────────────────────┘
         │
    ┌────▼──────────────┐
    │ Form pre-filled   │
    │ with saved data   │
    └────┬──────────────┘
         │
    ┌────▼────────────────────────────┐
    │ User fills Steps 1-8 (in memory) │
    │ (No network calls yet)           │
    └────┬───────────────────────────────┘
         │
         ├─────────────────────────────┐
         │                             │
    ┌────▼────────┐            ┌──────▼──────┐
    │ Save Draft  │            │   Submit    │
    │   Clicked   │            │   Clicked   │
    └────┬────────┘            └──────┬──────┘
         │                             │
    ┌────▼──────────────┐      ┌──────▼─────────────────┐
    │ saveDraftLocally()│      │ isOnline() → true      │
    │                  │      │ syncToFirestore()       │
    │ Hive: Data saved │      │                         │
    │ Snackbar: ✓      │      │ Firebase: Document +    │
    │                  │      │ Dialog: "Synced!" ✓     │
    └──────────────────┘      └────────────────────────┘
                                       │
                          ┌────────────┴──────────────┐
                          │                           │
                    ┌─────▼──────┐           ┌────────▼────┐
                    │ Hive       │           │ Firestore   │
                    │ Backup: ✓  │           │ Cloud: ✓    │
                    └────────────┘           └─────────────┘
```

### Data Structure

#### ProfilingData Model
```
ProfilingData {
  // Step 1: Personal
  firstName:      String
  middleName:     String? (optional)
  surname:        String
  extensionName:  String
  
  // Step 2: Address
  region:         String
  province:       String
  municipality:   String
  barangay:       String
  sitioPurok:     String
  dateOfBirth:    String
  sex:            String
  
  // Step 3: Other Personal
  isIndigenous:   bool
  indigenousGroup:String?
  isPWD:          bool
     maritalStatus:  (removed)
  spouseName:     String? (only if married)
  
  // Step 4: Commodity
  primaryCommodity: String
  secondaryCommodity: String
  ...
  
  // Step 5-7: Various fields...
  
  // Step 8: Signature
  idType:         String
  idFrontPhoto:   String (path)
  idBackPhoto:    String (path)
  farmerPhoto:    String (path)
  signature:      Uint8List
  
  // System
  updatedAt:      DateTime (auto-set on save)
}
```

#### Hive Storage Format
```
Key: "current_draft"
Value: {
  "firstName": "Juan",
  "surname": "Dela Cruz",
  ...
  "updatedAt": "2024-01-15T10:30:45.123456Z"
}
(Stored as JSON string)
```

#### Firestore Document Format
```
Collection: "profiling_forms"
Document ID: "user_id"

{
  firstName: "Juan",
  surname: "Dela Cruz",
  ...
  syncedAt: Timestamp(2024-01-15T10:30:45Z),
  userId: "user_id"
}
```

## ProfilingStorageService API

### Initialization
```dart
final storage = ProfilingStorageService();
await storage.init();  // Call once at app start
```

### Load Data
```dart
ProfilingData? draft = await storage.loadDraftLocally();
if (draft != null) {
  // Pre-fill form with draft data
}
```

### Save Data (Explicit)
```dart
await storage.saveDraftLocally(profilingData);
// Shows snackbar in ProfilingFlow
```

### Check Network
```dart
bool isOnline = await storage.isOnline();
if (isOnline) {
  await storage.syncToFirestore(profilingData, userId);
} else {
  // Show offline message
}
```

### Delete Draft
```dart
await storage.deleteDraftLocally();  // Local only
```

## Button UI Layout (Step 8)

```
┌────────────────────────────────────┐
│    Farmer's Signature              │
│    (form fields above)             │
│                                    │
│    [    SUBMIT BUTTON    ]  ← Orange, full width
│    [ Save Draft Button   ]  ← Green outline, full width
│    Back Link               ← Grey text link, centered
└────────────────────────────────────┘
```

## Validation Flow

### Before Next Button
```
Next button click
    ↓
If onValidate callback exists:
    ├─ Run validation async
    ├─ If fails: Show snackbar error
    └─ If passes: Call onNext()
Else: Call onNext() directly
```

### Current Validations
- **Step 1**: firstName, surname (extensionName is optional)
- **Step 2**: region, province, municipality, barangay, DOB, sex
- **Step 3**: indigenous status, marital status (spouse required if married)
- **Step 4**: primary/secondary commodities
- **Step 5**: family counts, years, commodities
- **Step 6**: income sources
- **Step 7**: farm income amounts
- **Step 8**: ID Type + both ID photos + farmer photo + signature

## Error Handling

### Try-Catch Blocks
```dart
try {
  await storage.saveDraftLocally(data);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
  );
}
```

### User Feedback
- ✅ Success: Green snackbar "Draft saved locally"
- ✅ Offline Dialog: "Saved locally. Will sync when online."
- ❌ Error: Red snackbar with error message

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| hive | ^2.2.3 | Local storage |
| hive_flutter | ^1.1.0 | Flutter integration |
| connectivity_plus | ^5.0.2 | Network detection |
| cloud_firestore | - | Cloud sync (existing) |
| firebase_auth | - | User auth (existing) |

## State Management Summary

**ProfilingFlow State**:
- `_currentStep`: int (1-8)
- `_currentData`: ProfilingData (holds all form data)
- `_storage`: ProfilingStorageService (manages Hive + Firestore)
- `_isLoading`: bool (true while initializing storage)

**No Redux/Provider needed** - Simple StatefulWidget is sufficient for this use case.

## Key Design Decisions

1. **Explicit Save Only** - User must click "Save Draft" button
   - Pro: No data loss from auto-saves, clear user control
   - Con: User might forget to save

2. **Offline-First** - Save locally first, sync to cloud
   - Pro: Works completely offline, fast local saves
   - Con: Requires sync reconciliation logic (not yet implemented)

3. **Single Draft** - Only one draft stored at a time
   - Pro: Simple, no version management
   - Con: Can't have multiple concurrent drafts

4. **No Auto-Sync Yet** - Manual sync on submit
   - Pro: Predictable, user understands when data goes to cloud
   - Con: Requires manual re-submit if network drops

---

**Status**: Complete, ready for field testing
**Next Enhancement**: Pre-fill form UI from ProfilingData
