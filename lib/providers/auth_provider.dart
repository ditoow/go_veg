import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:vegetables_app/config/user_preference.dart';

/// Provider autentikasi & RBAC sesuai dokumen pembagian proyek.
/// Saat ini menyinkronkan sesi Firebase Auth yang sudah dipakai FE,
/// dan siap disambungkan ke tabel `profiles` Supabase setelah BE-1 push.
class AuthProvider extends ChangeNotifier {
  final UserPreference _userPreference;

  AuthProvider(this._userPreference);

  String? _userId;
  String? _displayName;
  String? _email;
  String? _photoUrl;
  String _role = 'customer';

  User? get _firebaseUser =>
      Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

  String? get userId =>
      _userId ?? _firebaseUser?.uid ?? _userPreference.getUserId();
  String? get displayName =>
      _displayName ?? _firebaseUser?.displayName ?? _userPreference.getUserName();
  String? get email =>
      _email ?? _firebaseUser?.email ?? _userPreference.getUserEmail();
  String? get photoUrl => _photoUrl ?? _firebaseUser?.photoURL;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isAuthenticated => userId != null;

  void syncFromSession() {
    final user = _firebaseUser;
    _userId = user?.uid ?? _userPreference.getUserId();
    _displayName = user?.displayName ?? _userPreference.getUserName();
    _email = user?.email ?? _userPreference.getUserEmail();
    _photoUrl = user?.photoURL;
    notifyListeners();
  }

  void setRole(String role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
    await _userPreference.clearData();
    _userId = null;
    _displayName = null;
    _email = null;
    _photoUrl = null;
    _role = 'customer';
    notifyListeners();
  }
}
