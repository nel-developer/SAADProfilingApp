import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'dart:io';
import 'dart:typed_data';

/// Step 8 of 8 — Farmer's Signature
///
/// Fields:
///   • ID Type (dropdown)
///   • Identification (Take Photo — front + back)
///   • Farmer's Photo (Take Photo)
///   • Signature (shows privacy modal first, then signature pad)
class Step08Signature extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;

  const Step08Signature({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step08Signature> createState() => _Step08SignatureState();
}

class _Step08SignatureState extends State<Step08Signature> {
  String? _idType;
  File? _idFrontImage;
  File? _idBackImage;
  File? _farmerPhoto;
  Uint8List? _signatureImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _idTypes = [
    'SSS ID',
    'PhilHealth ID',
    'Driver\'s License',
    'Voter\'s ID',
    'Passport',
    'National ID',
    'Senior Citizen ID',
    'PWD ID',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final double labelSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final double fieldGap = isLargeTablet ? 22.0 : isTablet ? 18.0 : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;
    final double fieldHeight = isLargeTablet ? 54.0 : isTablet ? 50.0 : 44.0;
    final double buttonHeight = isLargeTablet ? 60.0 : isTablet ? 56.0 : 52.0;
    final double buttonTextSize = isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0;
    final double dropdownTextSize = isLargeTablet ? 15.0 : isTablet ? 14.0 : 13.0;
    final double iconSize = isLargeTablet ? 28.0 : isTablet ? 26.0 : 24.0;

    return ProfilingStepWrapper(
      currentStep: 8,
      sectionTitle: 'Farmer\'s Signature',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID TYPE
          _label('ID Type', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _idType,
              hint: 'Enter your ID Type',
              items: _idTypes,
              onChanged: (val) => setState(() => _idType = val),
              textSize: dropdownTextSize,
            ),
          ),

          SizedBox(height: fieldGap),

          // IDENTIFICATION (Front + Back)
          _label('Identification', labelSize),
          SizedBox(height: labelFieldGap),
          _takePhotoButton(
            label: 'Take Photo (Front & Back)',
            icon: Icons.camera_alt,
            height: buttonHeight,
            textSize: buttonTextSize,
            iconSize: iconSize,
            onTap: () => _takeIDPhotos(),
            hasBothPhotos: _idFrontImage != null && _idBackImage != null,
          ),

          SizedBox(height: fieldGap),

          // FARMER'S PHOTO
          _label('Farmer\'s Photo', labelSize),
          SizedBox(height: labelFieldGap),
          _takePhotoButton(
            label: 'Take Photo',
            icon: Icons.camera_alt,
            height: buttonHeight,
            textSize: buttonTextSize,
            iconSize: iconSize,
            onTap: () => _takeFarmerPhoto(),
            hasBothPhotos: _farmerPhoto != null,
          ),

          SizedBox(height: fieldGap),

          // SIGNATURE
          _label('Signature', labelSize),
          SizedBox(height: labelFieldGap),
          _signatureButton(
            height: buttonHeight,
            textSize: buttonTextSize,
            iconSize: iconSize,
            onTap: () => _showPrivacyModalThenSignature(context),
            hasSigned: _signatureImage != null,
          ),
        ],
      ),
    );
  }

  // Take ID Photos (Front then Back)
  Future<void> _takeIDPhotos() async {
    // Take Front
    final frontImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (frontImage == null) return;

    setState(() => _idFrontImage = File(frontImage.path));

    if (!mounted) return;

    // Show message to take back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Now take the BACK of your ID')),
    );

    // Take Back
    await Future.delayed(const Duration(milliseconds: 500));
    final backImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (backImage == null) return;

    setState(() => _idBackImage = File(backImage.path));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ID photos captured (Front + Back)'),
        backgroundColor: DAColors.primaryGreen,
      ),
    );
  }

  // Take Farmer Photo
  Future<void> _takeFarmerPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _farmerPhoto = File(image.path));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Farmer photo captured'),
        backgroundColor: DAColors.primaryGreen,
      ),
    );
  }

  void _showPrivacyModalThenSignature(BuildContext context) async {
    // Show privacy policy modal
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PrivacyPolicyModal(),
    );

    if (accepted != true) return;

    // Show signature pad
    final signature = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const _SignaturePadModal(),
    );

    if (signature != null) {
      setState(() => _signatureImage = signature);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signature saved'),
          backgroundColor: DAColors.primaryGreen,
        ),
      );
    }
  }

  Widget _label(String text, double size) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: DAColors.black,
      ),
    );
  }

  Widget _shadowedDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double textSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DAColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: textSize,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: DAColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DAColors.primaryGreen, width: 2),
          ),
        ),
        style: GoogleFonts.poppins(
          color: DAColors.black,
          fontSize: textSize,
          fontWeight: FontWeight.w400,
        ),
        dropdownColor: DAColors.white,
        icon: Icon(Icons.arrow_drop_down, color: DAColors.black),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _takePhotoButton({
    required String label,
    required IconData icon,
    required double height,
    required double textSize,
    required double iconSize,
    required VoidCallback onTap,
    required bool hasBothPhotos,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: hasBothPhotos ? DAColors.primaryGreen.withOpacity(0.7) : DAColors.primaryGreen,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: DAColors.primaryGreen.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasBothPhotos)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: iconSize * 0.85),
              ),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: textSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: iconSize, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _signatureButton({
    required double height,
    required double textSize,
    required double iconSize,
    required VoidCallback onTap,
    required bool hasSigned,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: hasSigned ? DAColors.primaryGreen.withOpacity(0.7) : DAColors.primaryGreen,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: DAColors.primaryGreen.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasSigned)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: iconSize * 0.85),
              ),
            Flexible(
              child: Text(
                'Signature',
                style: GoogleFonts.poppins(
                  fontSize: textSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit, size: iconSize, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// Privacy Policy Modal with Checkbox
class _PrivacyPolicyModal extends StatefulWidget {
  const _PrivacyPolicyModal();

  @override
  State<_PrivacyPolicyModal> createState() => _PrivacyPolicyModalState();
}

class _PrivacyPolicyModalState extends State<_PrivacyPolicyModal> {
  bool _hasRead = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;
    
    final modalWidth = isLargeTablet ? 600.0 : isTablet ? 500.0 : width * 0.9;
    final titleSize = isLargeTablet ? 26.0 : isTablet ? 24.0 : 22.0;
    final textSize = isLargeTablet ? 15.0 : isTablet ? 14.0 : 13.0;
    final checkboxTextSize = isLargeTablet ? 15.0 : isTablet ? 14.0 : 13.0;
    final buttonTextSize = isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: modalWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with green underline
            Column(
              children: [
                Text(
                  'Data Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: DAColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Privacy text (scrollable)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Text(
                  'The collection of personal information is for documentation, planning, reporting, and policy-making in availing of agri-fishery interventions. Processed data shall only be shared with partner agencies for planning, reporting, and other purposes in accordance with the mandate of the agency. This is in compliance with the Data Sharing Policy of the Department. Only authorized DA personnel have access to the collected personal information, the exchange of which will be facilitated through email and hard copy. The DA will only retain personal information as long as necessary for the fullfillment of the declared purpose. You have the right to exercise your data subject rights as enumerated under Sec. 16 of the Data Privacy Act of 2012. To do so, please email the Data Protection Officer at dpo@da.gov.ph.',
                  style: GoogleFonts.poppins(
                    fontSize: textSize,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkbox: I've read all of this
            GestureDetector(
              onTap: () => setState(() => _hasRead = !_hasRead),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hasRead ? DAColors.primaryGreen : Colors.white,
                      border: Border.all(
                        color: _hasRead ? DAColors.primaryGreen : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _hasRead
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "I've read all of this",
                      style: GoogleFonts.poppins(
                        fontSize: checkboxTextSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Okay button (only enabled if checkbox is checked)
            GestureDetector(
              onTap: _hasRead ? () => Navigator.pop(context, true) : null,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _hasRead ? DAColors.orange : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _hasRead
                      ? [
                          BoxShadow(
                            color: DAColors.orange.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Okay',
                    style: GoogleFonts.poppins(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

// Signature Pad Modal using signature package
class _SignaturePadModal extends StatefulWidget {
  const _SignaturePadModal();

  @override
  State<_SignaturePadModal> createState() => _SignaturePadModalState();
}

class _SignaturePadModalState extends State<_SignaturePadModal> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
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
    final isTablet = width > 600;
    final isLargeTablet = width > 900;
    
    final modalWidth = isLargeTablet ? 600.0 : isTablet ? 500.0 : width * 0.9;
    final titleSize = isLargeTablet ? 26.0 : isTablet ? 24.0 : 22.0;
    final buttonTextSize = isLargeTablet ? 17.0 : isTablet ? 16.0 : 15.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: modalWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Column(
              children: [
                Text(
                  'Get your Signature',
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: DAColors.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Signature canvas using signature package
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Signature(
                      controller: _controller,
                      backgroundColor: Colors.grey.shade100,
                    ),
                    // Eraser icon bottom-right
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _controller.clear(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.delete_outline, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cancel + Save buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (_controller.isNotEmpty) {
                        final signature = await _controller.toPngBytes();
                        if (signature != null) {
                          Navigator.pop(context, signature);
                        }
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: DAColors.primaryGreen,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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