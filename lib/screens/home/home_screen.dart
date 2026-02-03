import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/widgets/home_tile.dart';
import 'package:da_project_1/widgets/green_header_section.dart';

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
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Responsive breakpoints
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    // HEADER HEIGHT
    final headerHeight = height * (isLargeTablet ? 0.18 : isTablet ? 0.22 : 0.28);
    
    // TEXT SIZE
    final welcomeFontSize = isLargeTablet 
        ? 48.0
        : isTablet 
            ? 38.0
            : width * 0.065;
    
    // AVATAR SIZE
    final avatarRadius = isLargeTablet
        ? 55.0
        : isTablet
            ? 45.0
            : width * 0.085;

    // TILES SIZING
    final tileGridPadding = isLargeTablet
        ? 60.0
        : isTablet
            ? width * 0.08
            : width * 0.06;
    
    final tileSpacing = isLargeTablet
        ? 40.0
        : isTablet
            ? width * 0.05
            : width * 0.04;

    // HEADER PADDING
    final headerHorizontalPadding = isLargeTablet
        ? 80.0
        : width * 0.06;
    
    final headerVerticalPadding = isLargeTablet
        ? 30.0
        : height * 0.025;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Column(
        children: [
          /// GREEN HEADER WITH CONTENT
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                /// REUSABLE GREEN HEADER BACKGROUND WITH LEAFS
                GreenHeaderSection(
                  leafLeftAnimation: _leafLeftAnim,
                  leafRightAnimation: _leafRightAnim,
                  customHeight: headerHeight,
                ),

                /// HEADER CONTENT (Text + Avatar)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _headerOpacityAnim.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _headerSlideAnim.value),
                        child: Container(
                          height: headerHeight,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: headerHorizontalPadding,
                            vertical: headerVerticalPadding,
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                /// WELCOME TEXT
                                Flexible(
                                  flex: 3,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Welcome,\n',
                                          style: GoogleFonts.poppins(
                                            fontSize: welcomeFontSize,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.2,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Juan!',
                                          style: GoogleFonts.poppins(
                                            fontSize: welcomeFontSize,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.2,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                SizedBox(width: width * 0.04),

                                /// AVATAR
                                CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: avatarRadius * 1.1,
                                    color: const Color(0xFF6B6B6B),
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

          /// TILES GRID SECTION
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(tileGridPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;

                  // Calculate tile size
                  final maxTileWidth = (availableWidth - tileSpacing) / 2;
                  final maxTileHeight = (availableHeight - tileSpacing) / 2;

                  final tileSize = (maxTileWidth < maxTileHeight
                          ? maxTileWidth
                          : maxTileHeight)
                      .clamp(100.0, 250.0);

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// ROW 1: Dashboard & Profiling
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: tileSize,
                              height: tileSize,
                              child: HomeTile(
                                label: 'Dashboard',
                                icon: Icons.grid_view_outlined,
                                route: AppRoutes.dashboard,
                                animation: _tile1Anim,
                              ),
                            ),
                            SizedBox(width: tileSpacing),
                            SizedBox(
                              width: tileSize,
                              height: tileSize,
                              child: HomeTile(
                                label: 'Profiling',
                                icon: Icons.person_outline,
                                route: AppRoutes.profiling, // ← FIXED: may route na
                                animation: _tile2Anim,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tileSpacing),

                        /// ROW 2: Accounts & Settings
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: tileSize,
                              height: tileSize,
                              child: HomeTile(
                                label: 'Accounts',
                                icon: Icons.people_outline,
                                route: AppRoutes.accounts,
                                animation: _tile3Anim,
                              ),
                            ),
                            SizedBox(width: tileSpacing),
                            SizedBox(
                              width: tileSize,
                              height: tileSize,
                              child: HomeTile(
                                label: 'Settings',
                                icon: Icons.settings_outlined,
                                route: AppRoutes.settings,
                                animation: _tile4Anim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}