import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  bool _isPasswordVisible = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController(text: 'Jiroh');
  final TextEditingController _middleNameController = TextEditingController(text: 'Obispo');
  final TextEditingController _lastNameController = TextEditingController(text: 'Ilag');
  final TextEditingController _emailController = TextEditingController(text: 'jirohilag@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: '••••••••••••••••');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnim = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _leafLeftAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _leafRightAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
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

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settings saved successfully'),
        backgroundColor: DAColors.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final headerHeight = height * (isLargeTablet ? 0.18 : isTablet ? 0.22 : 0.28);
    final titleFontSize = isLargeTablet ? 36.0 : isTablet ? 30.0 : width * 0.065;
    final subtitleFontSize = isLargeTablet ? 14.0 : isTablet ? 12.0 : width * 0.028;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Column(
        children: [
          /// GREEN HEADER SECTION
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                /// BACKGROUND WITH LEAVES
                GreenHeaderSection(
                  leafLeftAnimation: _leafLeftAnim,
                  leafRightAnimation: _leafRightAnim,
                  customHeight: headerHeight,
                ),

                /// HEADER CONTENT
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _headerOpacityAnim.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _headerSlideAnim.value),
                        child: child!,
                      ),
                    );
                  },
                  child: Container(
                    height: headerHeight,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.06,
                      vertical: height * 0.025,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          /// BACK BUTTON
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: DAColors.primaryGreen,
                                size: isTablet ? 28 : 24,
                              ),
                            ),
                          ),

                          const Spacer(),

                          /// TITLE & SUBTITLE (CENTERED)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Settings',
                                style: GoogleFonts.poppins(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your personal information',
                                style: GoogleFonts.poppins(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const Spacer(),

                          /// INVISIBLE SPACER FOR CENTERING
                          SizedBox(width: isTablet ? 52 : 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// EDIT PROFILE TITLE
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeTablet ? 24.0 : isTablet ? 22.0 : 20.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),

                  /// FIRST NAME
                  _buildFieldLabel('First Name', isTablet, isLargeTablet),
                  const SizedBox(height: 8),
                  _buildTextField(_firstNameController, isTablet, isLargeTablet),
                  SizedBox(height: height * 0.02),

                  /// MIDDLE NAME
                  _buildFieldLabel('Middle Name', isTablet, isLargeTablet),
                  const SizedBox(height: 8),
                  _buildTextField(_middleNameController, isTablet, isLargeTablet),
                  SizedBox(height: height * 0.02),

                  /// LAST NAME
                  _buildFieldLabel('Last Name', isTablet, isLargeTablet),
                  const SizedBox(height: 8),
                  _buildTextField(_lastNameController, isTablet, isLargeTablet),
                  SizedBox(height: height * 0.02),

                  /// EMAIL
                  _buildFieldLabel('Email', isTablet, isLargeTablet),
                  const SizedBox(height: 8),
                  _buildTextField(_emailController, isTablet, isLargeTablet),
                  SizedBox(height: height * 0.02),

                  /// PASSWORD
                  _buildFieldLabel('Password', isTablet, isLargeTablet),
                  const SizedBox(height: 8),
                  _buildPasswordField(isTablet, isLargeTablet),
                  SizedBox(height: height * 0.03),

                  /// SAVE BUTTON
                  GestureDetector(
                    onTap: _saveSettings,
                    child: Container(
                      width: double.infinity,
                      height: isLargeTablet ? 56 : isTablet ? 52 : 50,
                      decoration: BoxDecoration(
                        color: DAColors.primaryGreen,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: DAColors.primaryGreen.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isTablet, bool isLargeTablet) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    bool isTablet,
    bool isLargeTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(
          fontSize: isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 20 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(bool isTablet, bool isLargeTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: GoogleFonts.poppins(
          fontSize: isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 20 : 16,
          ),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: DAColors.primaryGreen,
              size: isTablet ? 28 : 24,
            ),
          ),
        ),
      ),
    );
  }
}