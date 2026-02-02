import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/theme/da_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _tile1Anim;
  late Animation<double> _tile2Anim;
  late Animation<double> _tile3Anim;
  late Animation<double> _tile4Anim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _headerOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnim = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _tile1Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _tile2Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.63, curve: Curves.easeOutBack),
      ),
    );

    _tile3Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.46, 0.71, curve: Curves.easeOutBack),
      ),
    );

    _tile4Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.54, 0.79, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> tiles = [
      {
        'label': 'Dashboard',
        'icon': Icons.grid_view_outlined,
        'route': AppRoutes.dashboard,
      },
      {
        'label': 'Profiling',
        'icon': Icons.person_outline,
        'route': null, // TODO: profiling route
      },
      {
        'label': 'Accounts',
        'icon': Icons.people_outline,
        'route': AppRoutes.accounts,
      },
      {
        'label': 'Settings',
        'icon': Icons.settings_outlined,
        'route': AppRoutes.settings,
      },
    ];

    final List<Animation<double>> tileAnims = [
      _tile1Anim,
      _tile2Anim,
      _tile3Anim,
      _tile4Anim,
    ];

    return Column(
      children: [
        /// GREEN HEADER
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _headerOpacityAnim.value,
              child: Transform.translate(
                offset: Offset(0, _headerSlideAnim.value),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.06,
                    bottom: screenHeight * 0.05,
                    left: screenWidth * 0.06,
                    right: screenWidth * 0.06,
                  ),
                  decoration: const BoxDecoration(
                    color: DAColors.primaryGreen,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// WELCOME TEXT
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Welcome,\n',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: DAColors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'Juan!',
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: DAColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// AVATAR
                      CircleAvatar(
                        radius: screenWidth * 0.09,
                        backgroundColor: Colors.grey.shade400,
                        child: Icon(
                          Icons.person,
                          size: screenWidth * 0.1,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        /// TILES SECTION
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    /// DASHBOARD TILE
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: tileAnims[0].value,
                            child: Transform.scale(
                              scale: tileAnims[0].value,
                              child: _buildTile(
                                context,
                                label: tiles[0]['label'],
                                icon: tiles[0]['icon'],
                                route: tiles[0]['route'],
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),

                    /// PROFILING TILE
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: tileAnims[1].value,
                            child: Transform.scale(
                              scale: tileAnims[1].value,
                              child: _buildTile(
                                context,
                                label: tiles[1]['label'],
                                icon: tiles[1]['icon'],
                                route: tiles[1]['route'],
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.04),
                Row(
                  children: [
                    /// ACCOUNTS TILE
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: tileAnims[2].value,
                            child: Transform.scale(
                              scale: tileAnims[2].value,
                              child: _buildTile(
                                context,
                                label: tiles[2]['label'],
                                icon: tiles[2]['icon'],
                                route: tiles[2]['route'],
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),

                    /// SETTINGS TILE
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: tileAnims[3].value,
                            child: Transform.scale(
                              scale: tileAnims[3].value,
                              child: _buildTile(
                                context,
                                label: tiles[3]['label'],
                                icon: tiles[3]['icon'],
                                route: tiles[3]['route'],
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String? route,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: DAColors.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: screenWidth * 0.12,
                color: DAColors.white,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  color: DAColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}