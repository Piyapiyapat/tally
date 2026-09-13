import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// PIN + biometric unlock for the app's local lock screen. The PIN lives in
/// OS-backed secure storage (Android Keystore / iOS Keychain) — never in
/// Hive alongside everything else, since it's the one credential in this
/// app that actually guards something.
class AppLockService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'app_lock_pin';
  static final _auth = LocalAuthentication();

  static Future<bool> hasPin() async =>
      (await _storage.read(key: _pinKey)) != null;

  static Future<void> setPin(String pin) async =>
      _storage.write(key: _pinKey, value: pin);

  static Future<void> clearPin() async => _storage.delete(key: _pinKey);

  static Future<bool> verifyPin(String pin) async =>
      (await _storage.read(key: _pinKey)) == pin;

  static Future<bool> biometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Tally',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
