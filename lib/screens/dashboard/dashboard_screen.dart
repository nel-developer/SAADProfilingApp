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
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

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
    super.dispose();
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
    final subtitleFontSize = isLargeTablet ? 14.0 : isTablet ? 12.0 : width * 0.03;

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
                                    color: Colors.white.withOpacity(0.9),
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
                      fontSize: isLargeTablet ? 24.0 : isTablet ? 22.0 : 20.0,
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
                          '25',
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Total SAAD\nBeneficiaries',
                          '60',
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Total Registered\nMembers',
                          '60',
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
                          '7',
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Average Gross\nAgri-Related\nIncome',
                          '₱25000',
                          isTablet,
                          isLargeTablet,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: _buildStatCard(
                          'Average Gross\nNon Agri-Related\nIncome',
                          '₱25000',
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
                      fontSize: isLargeTablet ? 24.0 : isTablet ? 22.0 : 20.0,
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
                        child: _buildGenderChart(isTablet, isLargeTablet, width),
                      ),
                      SizedBox(width: width * 0.04),
                      Expanded(
                        child: _buildAgeGroupChart(isTablet, isLargeTablet, width),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.03),

                  /// GEOGRAPHIC COVERAGE TITLE
                  Text(
                    'Geographic Coverage',
                    style: GoogleFonts.poppins(
                      fontSize: isLargeTablet ? 24.0 : isTablet ? 22.0 : 20.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: height * 0.02),

                  /// BAR CHART
                  _buildBarChart(isTablet, isLargeTablet, width, height),

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
    final titleFontSize = isLargeTablet ? 12.0 : isTablet ? 11.0 : 10.0;
    final valueFontSize = isLargeTablet ? 32.0 : isTablet ? 28.0 : 24.0;

    return Container(
      height: isLargeTablet ? 140 : isTablet ? 130 : 120, // Fixed equal height
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 8,
        vertical: isTablet ? 14 : 10,
      ),
      decoration: BoxDecoration(
        color: DAColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DAColors.primaryGreen.withOpacity(0.3),
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

  Widget _buildGenderChart(bool isTablet, bool isLargeTablet, double width) {
    final titleFontSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final labelFontSize = isLargeTablet ? 12.0 : isTablet ? 11.0 : 10.0;
    final chartSize = isLargeTablet ? 180.0 : isTablet ? 160.0 : 140.0;
    final containerHeight = isLargeTablet ? 280.0 : isTablet ? 260.0 : 240.0;

    return Container(
      height: containerHeight, // Fixed equal height
      padding: EdgeInsets.all(isTablet ? 16 : 12),
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
          SizedBox(
            height: chartSize,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: [
                  PieChartSectionData(
                    color: DAColors.primaryGreen,
                    value: 60,
                    title: 'Male\n60%',
                    radius: chartSize * 0.45,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: DAColors.orange,
                    value: 40,
                    title: 'Female\n40%',
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

  Widget _buildAgeGroupChart(bool isTablet, bool isLargeTablet, double width) {
    final titleFontSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final labelFontSize = isLargeTablet ? 10.0 : isTablet ? 9.0 : 8.0;
    final chartSize = isLargeTablet ? 180.0 : isTablet ? 160.0 : 140.0;
    final containerHeight = isLargeTablet ? 280.0 : isTablet ? 260.0 : 240.0;

    return Container(
      height: containerHeight, // Fixed equal height (same as Gender chart)
      padding: EdgeInsets.all(isTablet ? 16 : 12),
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
          SizedBox(
            height: chartSize,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 0,
                sections: [
                  PieChartSectionData(
                    color: DAColors.primaryGreen,
                    value: 40,
                    title: 'Senior\n(60+)\n40%',
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
                    value: 20,
                    title: 'Youth\n(15-30)\n20%',
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
                    value: 20,
                    title: 'Adult\n(31-59)\n20%',
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
                    value: 20,
                    title: 'Child\n(10-15)\n20%',
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

  Widget _buildBarChart(bool isTablet, bool isLargeTablet, double width, double height) {
    final labelFontSize = isLargeTablet ? 14.0 : isTablet ? 13.0 : 12.0;
    final chartHeight = isLargeTablet ? 300.0 : isTablet ? 250.0 : height * 0.25;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
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
              _buildLegendItem('Quezon', const Color(0xFF0066CC), labelFontSize),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          /// BAR CHART
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Cavite', 'Laguna', 'Batangas', 'Rizal', 'Quezon'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: DAColors.primaryGreen, width: isTablet ? 30 : 20)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: DAColors.orange, width: isTablet ? 30 : 20)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 15, color: Colors.grey.shade500, width: isTablet ? 30 : 20)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: const Color(0xFF00BCD4), width: isTablet ? 30 : 20)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 19, color: const Color(0xFF0066CC), width: isTablet ? 30 : 20)]),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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