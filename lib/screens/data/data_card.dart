import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';

/// DataCard - Reusable card for displaying farmer/fisherfolk data
/// Left border color: Red (Unsync), Yellow (Pending), Green (Approved)
class DataCard extends StatelessWidget {
  final String farmerName;
  final String location;
  final String commodity;
  final String enumerator;
  final String date;
  final String status; // 'Unsync', 'Pending', 'Approved'
  final VoidCallback onViewTap;

  const DataCard({
    super.key,
    required this.farmerName,
    required this.location,
    required this.commodity,
    required this.enumerator,
    required this.date,
    required this.status,
    required this.onViewTap,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Unsync':
        return DAColors.red;
      case 'Pending':
        return const Color(0xFFFFCC00); // Yellow
      case 'Approved':
        return DAColors.primaryGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final nameFontSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : 17.0;
    final locationFontSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final enumeratorFontSize = isLargeTablet ? 14.0 : isTablet ? 13.0 : 12.0;
    final dateFontSize = isLargeTablet ? 14.0 : isTablet ? 13.0 : 12.0;
    final buttonTextSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: _getStatusColor(),
            width: 6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            /// DATA INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farmer Name
                  Text(
                    farmerName,
                    style: GoogleFonts.poppins(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location | Commodity
                  Text(
                    '$location | $commodity',
                    style: GoogleFonts.poppins(
                      fontSize: locationFontSize,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: isTablet ? 16 : 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          date,
                          style: GoogleFonts.poppins(
                            fontSize: dateFontSize,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Enumerator
                  Text(
                    'Enumerator : $enumerator',
                    style: GoogleFonts.poppins(
                      fontSize: enumeratorFontSize,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// VIEW BUTTON
            GestureDetector(
              onTap: onViewTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 12 : 10,
                ),
                decoration: BoxDecoration(
                  color: DAColors.primaryGreen,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: DAColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'View',
                  style: GoogleFonts.poppins(
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}