import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseRoleService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  /// Check if user is admin
  Future<bool> isUserAdmin(String uid) async {
    try {
      final role = await getUserRole(uid);
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return [];

      final isAdmin = await isUserAdmin(currentUser.uid);
      if (!isAdmin) {
        throw Exception('Only admins can view all users');
      }

      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final isAdmin = await isUserAdmin(currentUser.uid);
      if (!isAdmin) {
        throw Exception('Only admins can update user role');
      }

      await _firestore.collection('users').doc(uid).update({
        'role': role,
        'roleUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Make user admin (admin only)
  Future<void> makeUserAdmin(String uid) async {
    await updateUserRole(uid, 'admin');
  }

  /// Revoke admin access (admin only)
  Future<void> revokeAdminAccess(String uid) async {
    await updateUserRole(uid, 'user');
  }

  /// Get user's permissions based on role
  Future<List<String>> getUserPermissions(String uid) async {
    try {
      final role = await getUserRole(uid);
      return _getRolePermissions(role ?? 'user');
    } catch (e) {
      return [];
    }
  }

  /// Define permissions for each role
  List<String> _getRolePermissions(String role) {
    switch (role) {
      case 'admin':
        return [
          'view_users',
          'edit_users',
          'delete_users',
          'manage_roles',
          'view_analytics',
          'manage_settings',
          'view_profiles',
          'edit_profiles',
          'approve_profiles',
        ];
      case 'moderator':
        return [
          'view_users',
          'view_analytics',
          'view_profiles',
          'approve_profiles',
        ];
      case 'user':
      default:
        return ['view_own_profile', 'edit_own_profile'];
    }
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String uid, String permission) async {
    try {
      final permissions = await getUserPermissions(uid);
      return permissions.contains(permission);
    } catch (e) {
      return false;
    }
  }
}
