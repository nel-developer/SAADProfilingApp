import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Register with email and password
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    required String firstName,
    required String middleName,
    required String lastName,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Store user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'createdAt': FieldValue.serverTimestamp(),
        'accountStatus': 'pending_review', // Default status
        'role': 'user', // Default role - will be updated on approval
        'roles': [], // List of roles: 'admin', 'moderator', 'profiler'
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getErrorMessage(e.code),
      );
    } catch (e) {
      // Catch Firestore errors (permission denied, network issues, etc.)
      throw Exception('Registration failed: $e. Please try again.');
    }
  }

  /// Login with email and password
  Future<UserCredential?> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getErrorMessage(e.code),
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get error message from Firebase error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email address is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if user email is verified
  bool isEmailVerified() {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  /// Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Assign role to user (admin only)
  /// Roles: 'admin', 'moderator', 'profiler'
  Future<void> assignRole(String uid, String role) async {
    try {
      // Get current roles
      final userDoc = await _firestore.collection('users').doc(uid).get();
      List<String> roles = List<String>.from(userDoc['roles'] ?? []);

      // Add role if not already present
      if (!roles.contains(role)) {
        roles.add(role);
      }

      // Update user document
      await _firestore.collection('users').doc(uid).update({
        'roles': roles,
        'role': role, // Set as primary role
      });
    } catch (e) {
      throw Exception('Failed to assign role: $e');
    }
  }

  /// Approve user and assign role
  Future<void> approveUserWithRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'approved',
        'role': role,
        'roles': [role],
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve user: $e');
    }
  }

  /// Reject user account
  Future<void> rejectUser(String uid, String reason) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject user: $e');
    }
  }

  /// Get all pending users (for admin approval)
  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('accountStatus', isEqualTo: 'pending_review')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending users: $e');
    }
  }

  /// Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get user roles list
  Future<List<String>> getUserRoles(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return List<String>.from(doc['roles'] ?? []);
    } catch (e) {
      return [];
    }
  }
}
