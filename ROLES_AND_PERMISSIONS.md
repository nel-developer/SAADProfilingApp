# Firebase Role Management Setup Guide

## How to Create Roles in Firebase

There are two main ways to handle roles in Firebase:

### **Method 1: Using Firestore (RECOMMENDED) ✅**

This is what we've implemented. Roles are stored in each user document.

#### Step 1: Update User Document in Firestore

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `da-saad-profiling`
3. Go to **Firestore Database** → **Collections** → **users**
4. Find your user document
5. Click **Edit** and add a new field:
   - **Field name:** `role`
   - **Value:** `admin` (or `moderator`, `user`)
   - **Type:** String

**Example User Document:**
```json
{
  "uid": "user123",
  "email": "admin@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "admin",
  "createdAt": "2025-02-02T...",
  "accountStatus": "active"
}
```

#### Available Roles:
- `admin` - Full access to everything
- `moderator` - Can approve profiles, view analytics
- `user` - Regular user (default)

---

### **Step 2: Make Your Current User an Admin**

1. Open Firebase Console
2. Go to **Firestore** → **users** collection
3. Find your user account
4. Add/Update the `role` field to `admin`
5. Save

---

### **Method 2: Using Firebase Admin SDK (ADVANCED)**

If you want automated admin setup, use Firebase Admin SDK:

#### Install Firebase Admin SDK
```bash
npm install -g firebase-tools
```

#### Login to Firebase
```bash
firebase login
```

#### Create a script to set admin role
Create a file `set-admin.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setAdminRole(uid) {
  try {
    await admin.firestore().collection('users').doc(uid).update({
      role: 'admin'
    });
    console.log(`User ${uid} is now an admin!`);
  } catch (error) {
    console.error('Error:', error);
  }
}

// Replace 'USER_UID_HERE' with your actual user UID
setAdminRole('USER_UID_HERE');
```

Run it:
```bash
node set-admin.js
```

---

## How to Use Roles in Your App

### **1. Check User Role**

```dart
final roleService = FirebaseRoleService();
final isAdmin = await roleService.isUserAdmin(currentUser.uid);

if (isAdmin) {
  print('User is admin!');
}
```

### **2. Check Permissions**

```dart
final hasPermission = await roleService.hasPermission(
  currentUser.uid,
  'manage_roles'
);

if (hasPermission) {
  // Show admin features
}
```

### **3. Update User Role**

```dart
final roleService = FirebaseRoleService();

// Make someone an admin
await roleService.makeUserAdmin('user_uid_here');

// Remove admin access
await roleService.revokeAdminAccess('user_uid_here');
```

### **4. Get All Users (Admin Only)**

```dart
final roleService = FirebaseRoleService();
final allUsers = await roleService.getAllUsers();

for (var user in allUsers) {
  print('${user['firstName']} - Role: ${user['role']}');
}
```

---

## Firestore Security Rules

Protect your data with these security rules:

1. Go to **Firestore Database** → **Rules**
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Everyone can read their own profile
      allow read: if request.auth.uid == userId;
      
      // Only admins can read all users
      allow read: if isAdmin(request.auth.uid);
      
      // Users can update their own profile (except role)
      allow update: if request.auth.uid == userId 
                    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']);
      
      // Only admins can update roles
      allow update: if isAdmin(request.auth.uid);
      
      // Only self or admin can delete
      allow delete: if request.auth.uid == userId || isAdmin(request.auth.uid);
      
      // Only users can create their own documents (during registration)
      allow create: if request.auth.uid == userId;
    }
    
    // Helper function to check if user is admin
    function isAdmin(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.role == 'admin';
    }
  }
}
```

3. Click **Publish**

---

## Testing Your Setup

### **In the App:**

1. **Register/Login** with your account
2. In Firebase Console, set your user's role to `admin`
3. In your app, use:

```dart
final roleService = FirebaseRoleService();
final isAdmin = await roleService.isUserAdmin(FirebaseAuth.instance.currentUser!.uid);
print('Is Admin: $isAdmin');
```

---

## Quick Reference

| Role | Permissions |
|------|------------|
| **admin** | All permissions |
| **moderator** | View users, approve profiles, analytics |
| **user** | View/edit own profile |

---

## Troubleshooting

**Q: Role doesn't update immediately?**
- Firebase caches data. The app might need to refresh.
- Add this to reload: `await roleService.getUserRole(uid);`

**Q: Can't access admin features?**
- Check if `role` field exists in Firestore
- Verify the value is exactly `"admin"` (case-sensitive)
- Clear app cache and restart

**Q: Permission denied errors?**
- Check Firestore security rules
- Make sure your user UID matches in the rules
