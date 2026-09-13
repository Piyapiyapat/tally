import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  VoidCallback? onDataSynced;

  AuthProvider() {
    _user = _authService.currentUser;
    SyncService.setUser(_user?.uid);

    _authService.authStateChanges.listen((user) async {
      _user = user;
      SyncService.setUser(user?.uid);
      notifyListeners();

      if (user != null) {
        _isSyncing = true;
        notifyListeners();
        try {
          await SyncService.mergeAndSyncAll();
          onDataSynced?.call();
        } finally {
          _isSyncing = false;
          notifyListeners();
        }
      }
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isGoogleUser => _authService.isGoogleUser;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email, password);
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] Sign-up failed: ${e.code} — ${e.message}');
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthProvider] Sign-in failed: ${e.code} — ${e.message}');
      _errorMessage = _mapError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] Google sign-in failed: $e');
      _errorMessage = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> resendVerificationEmail() async {
    await _authService.resendEmailVerification();
  }

  Future<void> refreshUser() async {
    await _authService.reloadUser();
    _user = _authService.currentUser;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await DbService.clearAllUserData();
    onDataSynced?.call();
  }

  /// ลบบัญชีถาวร: reauth -> ลบข้อมูลบน Firestore -> ลบ Firebase user -> ล้าง local
  /// คืนค่า null ถ้าสำเร็จ, คืนข้อความ error ถ้าไม่สำเร็จ
  Future<String?> deleteAccount({String? password}) async {
    _setLoading(true);
    try {
      if (isGoogleUser) {
        await _authService.reauthenticateWithGoogle();
      } else {
        if (password == null || password.isEmpty) {
          return 'Please enter your password to confirm.';
        }
        await _authService.reauthenticateWithPassword(password);
      }

      await SyncService.deleteAllCloudData();
      await _authService.deleteCurrentUser();
      await DbService.clearAllUserData();
      await AppLockService.clearPin();
      await DbService.setAppLockEnabled(false);
      await DbService.setAppLockBiometricEnabled(false);
      onDataSynced?.call();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to confirm this action.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}