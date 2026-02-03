import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CustomTextField - Reusable styled text input field
/// Used for search bars, forms, and other text inputs
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final Function(String)? onChanged;
  final bool isSearch;
  final bool obscureText;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.onChanged,
    this.isSearch = false,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSearch ? 30 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText ?? '',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: Colors.grey.shade600,
                  size: 24,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixIconTap,
                  child: Icon(
                    suffixIcon,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSearch ? 20 : 16,
            vertical: 16,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}