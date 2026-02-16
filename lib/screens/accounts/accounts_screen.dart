import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/widgets/filter_tab.dart';
import 'package:da_project_1/widgets/account_card.dart';
import 'package:da_project_1/widgets/account_role_modal.dart';
import 'package:da_project_1/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  String _selectedFilter = 'Pending'; // Start with Pending to show new registrations
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allAccounts = [];
  bool _isLoading = true;

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
    _checkAccessAndLoad();
  }

  /// Ensure only Admins and Moderators can view this screen
  Future<void> _checkAccessAndLoad() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final role = await _authService.getUserRole(user.uid);
    final roleLower = role?.toLowerCase();
    if (roleLower == null || !(roleLower == 'admin' || roleLower == 'moderator')) {
      // Not allowed — show restricted dialog then pop
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restricted'),
          content: const Text('You do not have access to Accounts.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // Allowed — proceed to load accounts
    await _loadAccounts();
  }

  /// Fetch all users (pending and approved) from Firestore
  Future<void> _loadAccounts() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final accounts = snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        final dateStr = createdAt != null
            ? createdAt.toDate().toString().split(' ')[0]
            : DateTime.now().toString().split(' ')[0];

        // Map role for display (capitalize)
        String roleForDisplay = data['role']?.toString() ?? 'user';
        roleForDisplay = roleForDisplay[0].toUpperCase() + roleForDisplay.substring(1);

        final status = data['accountStatus'] ?? 'pending_review';
        final isPending = status == 'pending_review';

        return {
          'uid': doc.id,
          'name': '${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'email': data['email'] ?? '',
          'role': roleForDisplay,
          'status': isPending ? 'Pending' : 'Active',
          'date': dateStr,
          'isPending': isPending,
          'accountStatus': status,
        };
      }).toList();

      setState(() {
        _allAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading accounts: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e'), backgroundColor: DAColors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return DAColors.red;
      case 'Profiler':
        return const Color(0xFF0066CC); // Blue
      case 'Moderator':
        return const Color(0xFFFFCC00); // Yellow
      case 'Pending':
        return DAColors.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _filteredAccounts {
    return _allAccounts.where((account) {
      if (_selectedFilter == 'Pending') {
        return account['isPending'] == true;
      }
      return account['role'].toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  void _showAccountRoleModal(BuildContext context,
      {Map<String, dynamic>? account, bool isEdit = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AccountRoleModal(
          currentRole: account?['role'],
          onRoleSelected: (selectedRole) async {
            Navigator.pop(dialogContext);
            
            try {
              if (isEdit) {
                // Update existing role
                await _authService.updateUserRole(
                  account!['uid'],
                  selectedRole.toLowerCase(),
                );
              } else {
                // Approve user with new role
                await _authService.approveUserWithRole(
                  account!['uid'],
                  selectedRole.toLowerCase(),
                );
              }
              
              // Reload accounts
              await _loadAccounts();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? 'Account role updated to $selectedRole'
                          : 'Account approved as $selectedRole',
                    ),
                    backgroundColor: DAColors.primaryGreen,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: DAColors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  void _handleAccept(Map<String, dynamic> account) {
    // Show the role selection modal
    _showAccountRoleModal(context, account: account, isEdit: false);
  }

  void _handleDecline(Map<String, dynamic> account) async {
    try {
      await _authService.rejectUser(
        account['uid'],
        'Rejected by admin',
      );
      await _loadAccounts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account declined: ${account['email']}'),
            backgroundColor: DAColors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining account: $e'),
            backgroundColor: DAColors.red,
          ),
        );
      }
    }
  }

  void _handleEdit(Map<String, dynamic> account) {
    // Show the role selection modal for editing
    _showAccountRoleModal(context, account: account, isEdit: true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final headerHeight =
        height * (isLargeTablet ? 0.18 : isTablet ? 0.22 : 0.28);

    final titleFontSize =
        isLargeTablet ? 48.0 : isTablet ? 38.0 : width * 0.08;

    final subtitleFontSize =
        isLargeTablet ? 18.0 : isTablet ? 16.0 : width * 0.038;

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
                        child: Container(
                          height: headerHeight,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeTablet ? 60.0 : width * 0.06,
                            vertical: isLargeTablet ? 30.0 : height * 0.025,
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
                                      'Accounts',
                                      style: GoogleFonts.poppins(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.2,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Accounts of all the user',
                                      style: GoogleFonts.poppins(
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.2,
                                      ),
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
                    );
                  },
                ),
              ],
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding: EdgeInsets.fromLTRB(
              width * 0.06,
              height * 0.025,
              width * 0.06,
              height * 0.02,
            ),
            child: CustomTextField(
              controller: _searchController,
              hintText: '',
              prefixIcon: Icons.search,
              isSearch: true,
              onChanged: (value) {
                // TODO: Implement search functionality
                setState(() {});
              },
            ),
          ),

          /// FILTER TABS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.06),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterTab(
                    label: 'Admin',
                    color: DAColors.red,
                    isSelected: _selectedFilter == 'Admin',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Admin';
                      });
                    },
                  ),
                  SizedBox(width: width * 0.025),
                  FilterTab(
                    label: 'Profiler',
                    color: const Color(0xFF0066CC),
                    isSelected: _selectedFilter == 'Profiler',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Profiler';
                      });
                    },
                  ),
                  SizedBox(width: width * 0.025),
                  FilterTab(
                    label: 'Moderator',
                    color: const Color(0xFFFFCC00),
                    isSelected: _selectedFilter == 'Moderator',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Moderator';
                      });
                    },
                  ),
                  SizedBox(width: width * 0.025),
                  FilterTab(
                    label: 'Pending',
                    color: DAColors.primaryGreen,
                    isSelected: _selectedFilter == 'Pending',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Pending';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: height * 0.025),

          /// ACCOUNTS LIST
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: DAColors.primaryGreen,
                    ),
                  )
                : _filteredAccounts.isEmpty
                    ? Center(
                        child: Text(
                          'No accounts found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.06,
                          vertical: height * 0.01,
                        ),
                        itemCount: _filteredAccounts.length,
                        itemBuilder: (context, index) {
                          final account = _filteredAccounts[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: height * 0.02),
                            child: AccountCard(
                              name: account['name'],
                              email: account['email'],
                              date: account['date'],
                              role: account['role'],
                              status: account['status'],
                              isPending: account['isPending'],
                              roleColor: _getRoleColor(account['role']),
                              onAccept: () => _handleAccept(account),
                              onDecline: () => _handleDecline(account),
                              onEdit: () => _handleEdit(account),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}