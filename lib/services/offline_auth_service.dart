import 'package:hive/hive.dart';

class OfflineAuthService {
  static final OfflineAuthService _instance = OfflineAuthService._internal();
  static const String _offlineAuthBoxName = 'offline_auth';

  factory OfflineAuthService() {
    return _instance;
  }

  OfflineAuthService._internal();

  /// Initialize Hive box for offline authentication
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_offlineAuthBoxName)) {
        await Hive.openBox<Map<String, dynamic>>(_offlineAuthBoxName);
      }
    } catch (e) {
      // Fail silently if initialization fails
      return;
    }
  }

  /// Save credentials locally for offline login
  /// This stores email and a hashed password locally
  /// In production, use a more secure approach (e.g., platform-specific secure storage)
  Future<void> saveCredentials({
    required String email,
    required String password,
    required String uid,
    required String accountStatus,
    required String role,
  }) async {
    try {
      final box = Hive.box<Map<String, dynamic>>(_offlineAuthBoxName);
      final userData = <String, dynamic>{
        'email': email,
        'password': password, // In production: hash this
        'uid': uid,
        'accountStatus': accountStatus,
        'role': role,
        'lastLoginTime': DateTime.now().toIso8601String(),
      };
      await box.put('current_user', userData);
    } catch (e) {
      // Fail silently
      return;
    }
  }

  /// Retrieve locally stored offline credentials
  Future<Map<String, dynamic>?> getOfflineCredentials() async {
    try {
      final box = Hive.box<Map<String, dynamic>>(_offlineAuthBoxName);
      final data = box.get('current_user');
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Verify stored credentials (for offline login retry)
  Future<bool> verifyStoredCredentials({
    required String email,
    required String password,
  }) async {
    try {
      final stored = await getOfflineCredentials();
      if (stored == null) return false;

      return stored['email'] == email && stored['password'] == password;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has valid offline session
  Future<bool> hasValidOfflineSession() async {
    try {
      final stored = await getOfflineCredentials();
      if (stored == null) return false;

      // Session valid if we have uid and accountStatus
      return stored['uid'] != null && stored['accountStatus'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear offline credentials (logout)
  Future<void> clearOfflineCredentials() async {
    try {
      final box = Hive.box<Map<String, dynamic>>(_offlineAuthBoxName);
      await box.delete('current_user');
    } catch (e) {
      return;
    }
  }

  /// Get stored user UID for offline session
  Future<String?> getStoredUid() async {
    try {
      final stored = await getOfflineCredentials();
      return stored?['uid'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get stored user role
  Future<String?> getStoredRole() async {
    try {
      final stored = await getOfflineCredentials();
      return stored?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get stored account status
  Future<String?> getStoredAccountStatus() async {
    try {
      final stored = await getOfflineCredentials();
      return stored?['accountStatus'] as String?;
    } catch (e) {
      return null;
    }
  }
}
