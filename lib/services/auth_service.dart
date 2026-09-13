import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  static const String _webClientId =
      '681803928165-m34sts64d4v2ub6faufqpvjfrhs9dfp8.apps.googleusercontent.com';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _googleSignInInitialized = true;
  }

  // ── Email / Password ────────────────────────────────────
  Future<UserCredential> signUpWithEmail(
      String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.sendEmailVerification();
    return credential;
  }

  Future<UserCredential> signInWithEmail(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ── Google ──────────────────────────────────────────────
  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ── Reauthentication (จำเป็นก่อนลบบัญชี) ─────────────────
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    final user = _auth.currentUser;
    if (user == null) return;

    // ลองดึงบัญชีที่ล็อกอินค้างอยู่แบบเงียบๆ ก่อน (ไม่โชว์ picker)
    var googleUser = await _googleSignIn.attemptLightweightAuthentication();

    // ถ้า silent auth ได้บัญชีมา แต่ไม่ตรงกับบัญชีที่ login Firebase อยู่
    // (เช่น เครื่องมีหลายบัญชี Google) ให้ถือว่าใช้ไม่ได้ ต้องโชว์ picker แทน
    if (googleUser != null && googleUser.email != user.email) {
      googleUser = null;
    }

    // silent auth ไม่สำเร็จ (session หมดอายุ หรือ email ไม่ตรง) ค่อย fallback
    // ไปโชว์ picker ให้เลือกเอง
    googleUser ??= await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  // ── Delete account ──────────────────────────────────────
  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete();
  }

  // ── Sign out ──────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInInitialized) {
      await _googleSignIn.signOut();
    }
  }
}