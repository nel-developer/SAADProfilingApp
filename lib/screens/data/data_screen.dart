import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

  bool _isUnsyncLocalRecord(ProfilingData data) {
    final status = (data.status ?? '').trim().toLowerCase();

    // In-progress drafts (status == 'draft' or empty) are mid-profiling saves
    // and must NOT appear in the Unsync tab.
    if (status.isEmpty || status == 'draft') {
      return false;
    }

    // Unsync tab is local-history view: include finalized local records,
    // even if already synced (Pending/Approved), so users can still view
    // their local copy and its status marker.
    if (status == 'unsync' ||
        status == 'unsynced' ||
        status == 'pending approval' ||
        status == 'pending' ||
        status == 'approved') {
      return true;
    }

    return false;
  }

  String _unsyncIdentityKey(ProfilingData data) {
    final firebaseId = (data.tempIdFirebase ?? '').trim();
    if (firebaseId.isNotEmpty) return 'firebase:$firebaseId';

    final localId = (data.tempIdLocal ?? '').trim();
    if (localId.isNotEmpty) return 'local:$localId';

    final folder = (data.farmerFolderName ?? '').trim();
    if (folder.isNotEmpty) return 'folder:$folder';

    final saad = (data.saadIdNo ?? '').trim().toLowerCase();
    final rsbsa = (data.rsbsaFishrIdNo ?? '').trim().toLowerCase();
    final first = (data.firstName ?? '').trim().toLowerCase();
    final middle = (data.middleName ?? '').trim().toLowerCase();
    final surname = (data.surname ?? '').trim().toLowerCase();
    final dob = (data.dateOfBirth ?? '').trim().toLowerCase();
    return 'fallback:$saad|$rsbsa|$first|$middle|$surname|$dob';
  }

  List<ProfilingData> _dedupeUnsyncDrafts(List<ProfilingData> drafts) {
    final deduped = <String, ProfilingData>{};

    for (final draft in drafts) {
      final key = _unsyncIdentityKey(draft);
      final current = deduped[key];
      if (current == null) {
        deduped[key] = draft;
        continue;
      }

      final currentUpdated = current.updatedAt ?? DateTime(1970);
      final candidateUpdated = draft.updatedAt ?? DateTime(1970);
      if (candidateUpdated.isAfter(currentUpdated)) {
        deduped[key] = draft;
      }
    }

    final result = deduped.values.toList();
    result.sort(
      (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
        a.updatedAt ?? DateTime(1970),
      ),
    );
    return result;
  }

  bool _asSuccess(dynamic result) {
    if (result is bool) return result;
    try {
      return result != null && (result as dynamic).success == true;
    } catch (_) {
      return false;
    }
  }

  String _csvCell(dynamic value) {
    final raw = (value ?? '').toString();
    final escaped = raw.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _formatDateOnly(DateTime? value) {
    if (value == null) return '';
    return value.toIso8601String().split('T').first;
  }

  Future<void> _downloadApprovedBasicInformation() async {
    try {
      List<ProfilingData> approvedProfiles = [];
      final user = FirebaseAuth.instance.currentUser;

      if (_isOnline && user != null) {
        approvedProfiles = await _storage.loadApprovedProfiles(user.uid);
      } else {
        approvedProfiles = _approvedData
            .map((entry) => entry['data'])
            .whereType<ProfilingData>()
            .toList();
      }

      if (approvedProfiles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No approved profiles found to export.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final header = [
        'SAAD ID No',
        'RSBSA/FISHR ID No',
        'First Name',
        'Middle Name',
        'Surname',
        'Extension Name',
        'Sex',
        'Date of Birth',
        'Region',
        'Province',
        'Municipality',
        'Barangay',
        'Sitio/Purok',
        'Spouse Name',
        'Main Sources of Income',
        'Enumerator',
        'Approved By',
        'Approved At',
      ];

      final csv = StringBuffer()..writeln(header.map(_csvCell).join(','));

      for (final profile in approvedProfiles) {
        csv.writeln(
          [
            profile.saadIdNo,
            profile.rsbsaFishrIdNo,
            profile.firstName,
            profile.middleName,
            profile.surname,
            profile.extensionName,
            profile.sex,
            profile.dateOfBirth,
            profile.region,
            profile.province,
            profile.municipality,
            profile.barangay,
            profile.sitioPurok,
            profile.spouseName,
            profile.mainSourcesOfIncome,
            profile.enumeratorEmail,
            profile.approverEmail,
            _formatDateOnly(profile.approvedAt),
          ].map(_csvCell).join(','),
        );
      }

      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'CSV export to file is available on mobile/desktop app.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      Directory outputDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        final downloadsPath = (userProfile != null && userProfile.isNotEmpty)
            ? '$userProfile\\Downloads'
            : Directory.current.path;
        outputDir = Directory(downloadsPath);
      } else {
        outputDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final filePath = p.join(
        outputDir.path,
        'approved_basic_information_$timestamp.csv',
      );
      final file = File(filePath);
      await file.writeAsString(csv.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: $filePath'),
          backgroundColor: DAColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export approved basic info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _ensureRequiredIdsBeforeApproval(ProfilingData data) async {
    if (!mounted) return false;

    String rsbsa = data.rsbsaFishrIdNo?.trim() ?? '';
    String saad = data.saadIdNo?.trim() ?? '';
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Required Before Approval'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please provide these IDs to approve profile:'),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: rsbsa,
                    decoration: const InputDecoration(
                      labelText: 'RSBSA / FISHR ID No.',
                      helperText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      rsbsa = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: saad,
                    decoration: InputDecoration(
                      labelText: 'SAAD I.D No.',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      saad = value;
                      if (errorText != null) {
                        setDialogState(() {
                          errorText = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final trimmedRsbsa = rsbsa.trim();
                    final trimmedSaad = saad.trim();

                    if (trimmedSaad.isEmpty) {
                      setDialogState(() {
                        errorText = 'SAAD I.D No. is required.';
                      });
                      return;
                    }

                    FocusScope.of(dialogContext).unfocus();
                    data.rsbsaFishrIdNo = trimmedRsbsa.isEmpty
                        ? null
                        : trimmedRsbsa;
                    data.saadIdNo = trimmedSaad;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return false;
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check initial connectivity
    _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      final isOnline = result != ConnectivityResult.none;
      if (_isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
          debugPrint(
            '🌐 Connectivity changed: ${isOnline ? 'ONLINE' : 'OFFLINE'}',
          );
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
        debugPrint(
          '🌐 Initial connectivity: ${_isOnline ? 'ONLINE' : 'OFFLINE'}',
        );
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
      if (_selectedFilter == 'Unsync') {
        try {
          final diskDrafts = await _storage.loadDraftsFromDiskOnly();
          final unsyncDrafts = diskDrafts.where(_isUnsyncLocalRecord).toList();
          final dedupedUnsyncDrafts = _dedupeUnsyncDrafts(unsyncDrafts);
          debugPrint(
            '✅ Loaded ${unsyncDrafts.length} local Unsync profile(s) from disk; '
            'showing ${dedupedUnsyncDrafts.length} after dedupe',
          );

          final unsyncDataMaps = dedupedUnsyncDrafts
              .map(_buildDataMap)
              .toList();

          if (mounted) {
            setState(() {
              _unsyncData = unsyncDataMaps;
            });
          }
          debugPrint(
            '✅ Unsync tab ready with ${unsyncDataMaps.length} local profiles',
          );
        } catch (e) {
          debugPrint('❌ Error loading disk drafts: $e');
        }
      }

      // NOTE: Approved data are loaded ONLY when user clicks the Approved tab
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
        pendingDrafts = await _storage.loadPendingProfiles().timeout(
          const Duration(seconds: 15),
        );
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _loadingPending = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⏱️ Loading pending profiles timed out. Try again.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      debugPrint(
        '✅ Loaded ${pendingDrafts.length} pending profile(s) from Firebase',
      );

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
          approvedDrafts = await _storage
              .loadApprovedProfiles(user.uid)
              .timeout(const Duration(seconds: 15));
        } on TimeoutException {
          if (mounted) {
            setState(() {
              _loadingApproved = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⏱️ Loading approved profiles timed out. Try again.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        debugPrint(
          '✅ Loaded ${approvedDrafts.length} approved profile(s) from Firebase',
        );

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
    final rawStatus = (draft.status ?? 'Unsync').trim();
    final normalizedStatus = rawStatus.toLowerCase();
    String status;

    // Map status values for display
    if (normalizedStatus == 'approved') {
      status = 'Approved';
    } else if (normalizedStatus == 'pending approval' ||
        normalizedStatus == 'pending') {
      status = 'Pending';
    } else {
      status = 'Unsync';
    }

    debugPrint(
      '📝 Draft: ${draft.firstName} ${draft.surname} - Status: $status (dbStatus: ${draft.status})',
    );

    final fullName =
        '${draft.firstName ?? ''} ${draft.middleName ?? ''} ${draft.surname ?? ''}'
            .trim();
    String fallbackName = fullName;
    if (fallbackName.isEmpty) {
      final folder = (draft.farmerFolderName ?? '').trim();
      if (folder.isNotEmpty) {
        final parts = folder.split('_');
        if (parts.length >= 3) {
          fallbackName = '${parts[0]} ${parts[1]}'.toUpperCase();
        }
      }
    }
    if (fallbackName.isEmpty) {
      final saad = (draft.saadIdNo ?? '').trim();
      fallbackName = saad.isNotEmpty ? 'SAAD: $saad' : 'N/A';
    }

    return {
      'farmerName': fallbackName,
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
    final scaleW = (MediaQuery.of(context).size.width / _refWidth).clamp(
      0.5,
      2.0,
    );
    final scaleH = (MediaQuery.of(context).size.height / _refHeight).clamp(
      0.5,
      2.0,
    );
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

    // Action buttons should follow the active tab context.
    // If a pending profile is shown inside the Unsync tab (for visibility),
    // keep Unsync actions and do not show Approve/Decline there.
    final String modalStatus = _selectedFilter == 'Unsync'
        ? 'Unsync'
        : (data['status'] ?? 'Unsync');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataViewModal(
          profileData: data,
          dataStatus: modalStatus,
          onEdit: canApprove
              ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Edit functionality'),
                      backgroundColor: DAColors.primaryGreen,
                    ),
                  );
                }
              : null,
          onSync: () async {
            bool loadingDialogShown = false;
            BuildContext? loadingDialogContext;
            try {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Not logged in'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final profilingData = data['data'] as ProfilingData;
              final normalizedStatus = (profilingData.status ?? '')
                  .trim()
                  .toLowerCase();
              if (normalizedStatus == 'pending approval' ||
                  normalizedStatus == 'pending' ||
                  normalizedStatus == 'approved') {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      normalizedStatus == 'approved'
                          ? 'This profile is already approved and cannot be synced again.'
                          : 'This profile is already pending approval and cannot be synced again.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              // Show loading dialog
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (dialogContext) {
                  loadingDialogContext = dialogContext;
                  loadingDialogShown = true;
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DAColors.primaryGreen,
                          ),
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
                final bool isExistingFarmer =
                    profilingData.isExistingFarmer == true;

                // Auto-detect: If profile has recurrence data by year and a saadIdNo,
                // treat as existing farmer even if flag isn't set.
                final hasRecurrenceData =
                    (profilingData.recurrenceByYear?.isNotEmpty ?? false);
                final hasSaadId =
                    (profilingData.saadIdNo?.trim().isNotEmpty ?? false);
                final shouldTryExistingFarmerSync =
                    hasRecurrenceData &&
                    hasSaadId &&
                    (profilingData.selectedExistingSaadId?.trim().isNotEmpty ??
                        false);

                final syncResult =
                    await (isExistingFarmer || shouldTryExistingFarmerSync
                            ? _storage.syncExistingRecurrenceToApproved(
                                profilingData,
                                user.uid,
                              )
                            : _storage.syncToFirestore(profilingData, user.uid))
                        .timeout(const Duration(seconds: 30));
                final bool success = _asSuccess(syncResult);

                if (!mounted) return;

                if (success) {
                  profilingData.status =
                      (isExistingFarmer || shouldTryExistingFarmerSync)
                      ? 'Approved'
                      : 'Pending Approval';
                  await _storage.saveDraftLocally(
                    profilingData,
                    setAsCurrent: false,
                  );

                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Close the modal
                  }
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isExistingFarmer
                              ? '✅ Recurrence synced and auto-approved'
                              : '✅ Data synced successfully',
                        ),
                        backgroundColor: DAColors.primaryGreen,
                      ),
                    );
                    // Reload the current tab
                    if (_selectedFilter == 'Pending') {
                      await _loadPendingProfiles();
                    } else if (_selectedFilter == 'Unsync') {
                      await _loadProfilingData();
                    }
                    // Reload both pending and approved for existing farmer sync
                    if ((isExistingFarmer || shouldTryExistingFarmerSync)) {
                      await _loadPendingProfiles();
                      await _loadApprovedProfiles();
                    }
                  }
                } else {
                  if (!mounted) return;
                  String errorMessage = 'Sync failed. Check your connection.';
                  try {
                    final dynamic result = syncResult;
                    final message = result?.errorMessage?.toString();
                    if (message != null && message.trim().isNotEmpty) {
                      errorMessage = message.trim();
                    }
                  } catch (_) {}
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $errorMessage'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } on TimeoutException {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏱️ Sync taking too long. Try again.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } finally {
                if (loadingDialogShown && loadingDialogContext != null) {
                  final navigator = Navigator.of(
                    loadingDialogContext!,
                    rootNavigator: true,
                  );
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                  loadingDialogShown = false;
                  loadingDialogContext = null;
                }
              }
            } catch (e) {
              if (!mounted) return;
              if (loadingDialogShown &&
                  loadingDialogContext != null &&
                  Navigator.of(
                    loadingDialogContext!,
                    rootNavigator: true,
                  ).canPop()) {
                Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
                loadingDialogShown = false;
                loadingDialogContext = null;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onApprove: canApprove
              ? () async {
                  bool loadingDialogShown = false;
                  BuildContext? loadingDialogContext;

                  try {
                    final profilingData = data['data'] as ProfilingData;
                    final docId = profilingData.tempIdFirebase;

                    if (docId == null || docId.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Error: Document ID not found'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final canProceed = await _ensureRequiredIdsBeforeApproval(
                      profilingData,
                    );
                    if (!canProceed) {
                      return;
                    }

                    // Show loading dialog
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      useRootNavigator: true,
                      builder: (dialogContext) {
                        loadingDialogContext = dialogContext;
                        return AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  DAColors.primaryGreen,
                                ),
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
                    loadingDialogShown = true;

                    final approveResult = await _storage.approvePendingProfile(
                      docId,
                      profilingData,
                    );
                    final bool success = _asSuccess(approveResult);

                    if (!mounted) return;
                    if (loadingDialogShown &&
                        loadingDialogContext != null &&
                        Navigator.of(
                          loadingDialogContext!,
                          rootNavigator: true,
                        ).canPop()) {
                      Navigator.of(
                        loadingDialogContext!,
                        rootNavigator: true,
                      ).pop();
                      loadingDialogShown = false;
                      loadingDialogContext = null;
                    }

                    if (success) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
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
                    if (loadingDialogShown &&
                        loadingDialogContext != null &&
                        Navigator.of(
                          loadingDialogContext!,
                          rootNavigator: true,
                        ).canPop()) {
                      Navigator.of(
                        loadingDialogContext!,
                        rootNavigator: true,
                      ).pop();
                      loadingDialogShown = false;
                      loadingDialogContext = null;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
          onDecline: canApprove
              ? () async {
                  bool loadingDialogShown = false;
                  BuildContext? loadingDialogContext;

                  try {
                    final profilingData = data['data'] as ProfilingData;
                    final docId = profilingData.tempIdFirebase;

                    if (docId == null || docId.isEmpty) {
                      if (!mounted) return;
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
                      useRootNavigator: true,
                      builder: (dialogContext) {
                        loadingDialogContext = dialogContext;
                        return AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  DAColors.primaryGreen,
                                ),
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
                    loadingDialogShown = true;

                    final rejectResult = await _storage.rejectPendingProfile(
                      docId,
                      'Declined by moderator',
                    );
                    final bool success = _asSuccess(rejectResult);

                    if (!mounted) return;
                    if (loadingDialogShown &&
                        loadingDialogContext != null &&
                        Navigator.of(
                          loadingDialogContext!,
                          rootNavigator: true,
                        ).canPop()) {
                      Navigator.of(
                        loadingDialogContext!,
                        rootNavigator: true,
                      ).pop();
                      loadingDialogShown = false;
                      loadingDialogContext = null;
                    }

                    if (success) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
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
                    if (loadingDialogShown &&
                        loadingDialogContext != null &&
                        Navigator.of(
                          loadingDialogContext!,
                          rootNavigator: true,
                        ).canPop()) {
                      Navigator.of(
                        loadingDialogContext!,
                        rootNavigator: true,
                      ).pop();
                      loadingDialogShown = false;
                      loadingDialogContext = null;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
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
                      _loadProfilingData();
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
                            content: Text(
                              '📴 You are offline. Connect to internet to view pending profiles.',
                            ),
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
                      debugPrint(
                        '📱 Pending tab selected - loading from Firebase...',
                      );
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
                            content: Text(
                              '📴 You are offline. Connect to internet to view approved profiles.',
                            ),
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
                      debugPrint(
                        '📱 Approved tab selected - loading from Firebase...',
                      );
                      _loadApprovedProfiles();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_selectedFilter == 'Approved')
            Padding(
              padding: EdgeInsets.fromLTRB(
                filterPaddingH,
                8 * scale,
                filterPaddingH,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _downloadApprovedBasicInformation,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Basic Info'),
                  style: TextButton.styleFrom(
                    foregroundColor: DAColors.primaryGreen,
                  ),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DAColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'Pending'
                                ? 'Loading pending profiles...'
                                : 'Loading approved profiles...',
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
