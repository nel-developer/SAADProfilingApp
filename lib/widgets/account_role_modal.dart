import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';

/// AccountRoleModal - Modal for selecting account role
/// Shows Admin, Moderator, and Profiler options
/// All role cards are equal height and evenly spaced
class AccountRoleModal extends StatelessWidget {
  final String? currentRole;
  final Function(String) onRoleSelected;

  const AccountRoleModal({
    super.key,
    this.currentRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    // Responsive font sizes
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final titleFontSize = isLargeTablet ? 28.0 : isTablet ? 24.0 : 22.0;
    final roleTitleFontSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : 17.0;
    final roleDescFontSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;

    // Fixed card height so all 3 options are equal size
    final cardHeight = isLargeTablet ? 90.0 : isTablet ? 80.0 : 72.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width * 0.08,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account Role',
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: isTablet ? 32 : 28,
                    ),
                    color: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Role options — all equal height, evenly spaced
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  _buildRoleOption(
                    context,
                    'Admin Role',
                    'Supervision of all of the accounts',
                    'Admin',
                    cardHeight,
                    roleTitleFontSize,
                    roleDescFontSize,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleOption(
                    context,
                    'Moderator',
                    'Accept and Decline Data',
                    'Moderator',
                    cardHeight,
                    roleTitleFontSize,
                    roleDescFontSize,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleOption(
                    context,
                    'Profiler',
                    'Collect Data',
                    'Profiler',
                    cardHeight,
                    roleTitleFontSize,
                    roleDescFontSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    String title,
    String description,
    String role,
    double cardHeight,
    double titleFontSize,
    double descFontSize,
  ) {
    final isSelected = currentRole == role;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onRoleSelected(role);
      },
      child: Container(
        height: cardHeight,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? DAColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: descFontSize,
                    color: Colors.grey.shade600,
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