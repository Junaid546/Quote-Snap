import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import 'package:quote_snap/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _businessNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    if (_isSignUp) {
      await ref
          .read(authProvider.notifier)
          .signUpWithEmail(
            _nameCtrl.text,
            _businessNameCtrl.text,
            _emailCtrl.text,
            _passwordCtrl.text,
          );
    } else {
      await ref
          .read(authProvider.notifier)
          .signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authState.message,
            style: GoogleFonts.publicSans(fontSize: 14),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (authState is AuthAuthenticated) {
      context.go('/home/dashboard');
    }
  }

  Future<void> _googleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authState.message,
            style: GoogleFonts.publicSans(fontSize: 14),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (authState is AuthAuthenticated) {
      context.go('/home/dashboard');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Geometric grid texture overlay
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.p24,
                vertical: 32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ─────────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'QuoteSnap',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Heading ───────────────────────────────────────────────
                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome back',
                      style: GoogleFonts.publicSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Join QuoteSnap to start winning jobs'
                          : 'Sign in to continue to your dashboard',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: const Color(0xFF8A8F9E),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── SignUp-only fields ────────────────────────────────────
                    if (_isSignUp) ...[
                      _buildField(
                        ctrl: _nameCtrl,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        ctrl: _businessNameCtrl,
                        hint: 'Business Name',
                        icon: Icons.business_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your business name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Email ─────────────────────────────────────────────────
                    _buildField(
                      ctrl: _emailCtrl,
                      hint: 'Email address',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Password ──────────────────────────────────────────────
                    _buildPasswordField(),
                    const SizedBox(height: 12),

                    // ── Forgot Password ───────────────────────────────────────
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // ── Primary CTA Button ────────────────────────────────────
                    _buildGradientButton(),
                    const SizedBox(height: 24),

                    // ── Divider ───────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.white.withAlpha(25)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: const Color(0xFF8A8F9E),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.white.withAlpha(25)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Google Button ─────────────────────────────────────────
                    _buildGoogleButton(),
                    const SizedBox(height: 36),

                    // ── Toggle Sign In / Sign Up ──────────────────────────────
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            color: const Color(0xFF8A8F9E),
                          ),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? ',
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  _formKey.currentState?.reset();
                                  setState(() => _isSignUp = !_isSignUp);
                                },
                                child: Text(
                                  _isSignUp ? 'Sign In' : 'Sign Up',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 15,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.publicSans(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.publicSans(
          color: const Color(0xFF8A8F9E),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF8A8F9E), size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2D3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2D3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        constraints: const BoxConstraints(minHeight: 56),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: GoogleFonts.publicSans(color: Colors.white, fontSize: 15),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your password';
        if (_isSignUp && v.length < 8) return 'Minimum 8 characters';
        return null;
      },
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: GoogleFonts.publicSans(
          color: const Color(0xFF8A8F9E),
          fontSize: 15,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF8A8F9E),
          size: 20,
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF8A8F9E),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2D3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2D3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        constraints: const BoxConstraints(minHeight: 56),
      ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFFEC5B13), Color(0xFFD4520F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        color: _isLoading ? AppColors.surface : null,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isSignUp ? 'Create Account' : 'Sign In',
                style: GoogleFonts.publicSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _googleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2A2D3A), width: 1.5),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google G icon using colored circles approximation
            _GoogleGIcon(),
            const SizedBox(width: 12),
            Text(
              'Google Sign-In',
              style: GoogleFonts.publicSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(5)
      ..strokeWidth = 0.5;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Google G Icon ────────────────────────────────────────────────────────────

class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.15;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Red (top right arc)
    canvas.drawArc(
      rect,
      -0.45,
      1.57,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Yellow (bottom right arc)
    canvas.drawArc(
      rect,
      1.12,
      1.05,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Green (bottom left arc)
    canvas.drawArc(
      rect,
      2.17,
      1.22,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );
    // Blue (left arc closing)
    canvas.drawArc(
      rect,
      3.39,
      1.20,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Blue horizontal bar for 'G'
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth / 2,
        center.dy - strokeWidth / 2,
        radius - strokeWidth / 2 + strokeWidth / 2,
        strokeWidth,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
