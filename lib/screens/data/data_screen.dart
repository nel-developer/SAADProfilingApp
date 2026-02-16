import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/widgets/filter_tab.dart';
import 'package:da_project_1/screens/data/data_card.dart';
import 'package:da_project_1/screens/data/data_view_modal.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';
import 'package:da_project_1/services/firebase_auth_service.dart';
import 'package:da_project_1/models/profiling_data.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  String _selectedFilter = 'Unsync'; // Default to Unsync (local data)
  final TextEditingController _searchController = TextEditingController();
  final ProfilingStorageService _storage = ProfilingStorageService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Tab-aware data lists for lazy loading
  List<Map<String, dynamic>> _unsyncData = [];
  List<Map<String, dynamic>> _pendingData = [];
  List<Map<String, dynamic>> _approvedData = [];
  bool _loadingPending = false;
  bool _loadingApproved = false;
  bool _isOnline = true; // Default to true, will be checked on init

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check initial connectivity
    _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      if (_isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
          debugPrint('🌐 Connectivity changed: ${isOnline ? 'ONLINE' : 'OFFLINE'}');
        });
        
        // Clear Pending/Approved data when going offline
        if (!isOnline) {
          setState(() {
            _pendingData = [];
            _approvedData = [];
            _loadingPending = false;
            _loadingApproved = false;
          });
        }
      }
    });
    
    // Load data without awaiting to avoid blocking UI
    _loadProfilingData();
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

    _leafLeftAnim = Tween<double>(begin: -120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _leafRightAnim = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      setState(() {
        _isOnline = result != ConnectivityResult.none;
        debugPrint('🌐 Initial connectivity: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
      });
    } catch (e) {
      debugPrint('⚠️ Error checking connectivity: $e');
    }
  }

  

  Future<void> _loadProfilingData() async {
    try {
      await _storage.init();
      
      // INSTANT LOAD: Load local Unsync profiles only (no network needed)
      // Only load if Unsync tab is selected or on init
      if (_selectedFilter == 'Unsync' || _selectedFilter == 'All') {
        try {
          final diskDrafts = await _storage.loadDraftsFromDiskOnly();
          debugPrint('✅ Loaded ${diskDrafts.length} local Unsync profile(s) from disk');
          
          if (mounted) {
            setState(() {
              _unsyncData = diskDrafts.map((d) {
                d.status ??= 'Unsync';
                return _buildDataMap(d);
              }).toList();
            });
          }
          debugPrint('✅ Unsync tab ready with ${_unsyncData.length} local profiles');
        } catch (e) {
          debugPrint('❌ Error loading disk drafts: $e');
        }
      }
      
      // NOTE: Pending and Approved data are loaded ONLY when user clicks their tabs
      // See: onTap handlers in FilterTab widgets below
      
    } catch (e) {
      debugPrint('❌ Error in _loadProfilingData: $e');
    }
  }

  Future<void> _loadPendingProfiles() async {
    if (_loadingPending) return;

    try {
      // Keep any existing _pendingData visible while fetching so UI
      // remains responsive; only set loading flag and replace when done.
      setState(() {
        _loadingPending = true;
      });
      
      List<ProfilingData> pendingDrafts = [];
      try {
        pendingDrafts = await _storage.loadPendingProfiles().timeout(const Duration(seconds: 15));
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _loadingPending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏱️ Loading pending profiles timed out. Try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      debugPrint('✅ Loaded ${pendingDrafts.length} pending profile(s) from Firebase');
      
      if (mounted) {
        final newList = pendingDrafts.map((d) {
          d.status = 'Pending Approval';
          return _buildDataMap(d);
        }).toList();
        setState(() {
          _pendingData = newList;
          _loadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingData = []; // Ensure data is cleared on error
          _loadingPending = false;
        });
      }
      debugPrint('❌ Error loading pending profiles: $e');
    }
  }

  Future<void> _loadApprovedProfiles() async {
    if (_loadingApproved) return;

    try {
      // Keep any existing _approvedData visible while fetching so the
      // UI doesn't show a blocking spinner; replace the list when fetch completes.
      setState(() {
        _loadingApproved = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<ProfilingData> approvedDrafts = [];
        try {
          approvedDrafts = await _storage.loadApprovedProfiles(user.uid).timeout(const Duration(seconds: 15));
        } on TimeoutException {
          if (mounted) {
            setState(() {
              _loadingApproved = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏱️ Loading approved profiles timed out. Try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        debugPrint('✅ Loaded ${approvedDrafts.length} approved profile(s) from Firebase');

        if (mounted) {
          final newList = approvedDrafts.map((d) {
            d.status = 'Approved';
            return _buildDataMap(d);
          }).toList();
          setState(() {
            _approvedData = newList;
            _loadingApproved = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingApproved = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _approvedData = []; // Ensure data is cleared on error
          _loadingApproved = false;
        });
      }
      debugPrint('❌ Error loading approved profiles: $e');
    }
  }

  Map<String, dynamic> _buildDataMap(ProfilingData draft) {
    // Determine status based on the status field only
    String status = draft.status ?? 'Unsync';
    
    // Map status values for display
    if (status == 'Approved') {
      status = 'Approved';
    } else if (status == 'Pending Approval') {
      status = 'Pending';
    } else {
      status = 'Unsync';
    }

    debugPrint('📝 Draft: ${draft.firstName} ${draft.surname} - Status: $status (dbStatus: ${draft.status})');

    return {
      'farmerName': '${draft.firstName ?? ''} ${draft.middleName ?? ''} ${draft.surname ?? ''}'.trim(),
      'location': '${draft.municipality ?? ''}, ${draft.province ?? ''}',
      'commodity': draft.primaryCommodity ?? 'N/A',
      'enumerator': draft.enumeratorEmail ?? 'Current User',
      'date': draft.updatedAt?.toString().split(' ')[0] ?? '2026-01-28',
      'status': status,
      'data': draft,
    };
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload based on currently selected tab to get fresh data
      if (_selectedFilter == 'Unsync') {
        _loadProfilingData();
      } else if (_selectedFilter == 'Pending') {
        _loadPendingProfiles();
      } else if (_selectedFilter == 'Approved') {
        _loadApprovedProfiles();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  Future<bool> _canApproveProfiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final role = await _authService.getUserRole(user.uid);
    final roleLower = role?.toLowerCase();
    return roleLower == 'admin' || roleLower == 'moderator';
  }

  List<Map<String, dynamic>> get _filteredData {
    // Each tab shows ONLY its own data - no merging
    if (_selectedFilter == 'Unsync') {
      return _unsyncData;
    } else if (_selectedFilter == 'Pending') {
      return _pendingData;
    } else if (_selectedFilter == 'Approved') {
      return _approvedData;
    }
    return []; // Fallback (should not happen)
  }

  bool get _isLoading {
    // Show spinner only if the currently selected tab is loading.
    if (_selectedFilter == 'Pending') return _loadingPending;
    if (_selectedFilter == 'Approved') return _loadingApproved;
    return false;
  }

  void _openDataViewModal(Map<String, dynamic> data) async {
    // Check if user can approve profiles (only Moderators and Admins)
    final canApprove = await _canApproveProfiles();
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataViewModal(
          profileData: data,
          dataStatus: data['status'],
          onEdit: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Edit functionality'),
                backgroundColor: DAColors.primaryGreen,
              ),
            );
          },
          onSync: () async {
            try {
              final user = FirebaseAuth.instance.currentUser;
              
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Not logged in'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final profilingData = data['data'] as ProfilingData;
              
              // Show loading dialog
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(DAColors.primaryGreen),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Syncing to Firebase...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
              
              try {
                final success = await _storage.syncToFirestore(profilingData, user.uid);
                
                if (!mounted) return;
                Navigator.pop(context); // Close the loading dialog
                
                if (success) {
                  Navigator.pop(context); // Close the modal
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  if (mounted) {
                    // Local copy retained per user preference; do not delete automatically
                    debugPrint('ℹ️ Local copy retained after sync for offline reference');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Data synced successfully'),
                        backgroundColor: DAColors.primaryGreen,
                      ),
                    );
                    // Reload the current tab
                    if (_selectedFilter == 'Pending') {
                      await _loadPendingProfiles();
                    } else if (_selectedFilter == 'Unsync') {
                      await _loadProfilingData();
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Sync failed. Check your connection.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } on TimeoutException {
                if (!mounted) return;
                Navigator.pop(context); // Close the loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏱️ Sync taking too long. Try again.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onApprove: canApprove ? () async {
            Navigator.pop(context);
            
            try {
              final profilingData = data['data'] as ProfilingData;
              final docId = profilingData.tempIdFirebase;
              
              if (docId == null || docId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error: Document ID not found'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Show loading dialog
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return AlertDialog(
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
              
              final success = await _storage.approvePendingProfile(docId, profilingData);
              
              if (!mounted) return;
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Profile approved successfully'),
                    backgroundColor: DAColors.primaryGreen,
                  ),
                );
                // Reload pending and approved data
                await _loadPendingProfiles();
                await _loadApprovedProfiles();
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } : null,
          onDecline: canApprove ? () async {
            Navigator.pop(context);
            
            try {
              final profilingData = data['data'] as ProfilingData;
              final docId = profilingData.tempIdFirebase;
              
              if (docId == null || docId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error: Document ID not found'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Show loading dialog
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(DAColors.primaryGreen),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Declining profile...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
              
              final success = await _storage.rejectPendingProfile(docId, 'Declined by moderator');
              
              if (!mounted) return;
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Profile declined'),
                    backgroundColor: DAColors.red,
                  ),
                );
                // Reload pending data
                await _loadPendingProfiles();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Failed to decline profile'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);

    final headerHeight = _refHeight * 0.28 * scale;
    final titleFontSize = _refWidth * 0.065 * scale;
    final subtitleFontSize = _refWidth * 0.03 * scale;
    final searchPaddingH = _refWidth * 0.06 * scale;
    final searchPaddingTop = _refHeight * 0.025 * scale;
    final searchPaddingBottom = _refHeight * 0.02 * scale;
    final filterPaddingH = _refWidth * 0.06 * scale;
    final filterSpacing = _refWidth * 0.025 * scale;
    final listPaddingH = _refWidth * 0.06 * scale;
    final listPaddingV = _refHeight * 0.01 * scale;
    final cardSpacing = _refHeight * 0.02 * scale;
    final afterFilterSpacing = _refHeight * 0.025 * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Column(
        children: [
          // Offline Banner
          if (!_isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.signal_wifi_off, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'You are offline - Unsync only',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          /// GREEN HEADER SECTION
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
                        child: child!,
                      ),
                    );
                  },
                  child: Container(
                    height: headerHeight,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: _refWidth * 0.06 * scale,
                      vertical: _refHeight * 0.025 * scale,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Data',
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Profiling Data is all here',
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding: EdgeInsets.fromLTRB(
              searchPaddingH,
              searchPaddingTop,
              searchPaddingH,
              searchPaddingBottom,
            ),
            child: CustomTextField(
              controller: _searchController,
              hintText: '',
              prefixIcon: Icons.search,
              isSearch: true,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          /// FILTER TABS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: filterPaddingH),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterTab(
                    label: 'Unsync',
                    color: DAColors.red,
                    isSelected: _selectedFilter == 'Unsync',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Unsync';
                      });
                      debugPrint('📱 Unsync tab selected - showing local data');
                    },
                  ),
                  SizedBox(width: filterSpacing),
                  FilterTab(
                    label: 'Pending',
                    color: const Color(0xFFFFCC00),
                    isSelected: _selectedFilter == 'Pending',
                    onTap: () {
                      if (!_isOnline) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📴 You are offline. Connect to internet to view pending profiles.'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        _selectedFilter = 'Pending';
                      });
                      // Lazy-load pending from Firebase only when tab clicked
                      debugPrint('📱 Pending tab selected - loading from Firebase...');
                      _loadPendingProfiles();
                    },
                  ),
                  SizedBox(width: filterSpacing),
                  FilterTab(
                    label: 'Approved',
                    color: DAColors.primaryGreen,
                    isSelected: _selectedFilter == 'Approved',
                    onTap: () {
                      if (!_isOnline) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📴 You are offline. Connect to internet to view approved profiles.'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      
                      setState(() {
                        _selectedFilter = 'Approved';
                      });
                      // Lazy-load approved from Firebase only when tab clicked
                      debugPrint('📱 Approved tab selected - loading from Firebase...');
                      _loadApprovedProfiles();
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: afterFilterSpacing),

          /// DATA LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh based on selected tab
                if (_selectedFilter == 'Unsync') {
                  await _loadProfilingData();
                } else if (_selectedFilter == 'Pending') {
                  await _loadPendingProfiles();
                } else if (_selectedFilter == 'Approved') {
                  await _loadApprovedProfiles();
                }
              },
              color: DAColors.primaryGreen,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(DAColors.primaryGreen),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'Pending' ? 'Loading pending profiles...' : 'Loading approved profiles...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredData.isEmpty
                      ? Center(
                          child: Text(
                            'No ${_selectedFilter.toLowerCase()} profiles',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: listPaddingH,
                        vertical: listPaddingV,
                      ),
                      itemCount: _filteredData.length,
                      itemBuilder: (context, index) {
                        final data = _filteredData[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: cardSpacing),
                          child: DataCard(
                            farmerName: data['farmerName'],
                            location: data['location'],
                      commodity: data['commodity'],
                      enumerator: data['enumerator'],
                      date: data['date'],
                      status: data['status'],
                      onViewTap: () => _openDataViewModal(data),
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