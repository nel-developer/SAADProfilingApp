import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/widgets/filter_tab.dart';
import 'package:da_project_1/screens/data/data_card.dart';
import 'package:da_project_1/screens/data/data_view_modal.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  String _selectedFilter = 'Unsync';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allData = [
    {
      'farmerName': 'Janeiroh Ilag',
      'location': 'Tingloy',
      'commodity': 'Native Chicken',
      'enumerator': 'Arnel Parlonga',
      'date': '2026-01-28',
      'status': 'Unsync',
    },
    {
      'farmerName': 'Maria Santos',
      'location': 'Tingloy',
      'commodity': 'Native Chicken',
      'enumerator': 'Arnel Parlonga',
      'date': '2026-01-28',
      'status': 'Unsync',
    },
    {
      'farmerName': 'Pedro Cruz',
      'location': 'Tingloy',
      'commodity': 'Native Chicken',
      'enumerator': 'Arnel Parlonga',
      'date': '2026-01-28',
      'status': 'Pending',
    },
    {
      'farmerName': 'Rosa Reyes',
      'location': 'Tingloy',
      'commodity': 'Native Chicken',
      'enumerator': 'Arnel Parlonga',
      'date': '2026-01-28',
      'status': 'Pending',
    },
    {
      'farmerName': 'Jose Garcia',
      'location': 'Tingloy',
      'commodity': 'Native Chicken',
      'enumerator': 'Arnel Parlonga',
      'date': '2026-01-28',
      'status': 'Approved',
    },
    {
      'farmerName': 'Ana Lopez',
      'location': 'Tingloy',
      'commodity': 'Native Chicken',
      'enumerator': 'Arnel Parlonga',
      'date': '2026-01-28',
      'status': 'Approved',
    },
  ];

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

  List<Map<String, dynamic>> get _filteredData {
    return _allData.where((data) => data['status'] == _selectedFilter).toList();
  }

  void _openDataViewModal(Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataViewModal(
          profileData: data,
          userRole: 'Profiler',
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
          onSync: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Synced successfully'),
                backgroundColor: DAColors.primaryGreen,
              ),
            );
          },
          onApprove: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Approved successfully'),
                backgroundColor: DAColors.primaryGreen,
              ),
            );
          },
          onDecline: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Declined'),
                backgroundColor: DAColors.red,
              ),
            );
          },
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
                    },
                  ),
                  SizedBox(width: filterSpacing),
                  FilterTab(
                    label: 'Pending',
                    color: const Color(0xFFFFCC00),
                    isSelected: _selectedFilter == 'Pending',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Pending';
                      });
                    },
                  ),
                  SizedBox(width: filterSpacing),
                  FilterTab(
                    label: 'Approved',
                    color: DAColors.primaryGreen,
                    isSelected: _selectedFilter == 'Approved',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Approved';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: afterFilterSpacing),

          /// DATA LIST
          Expanded(
            child: ListView.builder(
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
        ],
      ),
    );
  }
}