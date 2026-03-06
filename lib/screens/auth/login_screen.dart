import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/services/firebase_auth_service.dart';
import 'package:da_project_1/services/offline_auth_service.dart';
import 'package:da_project_1/services/commodity_service.dart';
import 'dart:math';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final OfflineAuthService _offlineAuthService = OfflineAuthService();

  late AnimationController _controller;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _titleOpacityAnim;
  late Animation<Offset> _emailSlideAnim;
  late Animation<Offset> _passwordSlideAnim;
  late Animation<Offset> _buttonSlideAnim;
  late Animation<double> _bottomOpacityAnim;

  bool _isLoading = false;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  @override
  void initState() {
    super.initState();

    // Initialize offline auth service
    _offlineAuthService.initialize();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _titleOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.45, curve: Curves.easeOut),
      ),
    );

    _emailSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
      ),
    );

    _passwordSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    _bottomOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.95, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// SCALE HELPER — use min() para hindi mag-overflow
  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter your email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Try Firebase login with timeout (5 seconds max)
      UserCredential? userCredential;
      try {
        userCredential = await _authService
            .loginWithEmailPassword(email: email, password: password)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        userCredential = null; // Timeout — fall through to offline
      }

      if (userCredential?.user != null) {
        // Firebase login successful
        final uid = userCredential!.user!.uid;

        // Cache minimal user data (non-blocking)
        final cached = await _authService.getCachedUserData(uid);
        String? accountStatus = cached?['accountStatus'] as String?;
        String? role = cached?['role'] as String?;

        if (accountStatus == null) {
          // Try to fetch fresh data with short timeout
          try {
            final userData = await _authService
                .getUserData(uid)
                .timeout(const Duration(seconds: 3));
            accountStatus = userData?['accountStatus'];
            role = userData?['role'];
          } catch (_) {
            // Timeout or fetch failure — do NOT assume 'pending_review'.
            // Prefer cached values; if unknown, allow login to proceed
            // and rely on server-driven enforcement where necessary.
            role ??= 'user';
          }
        }

        // Save credentials for offline use (async, non-blocking)
        await _offlineAuthService.saveCredentials(
          email: email,
          password: password,
          uid: uid,
          accountStatus: accountStatus ?? 'pending_review',
          role: role ?? 'user',
        );

        // Bootstrap commodity cache from Firestore if empty (on first login)
        debugPrint('📦 Starting commodity cache bootstrap...');
        unawaited(
          CommodityService()
              .bootstrapCacheIfEmpty()
              .timeout(const Duration(seconds: 10))
              .catchError((e) {
            debugPrint('⚠️ Bootstrap failed (non-blocking): $e');
            // Continue anyway — cache may already be populated
            return false;
          }),
        );

        if (!mounted) return;

        // Route based on status
        if (accountStatus == 'pending_review') {
          Navigator.pushReplacementNamed(context, AppRoutes.accountUnderReview);
        } else if (accountStatus == 'rejected') {
          await _authService.signOut();
          _showErrorDialog(
              'Your account has been rejected. Please contact support.');
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
        return;
      }

      // Firebase failed — try offline login
      final isValid = await _offlineAuthService.verifyStoredCredentials(
        email: email,
        password: password,
      );

      if (!isValid) {
        _showErrorDialog(
            'Login failed. Please try again or connect to internet.');
        return;
      }

      // Offline login successful
      if (!mounted) return;
      _showOfflineModeDialog();

      final accountStatus = await _offlineAuthService.getStoredAccountStatus();
      if (!mounted) return;

      if (accountStatus == 'pending_review') {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
                context, AppRoutes.accountUnderReview);
          }
        });
      } else if (accountStatus == 'rejected') {
        _showErrorDialog(
            'Your account has been rejected. Please contact support.');
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        String message = 'Login failed: ${e.toString()}';
        _showErrorDialog(message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOfflineModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Mode'),
        content: const Text(
            'You are logged in offline. Your profiling data will be saved locally and synced when you reconnect to the internet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    final logoWidth = _refWidth * 0.4 * scale;
    final logoTopPad = _refHeight * 0.08 * scale;
    final titleFontSize = _refWidth * 0.1 * scale;
    final fieldHorizontalPad = _refWidth * 0.1 * scale;
    final fieldFontSize = _refWidth * 0.04 * scale;
    final fieldContentPadH = 16.0 * scale;
    final fieldContentPadV = 14.0 * scale;
    final fieldRadius = 12.0 * scale;
    final spacingAfterLogo = _refHeight * 0.05 * scale;
    final spacingAfterTitle = _refHeight * 0.03 * scale;
    final spacingBetweenFields = _refHeight * 0.015 * scale;
    final spacingBeforeButton = _refHeight * 0.03 * scale;
    final buttonHeight = 50.0 * scale;
    final buttonRadius = 25.0 * scale;
    final buttonFontSize = 18.0 * scale;
    final bottomFontSize = _refWidth * 0.035 * scale;
    final testFontSize = _refWidth * 0.03 * scale;
    final spacingAfterButton = _refHeight * 0.02 * scale;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          /// BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
            ),
          ),

          /// CONTENT
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: logoTopPad),

                    /// LOGO
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacityAnim.value,
                          child: Transform.scale(
                            scale: _logoScaleAnim.value,
                            child: Image.asset(
                              'assets/images/da_logo.png',
                              width: logoWidth,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: spacingAfterLogo),

                    /// TITLE
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _titleOpacityAnim.value,
                          child: Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: DAColors.white,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: spacingAfterTitle),

                    /// EMAIL
                    SlideTransition(
                      position: _emailSlideAnim,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: fieldHorizontalPad),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(
                            fontSize: fieldFontSize,
                            color: DAColors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: fieldFontSize,
                              color: Colors.grey,
                            ),
                            fillColor: DAColors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(fieldRadius),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: fieldContentPadH,
                              vertical: fieldContentPadV,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spacingBetweenFields),

                    /// PASSWORD
                    SlideTransition(
                      position: _passwordSlideAnim,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: fieldHorizontalPad),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: GoogleFonts.poppins(
                            fontSize: fieldFontSize,
                            color: DAColors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: fieldFontSize,
                              color: Colors.grey,
                            ),
                            fillColor: DAColors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(fieldRadius),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: fieldContentPadH,
                              vertical: fieldContentPadV,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spacingBeforeButton),

                    /// LOGIN BUTTON
                    SlideTransition(
                      position: _buttonSlideAnim,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: fieldHorizontalPad),
                        child: SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DAColors.orange,
                              foregroundColor: DAColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(buttonRadius),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: buttonHeight * 0.25,
                                horizontal: 20 * scale,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: DAColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: buttonFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: DAColors.white,
                                      height: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: spacingAfterButton),

                    /// BOTTOM TEXT
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _bottomOpacityAnim.value,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                      fontSize: bottomFontSize,
                                      color: DAColors.white,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.register,
                                      );
                                    }, minimumSize: Size(0, 0),
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.poppins(
                                        fontSize: bottomFontSize,
                                        color: DAColors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacingAfterButton * 0.5),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgotPassword,
                                  );
                                }, minimumSize: Size(0, 0),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: testFontSize,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
}