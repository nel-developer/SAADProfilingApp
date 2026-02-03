import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'dart:math';

class AccountUnderReviewScreen extends StatefulWidget {
  const AccountUnderReviewScreen({super.key});

  @override
  State<AccountUnderReviewScreen> createState() =>
      _AccountUnderReviewScreenState();
}

class _AccountUnderReviewScreenState extends State<AccountUnderReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacityAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _cardSlideAnim;
  late Animation<double> _cardOpacityAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _cardOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _cardSlideAnim = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final spacingAfterLogo = _refHeight * 0.05 * scale;
    final cardHorizontalPad = _refWidth * 0.08 * scale;
    final cardPadding = _refWidth * 0.07 * scale;
    final cardRadius = 24.0 * scale;
    final iconSize = _refWidth * 0.3 * scale;
    final spacingAfterIcon = _refHeight * 0.04 * scale;
    final titleFontSize = _refWidth * 0.065 * scale;
    final spacingAfterTitle = _refHeight * 0.02 * scale;
    final subtitleFontSize = _refWidth * 0.038 * scale;
    final spacingAfterSubtitle = _refHeight * 0.04 * scale;
    final buttonHeight = 50.0 * scale;
    final buttonRadius = 25.0 * scale;
    final buttonFontSize = 18.0 * scale;

    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
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
            child: Column(
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

                /// WHITE CARD
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _cardOpacityAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, _cardSlideAnim.value),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: cardHorizontalPad,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(cardPadding),
                            decoration: BoxDecoration(
                              color: DAColors.white,
                              borderRadius: BorderRadius.circular(cardRadius),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /// ICON
                                Icon(
                                  Icons.description_outlined,
                                  size: iconSize,
                                  color: DAColors.primaryGreen,
                                ),

                                SizedBox(height: spacingAfterIcon),

                                /// TITLE
                                Text(
                                  'Your account\nis under review',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: DAColors.black,
                                  ),
                                ),

                                SizedBox(height: spacingAfterTitle),

                                /// SUBTITLE
                                Text(
                                  'Your account has been submitted &\nwill be reviewed by the admin.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize,
                                    color: Colors.grey,
                                  ),
                                ),

                                SizedBox(height: spacingAfterSubtitle),

                                /// BACK TO LOGIN BUTTON
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        AppRoutes.login,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DAColors.primaryGreen,
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
                                      'Back to Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: DAColors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}