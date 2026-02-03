# Account Approval Flow Documentation

## Overview
This document describes the complete account lifecycle flow from registration to approval and access.

## Account States
1. **pending_review** - New account waiting for admin approval
2. **approved** - Account approved by admin with assigned role
3. **rejected** - Account rejected by admin

## User Journey

### 1. Registration Flow
**File:** `lib/screens/auth/register_screen.dart`

- User fills in: firstName, middleName, lastName, email, password
- On submission:
  - `FirebaseAuthService.registerWithEmailPassword()` is called
  - User is created in Firebase Auth
  - Firestore document created with:
    - `accountStatus: 'pending_review'`
    - `role: 'user'` (default)
    - `createdAt: serverTimestamp()`
  - User is routed to `AccountUnderReviewScreen`

### 2. Account Under Review Screen
**File:** `lib/screens/auth/account_under_review_screen.dart`

- Shows message: "Your account is under review by admin"
- Starts a Timer that polls every 3 seconds:
  - Checks current user's `accountStatus` in Firestore
  - If `accountStatus == 'approved'`:
    - Timer is cancelled
    - Navigates to home/dashboard (`AppRoutes.home`)
  - If `accountStatus == 'rejected'`:
    - User sees rejection message (can be implemented)
  - Otherwise: Continues waiting

### 3. Login Flow
**File:** `lib/screens/auth/login_screen.dart`

After successful email/password login:
- Checks user's `accountStatus` in Firestore:
  - **pending_review** → Routes to `AccountUnderReviewScreen`
  - **approved** → Routes to home/dashboard
  - **rejected** → Signs out user and shows error

### 4. Admin Approval Screen
**File:** `lib/screens/accounts/accounts_screen.dart`

Admin features:
- Default filter: "Pending" (shows `accountStatus == 'pending_review'`)
- For each pending account, admin can:
  - **Accept** → Opens `AccountRoleModal` to select role (admin, profiler, moderator, user)
    - Calls: `FirebaseAuthService.approveUserWithRole(uid, role)`
    - Sets: `accountStatus: 'approved'` + `role: selectedRole`
  - **Decline** → Calls `FirebaseAuthService.rejectUser(uid, reason)`
    - Sets: `accountStatus: 'rejected'`
  - **Edit** (for approved accounts) → Update existing role
    - Calls: `FirebaseAuthService.updateUserRole(uid, newRole)`

## Database Schema

### Users Collection
```dart
{
  uid: 'user_id',
  email: 'user@example.com',
  firstName: 'John',
  middleName: 'Patrick',
  lastName: 'Doe',
  role: 'user' | 'admin' | 'profiler' | 'moderator',  // Single canonical role
  accountStatus: 'pending_review' | 'approved' | 'rejected',
  createdAt: serverTimestamp(),
  approvedAt: serverTimestamp(),  // Set when approved
  roleUpdatedAt: serverTimestamp(),  // Set when role changes
  rejectionReason: 'optional reason string',  // If rejected
}
```

## Key Services

### FirebaseAuthService
**Location:** `lib/services/firebase_auth_service.dart`

Key methods:
- `registerWithEmailPassword()` - Register new user
- `loginWithEmailPassword()` - Login user
- `getUserData(uid)` - Fetch user document
- `approveUserWithRole(uid, role)` - Admin approves user with role
- `rejectUser(uid, reason)` - Admin rejects user
- `updateUserRole(uid, newRole)` - Update approved user's role
- `getPendingUsers()` - Get all pending accounts for admin
- `getUserRole(uid)` - Get user's current role

## Important Notes

### No Redundant Fields
- **Single `role` field only** - Not `role` + `roles` array
- On registration: Creates `role: 'user'` (not a `roles` array)
- Methods handle missing `roles` array gracefully

### Polling vs Listeners
- `AccountUnderReviewScreen` uses Timer polling (every 3 seconds)
- Alternative: Could use Firestore listeners for real-time updates
- Current implementation chosen for simplicity

### Admin Route Protection
- MainScaffold/app routing should verify user's `role == 'admin'` before showing admin screens
- Firestore rules can enforce: Only `role: 'admin'` can access admin features

### Custom Claims (Optional)
- For additional security, custom claims `admin: true` can be set server-side
- Current implementation uses Firestore `role` field for simpler client-side checks
- Node.js admin script provided for setting custom claims if needed

## Testing Flow

1. **Register new user** → Should see "Account Under Review" screen
2. **Open admin account in new browser** → Should see pending user in AccountsScreen
3. **Admin clicks "Accept"** → Opens role selector
4. **Admin selects role** → User's `accountStatus` changes to "approved"
5. **User's polling detects approval** → Auto-navigates to dashboard
6. **User logs in** → Should route to dashboard (not under review)

## Future Enhancements

- Firestore listener instead of Timer polling for real-time updates
- Email notifications when account is approved/rejected
- Admin notes/comments on account approvals
- Account suspension/deactivation features
- Role expiration with renewal required
