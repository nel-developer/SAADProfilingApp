import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'dart:math';

/// ForgotPasswordScreen - Password recovery
/// User enters email → Receives reset link
/// Same background and responsive design as LoginScreen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _cardOpacityAnim;
  late Animation<Offset> _cardSlideAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _cardOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// SCALE HELPER — same as login screen
  double _scale(BuildContext context) {
    final scaleW = (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH = (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  Future<void> _sendResetLink() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement Firebase password reset
    // await FirebaseAuth.instance.sendPasswordResetEmail(
    //   email: _emailController.text.trim(),
    // );

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password reset link sent! Check your email.'),
        backgroundColor: DAColors.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );

    // Go back to login after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    final logoWidth = _refWidth * 0.4 * scale;
    final logoTopPad = _refHeight * 0.08 * scale;
    final cardHorizontalPad = _refWidth * 0.08 * scale;
    final cardVerticalPad = _refHeight * 0.04 * scale;
    final cardInnerPadH = _refWidth * 0.1 * scale;
    final cardInnerPadV = _refHeight * 0.05 * scale;
    final titleFontSize = _refWidth * 0.061 * scale;
    final subtitleFontSize = _refWidth * 0.036 * scale;
    final labelFontSize = _refWidth * 0.041 * scale;
    final fieldFontSize = _refWidth * 0.036 * scale;
    final fieldRadius = 30.0 * scale;
    final fieldContentPadH = 24.0 * scale;
    final fieldContentPadV = 18.0 * scale;
    final buttonHeight = 54.0 * scale;
    final buttonRadius = 30.0 * scale;
    final buttonFontSize = 18.0 * scale;
    final backButtonFontSize = _refWidth * 0.036 * scale;
    final spacingAfterLogo = _refHeight * 0.04 * scale;
    final spacingAfterTitle = _refHeight * 0.015 * scale;
    final spacingAfterSubtitle = _refHeight * 0.03 * scale;
    final spacingAfterLabel = 12.0 * scale;
    final spacingAfterField = _refHeight * 0.03 * scale;
    final spacingAfterButton = _refHeight * 0.02 * scale;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          /// SAME BACKGROUND AS LOGIN SCREEN
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
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardHorizontalPad,
                    vertical: cardVerticalPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: logoTopPad),

                      /// DA LOGO (same as login screen)
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

                      /// WHITE CARD CONTAINER
                      SlideTransition(
                        position: _cardSlideAnim,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _cardOpacityAnim.value,
                              child: child!,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.0 * scale),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20.0 * scale,
                                  offset: Offset(0, 10.0 * scale),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: cardInnerPadH,
                              vertical: cardInnerPadV,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// TITLE
                                Center(
                                  child: Text(
                                    'Reset your password',
                                    style: GoogleFonts.poppins(
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                SizedBox(height: spacingAfterTitle),

                                /// SUBTITLE
                                Center(
                                  child: Text(
                                    'We will send you the link to reset\nyour password',
                                    style: GoogleFonts.poppins(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                SizedBox(height: spacingAfterSubtitle),

                                /// EMAIL ADDRESS LABEL
                                Text(
                                  'Email Address',
                                  style: GoogleFonts.poppins(
                                    fontSize: labelFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),

                                SizedBox(height: spacingAfterLabel),

                                /// EMAIL INPUT FIELD
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(fieldRadius),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 2.0 * scale,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.poppins(
                                      fontSize: fieldFontSize,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email address',
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: fieldFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade400,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: fieldContentPadH,
                                        vertical: fieldContentPadV,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: spacingAfterField),

                                /// SEND BUTTON
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendResetLink,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isLoading ? Colors.grey : DAColors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(buttonRadius),
                                      ),
                                      elevation: 0,
                                      shadowColor: DAColors.orange.withOpacity(0.3),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20.0 * scale,
                                            height: 20.0 * scale,
                                            child: const CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Send',
                                            style: GoogleFonts.poppins(
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                SizedBox(height: spacingAfterButton),

                                /// BACK TO LOGIN
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Back to Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: backButtonFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: DAColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: logoTopPad),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}