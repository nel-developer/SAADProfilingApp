import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/primary_button.dart';
import 'package:da_project_1/widgets/status_badge.dart';

/// AccountCard - Reusable card widget for displaying account information
/// Non-pending layout:
///   Line 1:  Name          [Role Badge]      ← role badge malapit sa name
///   Line 2:  email
///   Line 3:  📅 date       [Active] [Edit]   ← status + edit magkatabi
class AccountCard extends StatelessWidget {
  final String name;
  final String email;
  final String date;
  final String role;
  final String status;
  final bool isPending;
  final Color roleColor;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onEdit;

  const AccountCard({
    super.key,
    required this.name,
    required this.email,
    required this.date,
    required this.role,
    required this.status,
    required this.isPending,
    required this.roleColor,
    this.onAccept,
    this.onDecline,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: roleColor, width: 6)),
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
        child: isPending
            ? _buildPendingLayout(context)
            : _buildActiveLayout(context),
      ),
    );
  }

  // ─── PENDING: name/email/date left, Accept+Decline stacked right ────────
  Widget _buildPendingLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;
    final nameFontSize = isLargeTablet
        ? 20.0
        : isTablet
        ? 18.0
        : 17.0;
    final emailFontSize = isLargeTablet
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final dateFontSize = isLargeTablet
        ? 14.0
        : isTablet
        ? 13.0
        : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.poppins(
                  fontSize: emailFontSize,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isTablet ? 16 : 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: dateFontSize,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        /// Accept / Decline
        if (onAccept != null || onDecline != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onAccept != null)
                PrimaryButton(
                  label: 'Accept',
                  color: DAColors.primaryGreen,
                  onTap: onAccept!,
                  isSmall: true,
                ),
              if (onAccept != null && onDecline != null)
                const SizedBox(height: 8),
              if (onDecline != null)
                PrimaryButton(
                  label: 'Decline',
                  color: DAColors.red,
                  onTap: onDecline!,
                  isSmall: true,
                ),
            ],
          ),
      ],
    );
  }

  // ─── ACTIVE (non-pending) ───────────────────────────────────────────────
  Widget _buildActiveLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;
    final nameFontSize = isLargeTablet
        ? 20.0
        : isTablet
        ? 18.0
        : 17.0;
    final emailFontSize = isLargeTablet
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final dateFontSize = isLargeTablet
        ? 14.0
        : isTablet
        ? 13.0
        : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: Name + Role Badge ──
        // Name ay nasa Expanded — kung kulang ang space, yung name ang mag-ellipsis,
        // hindi ang badge na mag-overflow
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            StatusBadge(label: role, color: roleColor),
          ],
        ),

        const SizedBox(height: 4),

        // ── Email ──
        Text(
          email,
          style: GoogleFonts.poppins(
            fontSize: emailFontSize,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // ── Row 2: Date (left) ──── Status + Edit (right) ──
        // Date row ay nasa Expanded — Spacer works properly,
        // at Status + Edit ay hindi na mag-overflow
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: isTablet ? 16 : 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: dateFontSize,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Status badge + Edit button side by side
            StatusBadge(
              label: status,
              color: status == 'Active'
                  ? DAColors.primaryGreen
                  : Colors.grey.shade700,
            ),
            if (onEdit != null) const SizedBox(width: 8),
            if (onEdit != null)
              PrimaryButton(
                label: 'Edit',
                color: const Color(0xFF00BCD4),
                onTap: onEdit!,
                isSmall: true,
              ),
          ],
        ),
      ],
    );
  }
}
