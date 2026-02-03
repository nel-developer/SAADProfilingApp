import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/widgets/home_tile.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/services/firebase_auth_service.dart';

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

  final FirebaseAuthService _authService = FirebaseAuthService();
  String? _userRole;

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
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _authService.currentUser;
    if (user != null) {
      // Use `getUserRole` which checks in-memory and SharedPreferences caches
      // before querying Firestore. This is faster and avoids fetching full
      // user documents just to read the role.
      final role = await _authService.getUserRole(user.uid);
      setState(() {
        _userRole = role;
      });
    }
  }

  void _showLockedAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restricted'),
        content: const Text(
            'This feature is restricted. Only Admins, Profilers, or Moderators can access it.'),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // ── HEADER ──────────────────────────────────────────
    final headerHeight  = (height * 0.22).clamp(120.0, 180.0);
    final welcomeFont   = (width * 0.055).clamp(16.0, 28.0);
    final avatarRadius  = (width * 0.07).clamp(20.0, 38.0);
    final headerPadH    = (width * 0.06).clamp(16.0, 36.0);
    final headerPadV    = (height * 0.02).clamp(10.0, 24.0);

    // ── TILES ───────────────────────────────────────────
    // Tile size = ~38% of screen width, hard capped 100–150
    // This keeps tiles the same visual weight on 360 phones AND 540+ screens
    final tileSize = (width * 0.38).clamp(100.0, 150.0);
    final gap      = (width * 0.035).clamp(10.0, 18.0);
    final gridPad  = (width * 0.05).clamp(14.0, 28.0);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Column(
        children: [
          // ── GREEN HEADER ──────────────────────────────
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                GreenHeaderSection(
                  leafLeftAnimation: _leafLeftAnim,
                  leafRightAnimation: _leafRightAnim,
                  customHeight: headerHeight,
                ),
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
                            horizontal: headerPadH,
                            vertical: headerPadV,
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  flex: 3,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Welcome,\n',
                                          style: GoogleFonts.poppins(
                                            fontSize: welcomeFont,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            height: 1.2,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Juan!',
                                          style: GoogleFonts.poppins(
                                            fontSize: welcomeFont,
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
                                SizedBox(width: 12),
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

          // ── TILE GRID ─────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(gridPad),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// ROW 1
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
                        SizedBox(width: gap),
                        SizedBox(
                          width: tileSize,
                          height: tileSize,
                          child: HomeTile(
                            label: 'Profiling',
                            icon: Icons.person_outline,
                              route: AppRoutes.profiling,
                              animation: _tile2Anim,
                              isEnabled: _userRole != null &&
                                  ['admin', 'profiler', 'moderator']
                                      .contains(_userRole!.toLowerCase()),
                              onDisabledTap: _showLockedAlert,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: gap),

                    /// ROW 2
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
                            isEnabled: _userRole?.toLowerCase() == 'admin',
                            onDisabledTap: _showLockedAlert,
                          ),
                        ),
                        SizedBox(width: gap),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}