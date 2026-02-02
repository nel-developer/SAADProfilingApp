import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSyncService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync a newly authenticated user with Firestore
  /// Call this right after user registers in Firebase Auth
  Future<void> syncUserToFirestore({
    required User authUser,
    required String firstName,
    required String middleName,
    required String lastName,
  }) async {
    try {
      await _firestore.collection('users').doc(authUser.uid).set({
        'uid': authUser.uid,
        'email': authUser.email,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'role': 'user', // Default role
        'accountStatus': 'pending_review',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('User synced to Firestore: ${authUser.uid}');
    } catch (e) {
      print('Error syncing user: $e');
      rethrow;
    }
  }

  /// Get Firestore user document by email
  Future<DocumentSnapshot?> getFirestoreUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }
      return null;
    } catch (e) {
      print('Error fetching user by email: $e');
      return null;
    }
  }

  /// Check if Auth user has matching Firestore document
  Future<bool> isUserSyncedWithFirestore(String authUid) async {
    try {
      final doc = await _firestore.collection('users').doc(authUid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all Auth users that are NOT in Firestore
  Future<List<String>> getUnsyncdAuthUsers() async {
    try {
      // Get all Firestore user UIDs
      final firestoreUsers =
          await _firestore.collection('users').get();
      final firestoreUids = firestoreUsers.docs.map((doc) => doc.id).toSet();

      // Get all Auth user UIDs
      final authUsers = await _firebaseAuth.listUsers(maxResults: 100);
      final unsyncedUids = <String>[];

      for (var authUser in authUsers.users) {
        if (!firestoreUids.contains(authUser.uid)) {
          unsyncedUids.add(authUser.uid);
        }
      }

      return unsyncedUids;
    } catch (e) {
      print('Error getting unsynced users: $e');
      return [];
    }
  }

  /// Sync unmatched Auth users to Firestore
  /// This creates Firestore documents for Auth users that don't have one
  Future<void> syncMissingAuthUsersToFirestore() async {
    try {
      final unsyncedUids = await getUnsyncdAuthUsers();

      for (var uid in unsyncedUids) {
        final authUser = _firebaseAuth.currentUser;
        
        // Get the auth user details
        final userRecord = _firebaseAuth.currentUser;
        if (userRecord != null && userRecord.uid == uid) {
          await _firestore.collection('users').doc(uid).set({
            'uid': uid,
            'email': userRecord.email,
            'firstName': 'Unknown',
            'middleName': '',
            'lastName': 'User',
            'role': 'user',
            'accountStatus': 'pending_review',
            'createdAt': FieldValue.serverTimestamp(),
            'syncedAt': FieldValue.serverTimestamp(),
          });
          print('Synced auth user to Firestore: $uid');
        }
      }
    } catch (e) {
      print('Error syncing missing users: $e');
      rethrow;
    }
  }

  /// Link an existing Firestore user to an Auth account
  /// Use this if you manually created Firestore users
  Future<void> linkFirestoreUserToAuth(
    String authUid,
    String email,
  ) async {
    try {
      // Find Firestore user by email
      final firestoreUser = await getFirestoreUserByEmail(email);

      if (firestoreUser == null) {
        throw Exception('No Firestore user found with email: $email');
      }

      // Update the Firestore document UID to match Auth UID
      await _firestore.collection('users').doc(authUid).set(
            {
              ...firestoreUser.data() as Map<String, dynamic>,
              'uid': authUid,
              'linkedAt': FieldValue.serverTimestamp(),
            },
          );

      // Delete the old document if UID was different
      if (firestoreUser.id != authUid) {
        await _firestore.collection('users').doc(firestoreUser.id).delete();
        print('Removed old duplicate user document');
      }

      print('Linked Firestore user to Auth: $authUid');
    } catch (e) {
      print('Error linking user: $e');
      rethrow;
    }
  }

  /// Get Firestore user by Auth UID
  Future<DocumentSnapshot?> getFirestoreUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      print('Error fetching Firestore user: $e');
      return null;
    }
  }

  /// Verify all users are synced (for debugging)
  Future<Map<String, dynamic>> verifyUserSync() async {
    try {
      final firestoreUsers = await _firestore.collection('users').get();
      final firestoreCount = firestoreUsers.docs.length;

      final authUsers = await _firebaseAuth.listUsers(maxResults: 100);
      final authCount = authUsers.users.length;

      final synced = <String>[];
      final unsynced = <String>[];

      // Check each auth user
      for (var authUser in authUsers.users) {
        final firestoreDoc = await getFirestoreUserByUid(authUser.uid);
        if (firestoreDoc != null && firestoreDoc.exists) {
          synced.add(authUser.uid);
        } else {
          unsynced.add(authUser.uid);
        }
      }

      return {
        'authCount': authCount,
        'firestoreCount': firestoreCount,
        'syncedCount': synced.length,
        'unsyncedAuthUids': unsynced,
        'isSynced': unsynced.isEmpty,
      };
    } catch (e) {
      print('Error verifying sync: $e');
      return {'error': e.toString()};
    }
  }
}
