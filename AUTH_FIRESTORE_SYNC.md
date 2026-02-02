# Firebase Authentication & Firestore Sync Guide

## The Problem

You have:
1. **Firebase Authentication** - Users created here have a `UID`
2. **Firestore Collection** - User documents created manually with their own `UID` (or email-based ID)

They're not connected because the **UIDs don't match**!

---

## The Solution

### **Option 1: Correct Way (Going Forward) ✅ RECOMMENDED**

When a user registers, they're automatically created in BOTH Auth and Firestore with the **same UID**.

This is already built into your `firebase_auth_service.dart`:

```dart
// This creates in Auth AND Firestore with same UID
await _authService.registerWithEmailPassword(
  email: email,
  password: password,
  firstName: firstName,
  middleName: middleName,
  lastName: lastName,
);
```

**Your registration flow already does this correctly!** ✅

---

### **Option 2: Fix Existing Mismatched Users**

If you manually created Firestore users and now have Auth accounts with different UIDs:

#### **Step 1: Check What's Mismatched**

Create a debug screen to see what's unsynced:

```dart
final syncService = FirebaseSyncService();
final syncStatus = await syncService.verifyUserSync();

print('Auth users: ${syncStatus['authCount']}');
print('Firestore users: ${syncStatus['firestoreCount']}');
print('Synced: ${syncStatus['syncedCount']}');
print('Unsynced: ${syncStatus['unsyncedAuthUids']}');
```

#### **Step 2: Link Them Manually**

If a user is in Auth but not in Firestore, link them:

```dart
final syncService = FirebaseSyncService();

// Get the current logged-in user
final authUser = FirebaseAuth.instance.currentUser;

if (authUser != null) {
  await syncService.linkFirestoreUserToAuth(
    authUser.uid,
    authUser.email!,
  );
}
```

---

## **How to Manually Fix in Firebase Console**

If you need to fix it manually:

### **For Users Manually Created in Firestore:**

1. Go to Firebase Console → **Firestore Database** → **users** collection
2. Find the user document you created manually
3. **Delete it** (if it has wrong ID)
4. Go to **Authentication** tab
5. Find that user
6. **Copy their UID**
7. Go back to **Firestore** → **users** collection
8. **Create new document** with ID = copied UID
9. Add the user data:

```json
{
  "uid": "PASTE_AUTH_UID_HERE",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "user",
  "accountStatus": "active",
  "createdAt": {"_seconds": 1706860800}
}
```

---

## **Understanding UIDs**

**Firebase Authentication UID:** (Example)
```
pXN4b6hZ9kQ2mL8wZ3yJ5xK9
```

**Firestore Document ID:** Must match Auth UID
```
pXN4b6hZ9kQ2mL8wZ3yJ5xK9  ← Same as Auth UID
```

**Why it matters:**
- When you login → Auth generates a UID
- Your app queries Firestore using that same UID
- If they don't match → User data isn't found!

---

## **Quick Checklist**

- [ ] Auth account created? Check **Authentication** tab
- [ ] UID from Auth copied?
- [ ] Firestore document has same UID? Check document ID
- [ ] Email matches? (in both places)
- [ ] Login works? Try logging in

---

## **Code: Properly Create New Users**

**Register Flow (CORRECT):**

```dart
// This handles BOTH Auth + Firestore
await _authService.registerWithEmailPassword(
  email: email,
  password: password,
  firstName: firstName,
  middleName: middleName,
  lastName: lastName,
);

// Auth user created ✅
// Firestore user created with same UID ✅
// They're synced! ✅
```

**Login Flow:**

```dart
// This only uses Auth
await _authService.loginWithEmailPassword(
  email: email,
  password: password,
);

// After successful login, get the UID
final currentUser = FirebaseAuth.instance.currentUser;
final uid = currentUser!.uid;

// Then fetch from Firestore using that UID
final userData = await _authService.getUserData(uid);
```

---

## **Troubleshooting**

### **"User not found after login"**
- ✅ Check if Firestore document exists with Auth UID
- ✅ Verify the document ID matches the Auth UID exactly
- ✅ Check collection name is `users` (case-sensitive)

### **"Duplicate users"**
- ✅ You have same user in both Auth and Firestore with different IDs
- ✅ Use `FirebaseSyncService` to link them
- ✅ Delete the old Firestore document

### **"Can't login after registration"**
- ✅ Make sure `registerWithEmailPassword` completes fully
- ✅ Check Firestore document was created
- ✅ Verify no errors in console logs

---

## **Summary**

| Scenario | Solution |
|----------|----------|
| New user registering | Use `registerWithEmailPassword` (already handles both) |
| Already have Auth user, need Firestore sync | Use `FirebaseSyncService.linkFirestoreUserToAuth()` |
| Check if synced | Use `FirebaseSyncService.verifyUserSync()` |
| Manual fix needed | Copy Auth UID → Create Firestore doc with same ID |

**Your registration is already correct!** Just make sure to use it for new users. 🎉
