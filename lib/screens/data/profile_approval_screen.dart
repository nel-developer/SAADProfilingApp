import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

class ProfileApprovalScreen extends StatefulWidget {
  const ProfileApprovalScreen({super.key});

  @override
  State<ProfileApprovalScreen> createState() => _ProfileApprovalScreenState();
}

class _ProfileApprovalScreenState extends State<ProfileApprovalScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  // Animation fields (deprecated - approval now happens in modal)
  // late Animation<double> _headerOpacityAnim;
  // late Animation<double> _headerSlideAnim;
  // late Animation<double> _leafLeftAnim;
  // late Animation<double> _leafRightAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  final ProfilingStorageService _storage = ProfilingStorageService();
  List<ProfilingData> _pendingProfiles = [];
  bool _isLoading = true;
  bool _hasInternet = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animation setup removed (deprecated screen)
    // _headerOpacityAnim, _headerSlideAnim, _leafLeftAnim, _leafRightAnim
    // are no longer used

    _controller.forward();
    _loadPendingProfiles();
  }

  Future<void> _loadPendingProfiles() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
      
      // Check internet connectivity first
      debugPrint('🔍 Checking internet connectivity...');
      final connectivityResult = await Connectivity().checkConnectivity();
      
      // Handle both List and single ConnectivityResult
      bool isConnected = false;
      if (connectivityResult is List) {
        isConnected = (connectivityResult as List).any((result) =>
            result == ConnectivityResult.mobile || 
            result == ConnectivityResult.wifi);
      } else {
        isConnected = connectivityResult == ConnectivityResult.mobile ||
                      connectivityResult == ConnectivityResult.wifi;
      }
      
      if (!isConnected) {
        debugPrint('❌ No internet connection');
        setState(() {
          _isLoading = false;
          _hasInternet = false;
          _loadError = 'No internet connection';
          _pendingProfiles = [];
        });
        return;
      }
      
      setState(() {
        _hasInternet = true;
      });
      
      debugPrint('✅ Internet available - Loading pending profiles from Firestore...');
      await _storage.init();
      final profiles = await _storage.loadPendingProfiles();
      debugPrint('✅ Pending profiles loaded: ${profiles.length} profile(s)');
      setState(() {
        _pendingProfiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading pending profiles: $e');
      setState(() {
        _isLoading = false;
        _loadError = 'Error loading profiles: ${e.toString()}';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload pending profiles when screen comes back into focus
      debugPrint('📱 Approval screen resumed - reloading pending profiles');
      _loadPendingProfiles();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final scaleW = (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH = (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  void _showApprovalDialog(ProfilingData profile, String docId) {
    final scale = _scale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Approve Profile',
            style: GoogleFonts.poppins(
              fontSize: 16.0 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile: ${profile.firstName} ${profile.surname}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.0 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0 * scale),
                Text(
                  'Are you sure you want to approve this profile?',
                  style: GoogleFonts.poppins(
                    fontSize: 12.0 * scale,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 12.0 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _approveProfile(docId, profile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DAColors.primaryGreen,
              ),
              child: Text(
                'Approve',
                style: GoogleFonts.poppins(
                  fontSize: 12.0 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRejectionDialog(ProfilingData profile, String docId) {
    final scale = _scale(context);
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reject Profile',
            style: GoogleFonts.poppins(
              fontSize: 16.0 * scale,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile: ${profile.firstName} ${profile.surname}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.0 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0 * scale),
                Text(
                  'Rejection Reason:',
                  style: GoogleFonts.poppins(
                    fontSize: 12.0 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.0 * scale),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0 * scale),
                  ),
                  child: TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(
                      fontSize: 12.0 * scale,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter reason for rejection',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12.0 * scale),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 12.0 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _rejectProfile(docId, reasonController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: Text(
                'Reject',
                style: GoogleFonts.poppins(
                  fontSize: 12.0 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveProfile(String docId, ProfilingData profile) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DAColors.primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                'Approving profile...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      final success = await _storage.approvePendingProfile(docId, profile);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Profile approved successfully'),
            backgroundColor: DAColors.primaryGreen,
          ),
        );
        await _loadPendingProfiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to approve profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error approving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectProfile(String docId, String reason) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rejecting profile...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      final success = await _storage.rejectPendingProfile(docId, reason);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadPendingProfiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to reject profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error rejecting profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    return Scaffold(
      backgroundColor: DAColors.lightGrey,
      body: Column(
        children: [
          /// GREEN HEADER
          Container(
            color: DAColors.primaryGreen,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0 * scale,
                  vertical: 12.0 * scale,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8.0 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: DAColors.primaryGreen,
                          size: 24.0 * scale,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Approve Profiles',
                      style: GoogleFonts.poppins(
                        fontSize: 18.0 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadPendingProfiles,
                      child: Container(
                        padding: EdgeInsets.all(8.0 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: DAColors.primaryGreen,
                          size: 24.0 * scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// CONTENT
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: DAColors.primaryGreen,
                        ),
                        SizedBox(height: 24.0 * scale),
                        Text(
                          'Loading pending profiles...',
                          style: GoogleFonts.poppins(
                            fontSize: 14.0 * scale,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : !_hasInternet
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 48.0 * scale,
                              color: Colors.red.shade400,
                            ),
                            SizedBox(height: 16.0 * scale),
                            Text(
                              'No Internet Connection',
                              style: GoogleFonts.poppins(
                                fontSize: 16.0 * scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade600,
                              ),
                            ),
                            SizedBox(height: 8.0 * scale),
                            Text(
                              'Please check your connection and try again',
                              style: GoogleFonts.poppins(
                                fontSize: 12.0 * scale,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24.0 * scale),
                            ElevatedButton.icon(
                              onPressed: _loadPendingProfiles,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DAColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _loadError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48.0 * scale,
                                  color: Colors.orange.shade400,
                                ),
                                SizedBox(height: 16.0 * scale),
                                Text(
                                  'Error Loading Profiles',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.0 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                                SizedBox(height: 8.0 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
                                  child: Text(
                                    _loadError ?? 'Unknown error occurred',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.0 * scale,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 24.0 * scale),
                                ElevatedButton.icon(
                                  onPressed: _loadPendingProfiles,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DAColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _pendingProfiles.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 48.0 * scale,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16.0 * scale),
                                    Text(
                                      'No pending profiles',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.0 * scale,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 8.0 * scale),
                                    Text(
                                      'All submissions have been reviewed',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.0 * scale,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16.0 * scale),
                                itemCount: _pendingProfiles.length,
                                itemBuilder: (context, index) {
                                  final profile = _pendingProfiles[index];
                                  final docId = profile.tempIdFirebase ?? '';
                          return _buildProfileCard(profile, docId, scale);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(ProfilingData profile, String docId, double scale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.0 * scale),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.firstName} ${profile.middleName ?? ''} ${profile.surname ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 14.0 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.0 * scale),
                      Text(
                        profile.municipality ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 12.0 * scale,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4.0 * scale),
                      Text(
                        'Submitted: ${profile.createdAt?.toString().split(' ')[0] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.0 * scale,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (profile.enumeratorEmail != null && profile.enumeratorEmail!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.0 * scale),
                          child: Text(
                            'Submitted by: ${profile.enumeratorEmail}',
                            style: GoogleFonts.poppins(
                              fontSize: 10.0 * scale,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0 * scale,
                    vertical: 6.0 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8.0 * scale),
                  ),
                  child: Text(
                    'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 10.0 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0 * scale),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showApprovalDialog(profile, docId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DAColors.primaryGreen,
                      padding: EdgeInsets.symmetric(vertical: 10.0 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0 * scale),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.poppins(
                        fontSize: 12.0 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.0 * scale),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectionDialog(profile, docId),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade400),
                      padding: EdgeInsets.symmetric(vertical: 10.0 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0 * scale),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        fontSize: 12.0 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
    }