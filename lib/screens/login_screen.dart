import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  bool _loading = false;
  String? _error;
  bool _isSignUp = false;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() { _loading = true; _error = null; });
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required.');
      }
      
      if (!email.toLowerCase().endsWith('@student.its.ac.id')) {
        throw Exception('Only @student.its.ac.id accounts are allowed.');
      }
      
      if (_isSignUp) {
        final confirmPassword = _confirmPasswordController.text;
        if (password != confirmPassword) {
          throw Exception('Passwords do not match.');
        }
        if (password.length < 6) {
          throw Exception('Password must be at least 6 characters.');
        }
        await _auth.registerWithEmail(email, password);
      } else {
        await _auth.signInWithEmail(email, password);
      }
      
      if (mounted) setState(() => _loading = false);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A3D42), Color(0xFF0D5C63), Color(0xFF0A3D42)],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter()),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: T.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: T.accent.withOpacity(0.5)),
                      ),
                      child: Text(
                        'IUP — Institut Teknologi Sepuluh Nopember',
                        style: GoogleFonts.dmSans(
                          color: T.accent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 20),

                    Text(
                      'CCWS\nVision',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 56,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 14),

                    Text(
                      'Know who\'s in the room.\nShare the vibe. Stay connected.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.65),
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: 40),

                    // Stats cards row
                    Row(
                      children: [
                        _statCard('Check-in', 'Tell others\nyou\'re here', Icons.where_to_vote_outlined),
                        const SizedBox(width: 12),
                        _statCard('Comments', 'Share the\ncurrent vibe', Icons.chat_bubble_outline_rounded),
                        const SizedBox(width: 12),
                        _statCard('Live Feed', 'See who\'s\naround now', Icons.people_outline_rounded),
                      ],
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 40),

                    // Mode indicator
                    Text(
                      _isSignUp ? 'Create Account' : 'Sign In',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'your.name@student.its.ac.id',
                        hintStyle: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      style: GoogleFonts.dmSans(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ).animate().fadeIn(delay: 750.ms),

                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      // Confirm password field
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                          ),
                        ),
                        style: GoogleFonts.dmSans(color: Colors.white),
                      ).animate().fadeIn(delay: 800.ms),
                    ],

                    const SizedBox(height: 20),

                    // Error
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.redAccent, fontSize: 13)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: T.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: T.primary))
                            : Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                      ),
                    ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    Center(
                      child: GestureDetector(
                        onTap: _toggleMode,
                        child: Text.rich(
                          TextSpan(
                            text: _isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                            style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.7), fontSize: 12),
                            children: [
                              TextSpan(
                                text: _isSignUp ? 'Sign In' : 'Sign Up',
                                style: GoogleFonts.dmSans(
                                    color: T.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'Only @student.its.ac.id accounts are permitted',
                        style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                    ).animate().fadeIn(delay: 950.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String sub, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: T.accent, size: 20),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub,
                style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.5), fontSize: 10, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}