import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';

enum _PwStrength { tooShort, weak, fair, good, strong, veryStrong }

extension on _PwStrength {
  String get label => switch (this) {
        _PwStrength.tooShort => 'Too short (min. 8 characters)',
        _PwStrength.weak => 'Weak',
        _PwStrength.fair => 'Fair',
        _PwStrength.good => 'Good',
        _PwStrength.strong => 'Strong',
        _PwStrength.veryStrong => 'Very strong',
      };

  // Out of 5 segments in the strength bar.
  int get filledSegments => switch (this) {
        _PwStrength.tooShort => 0,
        _PwStrength.weak => 1,
        _PwStrength.fair => 2,
        _PwStrength.good => 3,
        _PwStrength.strong => 4,
        _PwStrength.veryStrong => 5,
      };

  // Good, Strong and Very strong are all acceptable — a password doesn't
  // need every character class to be usable, just "good enough".
  bool get isAcceptable => index >= _PwStrength.good.index;
}

_PwStrength _passwordStrength(String password) {
  if (password.length < 8) return _PwStrength.tooShort;
  var score = 0;
  if (password.length >= 12) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[a-z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) score++;
  return switch (score) {
    0 || 1 => _PwStrength.weak,
    2 => _PwStrength.fair,
    3 => _PwStrength.good,
    4 => _PwStrength.strong,
    _ => _PwStrength.veryStrong,
  };
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _password = '';
  String _confirmPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _password = _passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      setState(() => _confirmPassword = _confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_emailController.text.trim().isEmpty || _password.isEmpty) {
      return false;
    }
    if (_isSignUp) {
      return _passwordStrength(_password).isAcceptable &&
          _confirmPassword == _password;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final auth = context.read<AuthProvider>();
    final success = _isSignUp
        ? await auth.signUp(email, password)
        : await auth.signIn(email, password);

    if (!mounted) return;

    if (success) {
      if (_isSignUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created! Check your email to verify.',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onAccent),
            ),
            backgroundColor: context.colors.accent,
          ),
        );
      }
      Navigator.pop(context, true);
    }
  }

  Future<void> _submitGoogle() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (!mounted) return;
    if (success) Navigator.pop(context, true);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter your email above first',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onAccent)),
          backgroundColor: context.colors.accent,
        ),
      );
      return;
    }
    await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password reset email sent',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: context.colors.onAccent)),
        backgroundColor: context.colors.accent,
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.nunito(color: colors.textDim, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: colors.accent, size: 20),
      filled: true,
      fillColor: colors.surfaceFlat,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildPasswordStrengthMeter() {
    final colors = context.colors;
    final strength = _passwordStrength(_password);
    final filled = strength.filledSegments;
    final barColor = filled <= 1
        ? colors.error
        : filled == 2
            ? Color.lerp(colors.error, colors.accent, 0.5)!
            : colors.accent;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              final isFilled = i < filled;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: isFilled ? barColor : colors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _password.isEmpty
                ? 'Use at least 8 characters'
                : strength.label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _password.isEmpty ? colors.textDim : barColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.deep, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSignUp ? 'Create account' : 'Welcome back',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.deep,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Link an email to back up your data across devices',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.nunito(
                    color: colors.deep, fontWeight: FontWeight.w600),
                decoration: _decoration('Email', Icons.mail_outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.nunito(
                    color: colors.deep, fontWeight: FontWeight.w600),
                decoration: _decoration('Password', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colors.accent,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              if (_isSignUp) ...[
                _buildPasswordStrengthMeter(),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: GoogleFonts.nunito(
                      color: colors.deep, fontWeight: FontWeight.w600),
                  decoration:
                      _decoration('Confirm password', Icons.lock_outline)
                          .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colors.accent,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                if (_confirmPassword.isNotEmpty &&
                    _confirmPassword != _password) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Passwords don't match",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ],
              ],

              if (!_isSignUp) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.nunito(
                        color: colors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 8),

              if (auth.errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: GoogleFonts.nunito(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (auth.isLoading || !_canSubmit) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                    disabledBackgroundColor: colors.mint,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Sign up' : 'Log in',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onAccent),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: GoogleFonts.nunito(
                            color: colors.accent, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Divider(color: colors.border)),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _submitGoogle,
                  icon: Icon(Icons.g_mobiledata,
                      size: 26, color: colors.deep),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colors.deep),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isSignUp = !_isSignUp;
                  }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : "Don't have an account? Sign up",
                    style: GoogleFonts.nunito(
                        color: colors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}