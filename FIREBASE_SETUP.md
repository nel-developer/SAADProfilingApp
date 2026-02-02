# Firebase Setup Guide for Flutter

This guide will help you set up Firebase Authentication and Firestore for your SAADProfilingApp.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter your project name (e.g., "SAADProfilingApp")
4. Select your country and click "Create project"
5. Wait for the project to be created, then click "Continue"

## Step 2: Enable Authentication

1. In the Firebase Console, go to **Build** > **Authentication**
2. Click "Get started"
3. Select **Email/Password** as the sign-in method
4. Enable it and click "Save"

## Step 3: Create Firestore Database

1. Go to **Build** > **Firestore Database**
2. Click "Create database"
3. Select **Start in production mode**
4. Choose your region and click "Create"

## Step 4: Set Firestore Security Rules

1. In Firestore, go to **Rules** tab
2. Replace the default rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
    }
  }
}
```

3. Click "Publish"

## Step 5: Get Firebase Configuration

### For Android:

1. In Firebase Console, click the settings icon and go to **Project settings**
2. Click **Android** app
3. Enter your package name (default: `com.example.da_project_1`)
4. Follow the setup wizard to download `google-services.json`
5. Place the file in: `android/app/google-services.json`

### For iOS:

1. In Firebase Console, click **iOS** app
2. Enter your iOS bundle ID (usually matches Android package name)
3. Download `GoogleService-Info.plist`
4. Drag and drop into Xcode under **Runner** folder

### For Web (Optional):

1. In Firebase Console, click **Web** app
2. Copy the Firebase config object
3. Create file `lib/firebase_config_web.dart` with your config

## Step 6: Update firebase_options.dart

After downloading your configuration files:

1. Open `lib/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase credentials:
   - `apiKey`
   - `appId`
   - `projectId`
   - `messagingSenderId`
   - `databaseURL`
   - `storageBucket`

### Finding Your Credentials:

**For Android (from google-services.json):**
- Open `android/app/google-services.json`
- Find values in the JSON under `project_info` and `client` sections

**For iOS (from GoogleService-Info.plist):**
- Right-click the plist file > Open As > Source Code
- Find the values in the XML

**Firebase Console:**
- Go to **Project Settings** to find your:
  - Project ID
  - API Key
  - Messaging Sender ID
  - Database URL
  - Storage Bucket

## Step 7: Install Dependencies

Run in your project terminal:

```bash
flutter pub get
```

## Step 8: Test Your Setup

1. Run your app:
   ```bash
   flutter run
   ```

2. Try registering a new account
3. Check Firebase Console > Authentication to see if users are created
4. Check Firestore Database to see user data stored

## Troubleshooting

### "Firebase app not initialized"
- Make sure you called `Firebase.initializeApp()` in `main.dart`

### Authentication errors
- Check your Firebase project has Email/Password auth enabled
- Verify credentials in `firebase_options.dart` are correct

### Firestore write errors
- Check Security Rules allow your user
- Verify user is authenticated before writing

### Android issues
- Make sure `google-services.json` is in the correct location
- Run: `flutter clean` and `flutter pub get`

## File Structure

After setup, your project should have:

```
lib/
├── firebase_options.dart      (← Configure with your credentials)
├── services/
│   └── firebase_auth_service.dart
├── screens/
│   └── auth/
│       ├── login_screen.dart  (← Uses Firebase auth)
│       └── register_screen.dart (← Uses Firebase auth)
└── main.dart                  (← Firebase initialized here)
```

## Next Steps

Your login and register screens are now connected to Firebase! The app will:

1. **On Register**: Create a user in Firebase Auth and store their profile in Firestore
2. **On Login**: Authenticate the user via Firebase Auth
3. **Error Handling**: Show user-friendly error messages

You can extend this by:
- Adding password reset functionality
- Email verification
- Profile updates
- Account deletion

Happy coding! 🚀
