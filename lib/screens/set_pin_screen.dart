import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_lock_service.dart';
import '../theme/app_colors.dart';
import '../widgets/pin_pad.dart';

/// Two-step PIN creation: enter, then confirm. Pops `true` once a matching
/// PIN has been saved, `false`/null if the user backs out.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _first = '';
  String _entered = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length == 4) _handleComplete();
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _first = _entered;
        _entered = '';
        _confirming = true;
      });
      return;
    }
    if (_entered == _first) {
      await AppLockService.setPin(_entered);
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _error = "PINs didn't match — try again";
        _first = '';
        _entered = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.deep, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Set a PIN',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _confirming ? 'Confirm your PIN' : 'Create a 4-digit PIN',
                style: GoogleFonts.nunito(
                  fontSize: 16,
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
              PinPad(onDigit: _onDigit, onBackspace: _onBackspace),
            ],
          ),
        ),
      ),
    );
  }
}
