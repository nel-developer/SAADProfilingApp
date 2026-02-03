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

    // Responsive font sizes — clamped tighter for small screens
    final titleFontSize   = (width * 0.045).clamp(16.0, 24.0);
    final roleTitleFont   = (width * 0.038).clamp(14.0, 18.0);
    final roleDescFont    = (width * 0.032).clamp(11.0, 15.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width * 0.06,
      ),
      child: Container(
        // Let the dialog width be constrained by insetPadding naturally
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                    icon: const Icon(Icons.close, size: 24),
                    color: Colors.grey.shade600,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Role options
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  _buildRoleOption(
                    context,
                    'Admin Role',
                    'Supervision of all of the accounts',
                    'Admin',
                    roleTitleFont,
                    roleDescFont,
                  ),
                  const SizedBox(height: 10),
                  _buildRoleOption(
                    context,
                    'Moderator',
                    'Accept and Decline Data',
                    'Moderator',
                    roleTitleFont,
                    roleDescFont,
                  ),
                  const SizedBox(height: 10),
                  _buildRoleOption(
                    context,
                    'Profiler',
                    'Collect Data',
                    'Profiler',
                    roleTitleFont,
                    roleDescFont,
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
        // No fixed height — let content determine the size
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? DAColors.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        // Expanded inside Row so text gets full available width
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: descFontSize,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}