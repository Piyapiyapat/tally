import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_lock_service.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/pin_pad.dart';

/// Blocks access to the rest of the app until the user enters their PIN (or
/// unlocks with biometrics, if enabled). Shown at startup when app lock is
/// on, and again after the app has been backgrounded for a while.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entered = '';
  String? _error;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (!DbService.getAppLockBiometricEnabled()) return;
    if (_checkingBiometric) return;
    if (!await AppLockService.biometricAvailable()) return;
    setState(() => _checkingBiometric = true);
    final ok = await AppLockService.authenticateBiometric();
    if (!mounted) return;
    setState(() => _checkingBiometric = false);
    if (ok) widget.onUnlocked();
  }

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == 4) _submit();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    final ok = await AppLockService.verifyPin(_entered);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 40, color: colors.accent),
                const SizedBox(height: 16),
                Text(
                  'Enter your PIN',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.deep,
                  ),
                ),
                const SizedBox(height: 24),
                PinDots(length: 4, filled: _entered.length),
                SizedBox(
                  height: 32,
                  child: _error == null
                      ? null
                      : Center(
                          child: Text(
                            _error!,
                            style: GoogleFonts.nunito(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                PinPad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  extraAction: DbService.getAppLockBiometricEnabled()
                      ? IconButton(
                          onPressed: _checkingBiometric ? null : _tryBiometric,
                          icon: Icon(Icons.fingerprint,
                              color: colors.accent, size: 28),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
