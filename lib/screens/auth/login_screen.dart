import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _titleOpacityAnim;
  late Animation<Offset> _emailSlideAnim;
  late Animation<Offset> _passwordSlideAnim;
  late Animation<Offset> _buttonSlideAnim;
  late Animation<double> _bottomOpacityAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  @override
  void initState() {
    super.initState();

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
    final buttonFontSize = 18.0 * scale; // Fixed: Based on scale, not absolute percentage
    final bottomFontSize = _refWidth * 0.035 * scale;
    final testFontSize = _refWidth * 0.03 * scale;
    final spacingAfterButton = _refHeight * 0.02 * scale;

    return Scaffold(
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
                child: IntrinsicHeight(
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
                          padding: EdgeInsets.symmetric(
                              horizontal: fieldHorizontalPad),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: fieldHorizontalPad),
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
                          padding: EdgeInsets.symmetric(
                              horizontal: fieldHorizontalPad),
                          child: SizedBox(
                            width: double.infinity,
                            height: buttonHeight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.home,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DAColors.orange,
                                foregroundColor: DAColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(buttonRadius),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: buttonHeight * 0.25,
                                  horizontal: 20 * scale,
                                ),
                              ),
                              child: Text(
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
                                      minSize: 0,
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.register,
                                        );
                                      },
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
                                  minSize: 0,
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.accountUnderReview,
                                    );
                                  },
                                  child: Text(
                                    '[TEST] Go to Under Review',
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
          ),
        ],
      ),
    );
  }
}