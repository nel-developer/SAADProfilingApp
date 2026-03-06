import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/image_storage_service.dart';
import 'dart:io';
import 'dart:typed_data';

/// Step 10 of 10 — Farmer's Signature
///
/// Fields:
///   • ID Type (optional, new farmer only)
///   • Identification (optional front + back, new farmer only)
///   • Farmer's Photo (Take Photo, required for new farmer)
///   • Signature (shows privacy modal first, then signature pad)
class Step10Signature extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step10Signature({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step10Signature> createState() => _Step10SignatureState();
}

class _Step10SignatureState extends State<Step10Signature> {
  String? _idType;
  File? _idFrontImage;
  File? _idBackImage;
  File? _farmerPhoto;
  Uint8List? _signatureImage;

  final ImagePicker _picker = ImagePicker();
  final ImageStorageService _imageStorage = ImageStorageService();
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
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(Step10Signature oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  void _loadData() {
    if (widget.currentData != null) {
      _idType = widget.currentData!.idType;

      final frontPath = widget.currentData!.idFrontImagePath;
      if (frontPath != null && frontPath.trim().isNotEmpty) {
        final file = File(frontPath);
        if (file.existsSync()) {
          _idFrontImage = file;
        }
      }

      final backPath = widget.currentData!.idBackImagePath;
      if (backPath != null && backPath.trim().isNotEmpty) {
        final file = File(backPath);
        if (file.existsSync()) {
          _idBackImage = file;
        }
      }

      final farmerPath = widget.currentData!.farmerPhotoPath;
      if (farmerPath != null && farmerPath.trim().isNotEmpty) {
        final file = File(farmerPath);
        if (file.existsSync()) {
          _farmerPhoto = file;
        }
      }

      if (widget.currentData!.signatureImage != null) {
        _signatureImage = widget.currentData!.signatureImage;
      }
    }
  }

  void _saveMediaToCurrentData() {
    if (widget.currentData == null) return;
    widget.currentData!.idType = _idType;
    widget.currentData!.idFrontImagePath = _idFrontImage?.path;
    widget.currentData!.idBackImagePath = _idBackImage?.path;
    widget.currentData!.farmerPhotoPath = _farmerPhoto?.path;
    widget.currentData!.signatureImage = _signatureImage;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final double labelSize = isLargeTablet
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final double fieldGap = isLargeTablet
        ? 22.0
        : isTablet
        ? 18.0
        : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;
    final double fieldHeight = isLargeTablet
        ? 54.0
        : isTablet
        ? 50.0
        : 44.0;
    final double buttonHeight = isLargeTablet
        ? 60.0
        : isTablet
        ? 56.0
        : 52.0;
    final double buttonTextSize = isLargeTablet
        ? 18.0
        : isTablet
        ? 17.0
        : 16.0;
    final double dropdownTextSize = isLargeTablet
        ? 15.0
        : isTablet
        ? 14.0
        : 13.0;
    final double iconSize = isLargeTablet
        ? 28.0
        : isTablet
        ? 26.0
        : 24.0;
    final isExistingFarmer = widget.currentData?.isExistingFarmer == true;

    return ProfilingStepWrapper(
      currentStep: 11,
      sectionTitle: 'Farmer\'s Signature',
      onNext: () => _handleNext(),
      onBack: _handleBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isExistingFarmer) ...[
            _label('ID Type (Optional)', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedDropdown(
                value: _idType,
                hint: 'Select ID Type',
                items: _idTypes,
                onChanged: (value) {
                  setState(() {
                    _idType = value;
                    _saveMediaToCurrentData();
                  });
                },
                textSize: dropdownTextSize,
              ),
            ),

            SizedBox(height: fieldGap),

            _label('Identification (Optional)', labelSize),
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
          ],

          _label('Signature', labelSize),
          SizedBox(height: labelFieldGap),
          _signatureButton(
            height: buttonHeight,
            textSize: buttonTextSize,
            iconSize: iconSize,
            onTap: () => _showPrivacyModalThenSignature(),
            hasSigned: _signatureImage != null,
          ),
        ],
      ),
    );
  }

  Future<void> _takeIDPhotos() async {
    final frontImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (frontImage == null) return;

    setState(() {
      _idFrontImage = File(frontImage.path);
      _saveMediaToCurrentData();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Now take the BACK of your ID')),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    final backImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (backImage == null) return;

    setState(() {
      _idBackImage = File(backImage.path);
      _saveMediaToCurrentData();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ID photos captured (Front + Back)'),
        backgroundColor: DAColors.primaryGreen,
      ),
    );
  }

  Future<void> _takeFarmerPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _farmerPhoto = File(image.path);
      _saveMediaToCurrentData();
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Farmer photo captured'),
        backgroundColor: DAColors.primaryGreen,
      ),
    );
  }

  void _handleNext() async {
    if (widget.currentData == null) {
      widget.onNext();
      return;
    }

    final isExistingFarmer = widget.currentData!.isExistingFarmer == true;

    if (widget.currentData!.farmerFolderName == null ||
        widget.currentData!.farmerFolderName!.isEmpty) {
      final firstName = widget.currentData!.firstName ?? 'farmer';
      final surname = widget.currentData!.surname ?? 'profiling';
      final uniqueId =
          widget.currentData!.tempIdLocal ??
          DateTime.now().millisecondsSinceEpoch.toString();
      widget.currentData!.farmerFolderName = _imageStorage
          .generateFarmerFolderName(firstName, surname, uniqueId: uniqueId);
    }

    final farmerFolder = widget.currentData!.farmerFolderName!;
    final firstName = widget.currentData!.firstName;
    final surname = widget.currentData!.surname;

    try {
      debugPrint('📸 Saving all images (batch mode)...');

      final imagesToSave = <String, File>{};
      if (!isExistingFarmer) {
        if (_idFrontImage != null) imagesToSave['front'] = _idFrontImage!;
        if (_idBackImage != null) imagesToSave['back'] = _idBackImage!;
        if (_farmerPhoto != null) imagesToSave['profile'] = _farmerPhoto!;
      }

      final savedPaths = await _imageStorage.saveImageBatch(
        farmerFolderName: farmerFolder,
        imagesToSave: imagesToSave,
        signatureData: _signatureImage,
        firstName: firstName,
        lastName: surname,
      );

      if (_idFrontImage != null) {
        if (savedPaths.containsKey('front')) {
          widget.currentData!.idFrontImagePath = savedPaths['front'];
          final idFrontExists = await _imageStorage.imageExists(
            widget.currentData!.idFrontImagePath,
          );
          if (!idFrontExists) {
            throw Exception('ID Front image verification failed.');
          }
        } else {
          throw Exception('ID Front image failed to save.');
        }
      }

      if (_idBackImage != null) {
        if (savedPaths.containsKey('back')) {
          widget.currentData!.idBackImagePath = savedPaths['back'];
          final idBackExists = await _imageStorage.imageExists(
            widget.currentData!.idBackImagePath,
          );
          if (!idBackExists) {
            throw Exception('ID Back image verification failed.');
          }
        } else {
          throw Exception('ID Back image failed to save.');
        }
      }

      if (!isExistingFarmer) {
        if (savedPaths.containsKey('profile')) {
          widget.currentData!.farmerPhotoPath = savedPaths['profile'];
          debugPrint(
            '✅ Farmer photo saved: ${widget.currentData!.farmerPhotoPath}',
          );

          final farmerPhotoExists = await _imageStorage.imageExists(
            widget.currentData!.farmerPhotoPath,
          );
          if (!farmerPhotoExists) {
            throw Exception(
              'Farmer photo file verification failed at: ${widget.currentData!.farmerPhotoPath}\nPlease check device storage.',
            );
          }
        } else {
          throw Exception(
            'Farmer photo failed to save. Please try taking the photo again.',
          );
        }
      }
      if (savedPaths.containsKey('signature')) {
        widget.currentData!.signatureImagePath = savedPaths['signature'];
        debugPrint(
          '✅ Signature saved: ${widget.currentData!.signatureImagePath}',
        );

        final signatureExists = await _imageStorage.imageExists(
          widget.currentData!.signatureImagePath,
        );
        if (!signatureExists) {
          throw Exception(
            'Signature file verification failed at: ${widget.currentData!.signatureImagePath}\nPlease check device storage.',
          );
        }
      } else {
        throw Exception(
          'Signature failed to save. Please draw your signature again.',
        );
      }

      debugPrint('📁 All images saved to: $farmerFolder');

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Images saved successfully!'),
          backgroundColor: DAColors.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onNext();
    } catch (e) {
      debugPrint('❌ Error saving images: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPrivacyModalThenSignature() async {
    final context = this.context;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PrivacyPolicyModal(),
    );

    if (accepted != true) return;

    final signature = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const _SignaturePadModal(),
    );

    if (!mounted) return;
    if (signature != null) {
      setState(() => _signatureImage = signature);
      _saveMediaToCurrentData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signature saved'),
          backgroundColor: DAColors.primaryGreen,
        ),
      );
    }
  }

  void _handleBack() {
    _saveMediaToCurrentData();
    widget.onBack?.call();
  }

  void _handleHeaderBack() {
    _saveMediaToCurrentData();
    if (widget.onHeaderBack != null) {
      widget.onHeaderBack!();
    } else {
      widget.onBack?.call();
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
        initialValue: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: textSize,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: DAColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
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
          color: hasBothPhotos
              ? DAColors.primaryGreen.withOpacity(0.7)
              : DAColors.primaryGreen,
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
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: iconSize * 0.85,
                ),
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
          color: hasSigned
              ? DAColors.primaryGreen.withOpacity(0.7)
              : DAColors.primaryGreen,
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
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: iconSize * 0.85,
                ),
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

    final modalWidth = isLargeTablet
        ? 600.0
        : isTablet
        ? 500.0
        : width * 0.9;
    final titleSize = isLargeTablet
        ? 26.0
        : isTablet
        ? 24.0
        : 22.0;
    final textSize = isLargeTablet
        ? 15.0
        : isTablet
        ? 14.0
        : 13.0;
    final checkboxTextSize = isLargeTablet
        ? 15.0
        : isTablet
        ? 14.0
        : 13.0;
    final buttonTextSize = isLargeTablet
        ? 18.0
        : isTablet
        ? 17.0
        : 16.0;

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
                        color: _hasRead
                            ? DAColors.primaryGreen
                            : Colors.grey.shade400,
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

    final modalWidth = isLargeTablet
        ? 600.0
        : isTablet
        ? 500.0
        : width * 0.9;
    final titleSize = isLargeTablet
        ? 26.0
        : isTablet
        ? 24.0
        : 22.0;
    final buttonTextSize = isLargeTablet
        ? 17.0
        : isTablet
        ? 16.0
        : 15.0;

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
