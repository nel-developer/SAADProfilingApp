import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/services/firebase_auth_service.dart';
import 'dart:math';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();

  late AnimationController _controller;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _titleOpacityAnim;
  late Animation<Offset> _firstNameSlideAnim;
  late Animation<Offset> _middleNameSlideAnim;
  late Animation<Offset> _lastNameSlideAnim;
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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _titleOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.35, curve: Curves.easeOut),
      ),
    );

    _firstNameSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.28, 0.45, curve: Curves.easeOut),
          ),
        );

    _middleNameSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.52, curve: Curves.easeOut),
          ),
        );

    _lastNameSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.42, 0.59, curve: Curves.easeOut),
          ),
        );

    _emailSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.49, 0.66, curve: Curves.easeOut),
          ),
        );

    _passwordSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.56, 0.73, curve: Curves.easeOut),
          ),
        );

    _buttonSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.65, 0.82, curve: Curves.easeOut),
          ),
        );

    _bottomOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 0.95, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final scaleW = (MediaQuery.of(context).size.width / _refWidth).clamp(
      0.5,
      2.0,
    );
    final scaleH = (MediaQuery.of(context).size.height / _refHeight).clamp(
      0.5,
      2.0,
    );
    return min(scaleW, scaleH);
  }

  Future<void> _handleRegister() async {
    // Prevent multiple submissions
    if (_isLoading) return;

    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showErrorDialog('Please fill in all required fields');
      return;
    }

    // Validate email format
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email)) {
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    // Validate password strength
    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.accountUnderReview);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
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
        title: const Text('Registration Error'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Animation<Offset> slideAnim,
    required double scale,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    final fieldFontSize = _refWidth * 0.04 * scale;
    final fieldRadius = 12.0 * scale;
    final fieldContentPadH = 16.0 * scale;
    final fieldContentPadV = 14.0 * scale;

    return SlideTransition(
      position: slideAnim,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.poppins(
          fontSize: fieldFontSize,
          color: DAColors.black,
        ),
        decoration: InputDecoration(
          hintText: hintText,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    final logoWidth = _refWidth * 0.4 * scale;
    final logoTopPad = _refHeight * 0.06 * scale;
    final titleFontSize = _refWidth * 0.1 * scale;
    final fieldHorizontalPad = _refWidth * 0.1 * scale;
    final spacingAfterLogo = _refHeight * 0.04 * scale;
    final spacingAfterTitle = _refHeight * 0.025 * scale;
    final spacingBetweenFields = _refHeight * 0.015 * scale;
    final spacingBeforeButton = _refHeight * 0.03 * scale;
    final buttonHeight = 50.0 * scale;
    final buttonRadius = 25.0 * scale;
    final buttonFontSize = 18.0 * scale;
    final bottomFontSize = _refWidth * 0.035 * scale;
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
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),

          /// CONTENT
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
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
                            'Register',
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

                    /// FORM FIELDS
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: fieldHorizontalPad,
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _firstNameController,
                            hintText: 'First Name',
                            slideAnim: _firstNameSlideAnim,
                            scale: scale,
                          ),
                          SizedBox(height: spacingBetweenFields),
                          _buildTextField(
                            controller: _middleNameController,
                            hintText: 'Middle Name',
                            slideAnim: _middleNameSlideAnim,
                            scale: scale,
                          ),
                          SizedBox(height: spacingBetweenFields),
                          _buildTextField(
                            controller: _lastNameController,
                            hintText: 'Last Name',
                            slideAnim: _lastNameSlideAnim,
                            scale: scale,
                          ),
                          SizedBox(height: spacingBetweenFields),
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            slideAnim: _emailSlideAnim,
                            scale: scale,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: spacingBetweenFields),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            slideAnim: _passwordSlideAnim,
                            scale: scale,
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: spacingBeforeButton),

                    /// REGISTER BUTTON
                    SlideTransition(
                      position: _buttonSlideAnim,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: fieldHorizontalPad,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DAColors.orange,
                              foregroundColor: DAColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  buttonRadius,
                                ),
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
                                    'Register',
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.poppins(
                                  fontSize: bottomFontSize,
                                  color: DAColors.white,
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                minimumSize: Size(0, 0),
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: bottomFontSize,
                                    color: DAColors.orange,
                                    fontWeight: FontWeight.bold,
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
