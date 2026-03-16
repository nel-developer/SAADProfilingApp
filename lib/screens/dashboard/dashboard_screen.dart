import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _approvedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _commoditiesSub;
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  List<Map<String, dynamic>> _approvedProfiles = [];
  List<Map<String, dynamic>> _pendingProfiles = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _commodities = [];

  bool _isLoadingMetrics = true;
  bool _isOnline = true;
  String? _dashboardError;

  DashboardMetrics _metrics = DashboardMetrics.empty();

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
    _initializeOnlineDashboard();
  }

  @override
  void dispose() {
    _approvedSub?.cancel();
    _pendingSub?.cancel();
    _usersSub?.cancel();
    _commoditiesSub?.cancel();
    _connectivitySub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeOnlineDashboard() async {
    await _checkConnectivity();

    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      _handleConnectivityChange(result);
    });

    if (_isOnline) {
      _listenToDashboardData();
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange(result);
    } catch (_) {
      _handleConnectivityChange(ConnectivityResult.none);
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final nowOnline = result != ConnectivityResult.none;
    if (!mounted) return;

    if (_isOnline == nowOnline) return;

    setState(() {
      _isOnline = nowOnline;
      if (!_isOnline) {
        _metrics = DashboardMetrics.empty();
        _isLoadingMetrics = false;
        _dashboardError = 'Dashboard is online-only. Connect to internet.';
      } else {
        _isLoadingMetrics = true;
        _dashboardError = null;
      }
    });

    if (_isOnline) {
      _listenToDashboardData();
    }
  }

  void _cancelDataSubscriptions() {
    _approvedSub?.cancel();
    _approvedSub = null;
    _pendingSub?.cancel();
    _pendingSub = null;
    _usersSub?.cancel();
    _usersSub = null;
    _commoditiesSub?.cancel();
    _commoditiesSub = null;
  }

  void _listenToDashboardData() {
    _cancelDataSubscriptions();

    _approvedSub = _firestore
        .collection('profiling_forms')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (snapshot.metadata.isFromCache) return;
          _approvedProfiles = snapshot.docs.map((doc) => doc.data()).toList();
          _recomputeMetrics();
        }, onError: (error) => _handleDashboardError(error));

    _pendingSub = _firestore
        .collection('profiling_pending')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (snapshot.metadata.isFromCache) return;
          _pendingProfiles = snapshot.docs.map((doc) => doc.data()).toList();
          _recomputeMetrics();
        }, onError: (error) => _handleDashboardError(error));

    _usersSub = _firestore
        .collection('users')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (snapshot.metadata.isFromCache) return;
          _users = snapshot.docs.map((doc) => doc.data()).toList();
          _recomputeMetrics();
        }, onError: (error) => _handleDashboardError(error));

    _commoditiesSub = _firestore
        .collection('commodities')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (snapshot.metadata.isFromCache) return;
          _commodities = snapshot.docs.map((doc) => doc.data()).toList();
          _recomputeMetrics();
        }, onError: (error) => _handleDashboardError(error));
  }

  void _handleDashboardError(Object error) {
    if (!mounted) return;
    setState(() {
      _dashboardError = error.toString();
      _isLoadingMetrics = false;
    });
  }

  void _recomputeMetrics() {
    if (!mounted || !_isOnline) return;

    final profiles = <Map<String, dynamic>>[
      ..._approvedProfiles,
      ..._pendingProfiles,
    ];

    int totalBeneficiaries = 0;

    final uniqueOrgs = <String>{};
    final uniqueCommodityTypes = <String>{};
    final provinceCounts = {
      'Cavite': 0,
      'Laguna': 0,
      'Batangas': 0,
      'Rizal': 0,
      'Quezon': 0,
    };

    int maleCount = 0;
    int femaleCount = 0;
    int childCount = 0;
    int youthCount = 0;
    int adultCount = 0;
    int seniorCount = 0;

    final uniqueMemberKeys = <String>{};

    double agriTotal = 0;
    int agriSamples = 0;
    double nonAgriTotal = 0;
    int nonAgriSamples = 0;

    for (final profile in profiles) {
      final coopName = _asString(profile['cooperativeName']);
      if (coopName.isNotEmpty) uniqueOrgs.add(coopName.toLowerCase());

      uniqueMemberKeys.add(_profileIdentityKey(profile));

      final sex = _asString(profile['sex']).toLowerCase();
      if (sex == 'male' || sex == 'm') {
        maleCount++;
      } else if (sex == 'female' || sex == 'f') {
        femaleCount++;
      }

      final age = _ageFromDateOfBirth(profile['dateOfBirth']);
      if (age != null) {
        if (age <= 15) {
          childCount++;
        } else if (age <= 30) {
          youthCount++;
        } else if (age <= 59) {
          adultCount++;
        } else {
          seniorCount++;
        }
      }

      final province = _asString(profile['province']).toLowerCase();
      if (province.contains('cavite')) {
        provinceCounts['Cavite'] = (provinceCounts['Cavite'] ?? 0) + 1;
      }
      if (province.contains('laguna')) {
        provinceCounts['Laguna'] = (provinceCounts['Laguna'] ?? 0) + 1;
      }
      if (province.contains('batangas')) {
        provinceCounts['Batangas'] = (provinceCounts['Batangas'] ?? 0) + 1;
      }
      if (province.contains('rizal')) {
        provinceCounts['Rizal'] = (provinceCounts['Rizal'] ?? 0) + 1;
      }
      if (province.contains('quezon')) {
        provinceCounts['Quezon'] = (provinceCounts['Quezon'] ?? 0) + 1;
      }

      final agri = _parseDouble(profile['agriRelatedIncome']);
      if (agri != null) {
        agriTotal += agri;
        agriSamples++;
      }

      final nonAgri = _parseDouble(profile['nonAgriRelatedIncome']);
      if (nonAgri != null) {
        nonAgriTotal += nonAgri;
        nonAgriSamples++;
      }

      final primaryCommodity = _asString(profile['primaryCommodity']);
      if (primaryCommodity.isNotEmpty) {
        uniqueCommodityTypes.add(primaryCommodity.toLowerCase());
      }
    }

    totalBeneficiaries = uniqueMemberKeys.length;

    for (final commodity in _commodities) {
      final type = _asString(commodity['type']);
      if (type.isNotEmpty) {
        uniqueCommodityTypes.add(type.toLowerCase());
      }
    }

    final double avgAgri = agriSamples > 0 ? agriTotal / agriSamples : 0.0;
    final double avgNonAgri = nonAgriSamples > 0
        ? nonAgriTotal / nonAgriSamples
        : 0.0;

    setState(() {
      _metrics = DashboardMetrics(
        totalRegisteredOrganizations: uniqueOrgs.length,
        totalSaadBeneficiaries: totalBeneficiaries,
        totalRegisteredMembers: uniqueMemberKeys.length,
        totalMainCommodities: uniqueCommodityTypes.length,
        averageGrossAgriIncome: avgAgri,
        averageGrossNonAgriIncome: avgNonAgri,
        genderMaleCount: maleCount,
        genderFemaleCount: femaleCount,
        ageChildCount: childCount,
        ageYouthCount: youthCount,
        ageAdultCount: adultCount,
        ageSeniorCount: seniorCount,
        provinceCounts: provinceCounts,
        totalUsers: _users.length,
      );
      _isLoadingMetrics = false;
      _dashboardError = null;
    });
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final normalized = value
        .toString()
        .replaceAll(',', '')
        .replaceAll('₱', '')
        .trim();
    return double.tryParse(normalized);
  }

  int? _ageFromDateOfBirth(dynamic dobRaw) {
    final dobText = _asString(dobRaw);
    if (dobText.isEmpty) return null;

    DateTime? dob = DateTime.tryParse(dobText);

    if (dob == null && dobText.contains('/')) {
      final parts = dobText.split('/');
      if (parts.length == 3) {
        final a = int.tryParse(parts[0]);
        final b = int.tryParse(parts[1]);
        final c = int.tryParse(parts[2]);
        if (a != null && b != null && c != null) {
          // Try MM/DD/YYYY then DD/MM/YYYY
          dob =
              DateTime.tryParse(
                '${c.toString().padLeft(4, '0')}-${a.toString().padLeft(2, '0')}-${b.toString().padLeft(2, '0')}',
              ) ??
              DateTime.tryParse(
                '${c.toString().padLeft(4, '0')}-${b.toString().padLeft(2, '0')}-${a.toString().padLeft(2, '0')}',
              );
        }
      }
    }

    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    final beforeBirthday =
        now.month < dob.month || (now.month == dob.month && now.day < dob.day);
    if (beforeBirthday) age--;
    if (age < 0 || age > 120) return null;
    return age;
  }

  String _profileIdentityKey(Map<String, dynamic> profile) {
    final saad = _asString(profile['saadIdNo']).toLowerCase();
    if (saad.isNotEmpty) return 'saad:$saad';

    final firebaseId = _asString(profile['tempIdFirebase']).toLowerCase();
    if (firebaseId.isNotEmpty) return 'fid:$firebaseId';

    final localId = _asString(profile['tempIdLocal']).toLowerCase();
    if (localId.isNotEmpty) return 'lid:$localId';

    final first = _asString(profile['firstName']).toLowerCase();
    final surname = _asString(profile['surname']).toLowerCase();
    final dob = _asString(profile['dateOfBirth']).toLowerCase();
    final fallback = '$first|$surname|$dob';
    if (fallback.replaceAll('|', '').isNotEmpty) return 'name:$fallback';

    return 'unknown:${profile.hashCode}';
  }

  String _formatCurrency(double amount) {
    final rounded = amount.isNaN || amount.isInfinite ? 0 : amount;
    return '₱${rounded.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final headerHeight =
        height *
        (isLargeTablet
            ? 0.18
            : isTablet
            ? 0.22
            : 0.28);
    final titleFontSize = isLargeTablet
        ? 36.0
        : isTablet
        ? 30.0
        : width * 0.065;
    final subtitleFontSize = isLargeTablet
        ? 14.0
        : isTablet
        ? 12.0
        : width * 0.03;

    if (!_isOnline) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Dashboard is available online only.\nPlease connect to the internet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoadingMetrics) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8E8E8),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                                color: Colors.white.withValues(alpha: 0.9),
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
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Dashboard',
                                  style: GoogleFonts.poppins(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All of those numbers are available here',
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
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
                  /// DASHBOARD OVERVIEW TITLE
                  Text(
                    'Dashboard Overview',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeTablet
                          ? 24.0
                          : isTablet
                          ? 22.0
                          : 20.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),

                  /// STATS CARDS ROW 1
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Registered\nOrganizations',
                          _metrics.totalRegisteredOrganizations.toString(),
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Total SAAD\nBeneficiaries',
                          _metrics.totalSaadBeneficiaries.toString(),
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Total Registered\nMembers',
                          _metrics.totalRegisteredMembers.toString(),
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.02),

                  /// STATS CARDS ROW 2
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Number of Main\nCommodities',
                          _metrics.totalMainCommodities.toString(),
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Average Gross\nAgri-Related\nIncome',
                          _formatCurrency(_metrics.averageGrossAgriIncome),
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Average Gross\nNon Agri-Related\nIncome',
                          _formatCurrency(_metrics.averageGrossNonAgriIncome),
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.03),

                  /// BENEFICIARY DEMOGRAPHICS TITLE
                  Text(
                    'Beneficiary Demographics',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeTablet
                          ? 24.0
                          : isTablet
                          ? 22.0
                          : 20.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),

                  /// PIE CHARTS ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildGenderChart(
                          isTablet,
                          isLargeTablet,
                          width,
                          _metrics,
                        ),
                      ),
                      SizedBox(width: width * 0.04),
                      Expanded(
                        child: _buildAgeGroupChart(
                          isTablet,
                          isLargeTablet,
                          width,
                          _metrics,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.03),

                  /// GEOGRAPHIC COVERAGE TITLE
                  Text(
                    'Geographic Coverage',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeTablet
                          ? 24.0
                          : isTablet
                          ? 22.0
                          : 20.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),

                  /// BAR CHART
                  _buildBarChart(
                    isTablet,
                    isLargeTablet,
                    width,
                    height,
                    _metrics,
                  ),

                  if (_dashboardError != null) ...[
                    SizedBox(height: height * 0.02),
                    Text(
                      'Dashboard sync warning: $_dashboardError',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 12 : 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],

                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    bool isTablet,
    bool isLargeTablet,
  ) {
    final titleFontSize = isLargeTablet
        ? 12.0
        : isTablet
        ? 11.0
        : 10.0;
    final valueFontSize = isLargeTablet
        ? 32.0
        : isTablet
        ? 28.0
        : 24.0;

    return Container(
      height: isLargeTablet
          ? 140
          : isTablet
          ? 130
          : 120, // Fixed equal height
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: DAColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DAColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Flexible(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChart(
    bool isTablet,
    bool isLargeTablet,
    double width,
    DashboardMetrics metrics,
  ) {
    final titleFontSize = isLargeTablet
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final labelFontSize = isLargeTablet
        ? 12.0
        : isTablet
        ? 11.0
        : 10.0;
    final chartSize = isLargeTablet
        ? 180.0
        : isTablet
        ? 160.0
        : 140.0;
    final containerHeight = isLargeTablet
        ? 280.0
        : isTablet
        ? 260.0
        : 240.0;

    final male = metrics.genderMaleCount.toDouble();
    final female = metrics.genderFemaleCount.toDouble();
    final total = male + female;

    final malePct = total > 0 ? ((male / total) * 100).round() : 0;
    final femalePct = total > 0 ? ((female / total) * 100).round() : 0;

    return Container(
      height: containerHeight, // Fixed equal height
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Gender Distribution',
            style: GoogleFonts.poppins(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          if (total == 0)
            Text(
              'No gender data yet',
              style: GoogleFonts.poppins(
                fontSize: labelFontSize + 1,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            SizedBox(
              height: chartSize,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 0,
                  sections: [
                    PieChartSectionData(
                      color: DAColors.primaryGreen,
                      value: male,
                      title: 'Male\n$malePct%',
                      radius: chartSize * 0.45,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: DAColors.orange,
                      value: female,
                      title: 'Female\n$femalePct%',
                      radius: chartSize * 0.45,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupChart(
    bool isTablet,
    bool isLargeTablet,
    double width,
    DashboardMetrics metrics,
  ) {
    final titleFontSize = isLargeTablet
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final labelFontSize = isLargeTablet
        ? 10.0
        : isTablet
        ? 9.0
        : 8.0;
    final chartSize = isLargeTablet
        ? 180.0
        : isTablet
        ? 160.0
        : 140.0;
    final containerHeight = isLargeTablet
        ? 280.0
        : isTablet
        ? 260.0
        : 240.0;

    final senior = metrics.ageSeniorCount.toDouble();
    final youth = metrics.ageYouthCount.toDouble();
    final adult = metrics.ageAdultCount.toDouble();
    final child = metrics.ageChildCount.toDouble();
    final total = senior + youth + adult + child;

    int pct(double value) => total > 0 ? ((value / total) * 100).round() : 0;

    return Container(
      height: containerHeight, // Fixed equal height (same as Gender chart)
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Age Group',
            style: GoogleFonts.poppins(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          if (total == 0)
            Text(
              'No age data yet',
              style: GoogleFonts.poppins(
                fontSize: labelFontSize + 1,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            SizedBox(
              height: chartSize,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 0,
                  sections: [
                    PieChartSectionData(
                      color: DAColors.primaryGreen,
                      value: senior,
                      title: 'Senior\n(60+)\n${pct(senior)}%',
                      radius: chartSize * 0.45,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    PieChartSectionData(
                      color: DAColors.orange,
                      value: youth,
                      title: 'Youth\n(16-30)\n${pct(youth)}%',
                      radius: chartSize * 0.45,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.grey.shade500,
                      value: adult,
                      title: 'Adult\n(31-59)\n${pct(adult)}%',
                      radius: chartSize * 0.45,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF0066CC),
                      value: child,
                      title: 'Child\n(0-15)\n${pct(child)}%',
                      radius: chartSize * 0.45,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    bool isTablet,
    bool isLargeTablet,
    double width,
    double height,
    DashboardMetrics metrics,
  ) {
    final labelFontSize = isLargeTablet
        ? 14.0
        : isTablet
        ? 13.0
        : 12.0;
    final chartHeight = isLargeTablet
        ? 300.0
        : isTablet
        ? 250.0
        : height * 0.25;

    final cavite = (metrics.provinceCounts['Cavite'] ?? 0).toDouble();
    final laguna = (metrics.provinceCounts['Laguna'] ?? 0).toDouble();
    final batangas = (metrics.provinceCounts['Batangas'] ?? 0).toDouble();
    final rizal = (metrics.provinceCounts['Rizal'] ?? 0).toDouble();
    final quezon = (metrics.provinceCounts['Quezon'] ?? 0).toDouble();

    final values = [cavite, laguna, batangas, rizal, quezon];
    final maxValue = values.fold<double>(
      0,
      (prev, val) => val > prev ? val : prev,
    );
    final hasData = maxValue > 0;
    final dynamicMaxY = hasData ? (maxValue + 2).clamp(5, 200).toDouble() : 5.0;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// LEGEND
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Cavite', DAColors.primaryGreen, labelFontSize),
              _buildLegendItem('Laguna', DAColors.orange, labelFontSize),
              _buildLegendItem('Batangas', Colors.grey.shade500, labelFontSize),
              _buildLegendItem('Rizal', const Color(0xFF00BCD4), labelFontSize),
              _buildLegendItem(
                'Quezon',
                const Color(0xFF0066CC),
                labelFontSize,
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          /// BAR CHART
          if (!hasData)
            SizedBox(
              height: chartHeight,
              child: Center(
                child: Text(
                  'No geographic data yet',
                  style: GoogleFonts.poppins(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dynamicMaxY,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = [
                            'Cavite',
                            'Laguna',
                            'Batangas',
                            'Rizal',
                            'Quezon',
                          ];
                          final index = value.toInt();
                          if (index < 0 || index >= titles.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[index],
                              style: GoogleFonts.poppins(
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: labelFontSize - 2,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (dynamicMaxY / 4)
                        .clamp(1, 50)
                        .toDouble(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: cavite,
                          color: DAColors.primaryGreen,
                          width: isTablet ? 30 : 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: laguna,
                          color: DAColors.orange,
                          width: isTablet ? 30 : 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: batangas,
                          color: Colors.grey.shade500,
                          width: isTablet ? 30 : 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: rizal,
                          color: const Color(0xFF00BCD4),
                          width: isTablet ? 30 : 20,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 4,
                      barRods: [
                        BarChartRodData(
                          toY: quezon,
                          color: const Color(0xFF0066CC),
                          width: isTablet ? 30 : 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class DashboardMetrics {
  final int totalRegisteredOrganizations;
  final int totalSaadBeneficiaries;
  final int totalRegisteredMembers;
  final int totalMainCommodities;
  final double averageGrossAgriIncome;
  final double averageGrossNonAgriIncome;
  final int genderMaleCount;
  final int genderFemaleCount;
  final int ageChildCount;
  final int ageYouthCount;
  final int ageAdultCount;
  final int ageSeniorCount;
  final Map<String, int> provinceCounts;
  final int totalUsers;

  DashboardMetrics({
    required this.totalRegisteredOrganizations,
    required this.totalSaadBeneficiaries,
    required this.totalRegisteredMembers,
    required this.totalMainCommodities,
    required this.averageGrossAgriIncome,
    required this.averageGrossNonAgriIncome,
    required this.genderMaleCount,
    required this.genderFemaleCount,
    required this.ageChildCount,
    required this.ageYouthCount,
    required this.ageAdultCount,
    required this.ageSeniorCount,
    required this.provinceCounts,
    required this.totalUsers,
  });

  factory DashboardMetrics.empty() {
    return DashboardMetrics(
      totalRegisteredOrganizations: 0,
      totalSaadBeneficiaries: 0,
      totalRegisteredMembers: 0,
      totalMainCommodities: 0,
      averageGrossAgriIncome: 0,
      averageGrossNonAgriIncome: 0,
      genderMaleCount: 0,
      genderFemaleCount: 0,
      ageChildCount: 0,
      ageYouthCount: 0,
      ageAdultCount: 0,
      ageSeniorCount: 0,
      provinceCounts: {
        'Cavite': 0,
        'Laguna': 0,
        'Batangas': 0,
        'Rizal': 0,
        'Quezon': 0,
      },
      totalUsers: 0,
    );
  }
}
