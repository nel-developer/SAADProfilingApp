import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 3 of 8 — Other Personal Information
/// Fields: Indigenous Group (Yes/No + Autocomplete), PWD (Yes/No), Spouse Name
class Step03OtherPersonal extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;

  const Step03OtherPersonal({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step03OtherPersonal> createState() => _Step03OtherPersonalState();
}

class _Step03OtherPersonalState extends State<Step03OtherPersonal> {
  bool? _isIndigenous;
  bool? _isPWD;
  final TextEditingController _spouseNameCtrl = TextEditingController();

  final List<String> _indigenousGroups = [
    'Abelling/Aberling',
    'Aeta',
    'Aeta/Ayta',
    'Aeta/Ayta-Sambal',
    'Aeta/Ayta-Ambala',
    'Aeta/Ayta-Abelling/Abellen',
    'Aeta/Ayta-Mag-indi',
    'Aeta/Ayta-Mang-ansti',
    'Aeta/Ayta-- Magbukun',
    'Agta',
    'Agta-Labin',
    'Agta-Dupanigan',
    'Agta Isigiran',
    'Agta- Cimaron',
    'Agta- Tabangnon',
    'Agta-Taboy',
    'Agta-Agay',
    'Agta-Dumagat',
    'Agutaynen',
    'Alangan Mangyan',
    'Alta',
    'Applai',
    'Applai-Kachakran/Kadaclan',
    'Aromanen-Manobo/Eromanen-Manobo',
    'Aromanen-Manobo/Eromanen-Manobo Dibabeen',
    'Aromanen-Manobo/Eromanen-Manobo Direrayaan',
    'Aromanen-Manobo/Eromanen-Manobo Ilianen',
    'Aromanen-Manobo/Eromanen-Manobo Isoroken',
    'Aromanen-Manobo/Eromanen-Manobo Kirenteken',
    'Aromanen-Manobo/Eromanen-Manobo Lahitanen',
    'Aromanen-Manobo/Eromanen-Manobo Livunganen',
    'Aromanen-Manobo/Eromanen-Manobo Mulitaan',
    'Aromanen-Manobo/Eromanen-Manobo Pulengien',
    'Aromanen-Manobo/Eromanen-Manobo Kulmanen',
    'Ata',
    'Ata-Manobo',
    'Ati',
    'Ayangan',
    'Ayangan-Henanga',
    'Ayta',
    'Badjao',
    'Bago',
    'Bagobo Klata',
    'Bagobo Tagabawa',
    'Bajau',
    'Balangao',
    'Balangao - Lias',
    'Baliwon',
    'Baliwon - Gaddang',
    'Baliwon - Miligan',
    'Baliwon - I-sadanga',
    'Baliwon - Fiallig/Fialika',
    'Bangon Mangyan',
    'Bantoanon',
    'Banwaon',
    'Batak',
    "B'laan/Blaan",
    'Bontok',
    'Bontok-Majukayong',
    'Bugkalot/Ilongot',
    'Buhid Mangyan',
    'Bukidnon',
    'Bukidnon - Akeanon',
    'Bukidnon - Pan-anayon',
    'Bukidnon - Halowodnon',
    'Bukidnon - Magahat',
    'Bukidnon - Ituman',
    'Bukidnon - Iraynon',
    'Bukidnon - Tagoloanon',
    'Cagayanen',
    'Calinga',
    'Cuyonen/Cuyunon',
    'Diangan',
    'Dibabawon',
    'Dumagat',
    'Dumagat - Remontado',
    'Dumagat - Kabolowen',
    'Dumagat - Tagebolus',
    'Dumagat - Edimala',
    'Eskaya',
    'Gaddang',
    'Gubatnon-Ratagnon Mangyan',
    'Hanunuo Mangyan',
    'Higaonon/Higa-onon',
    'Higaonon - Tagoloanon',
    'Ibanag',
    'Ibatan',
    'Ibaloy',
    'Ibukid',
    'Ifugao',
    'Imalawa',
    'Iraya Mangyan',
    'Isinai',
    'Isnag',
    'Isneg',
    'Isneg/Isnag',
    'Itawes',
    'Itneg',
    'Itneg/Tinguian',
    'Itneg/Tinguian - Adasen',
    'Itneg/Tinguian - Balatok',
    'Itneg/Tinguian - Banao',
    'Itneg/Tinguian - Belwang',
    'Itneg/Tinguian - Binongan',
    'Itneg/Tinguian - Gubang',
    'Itneg/Tinguian - Inlaud',
    'Itneg/Tinguian - Mabaka',
    'Itneg/Tinguian - Maeng',
    'Itneg/Tinguian - Masadiit',
    'Itneg/Tinguian - Muyadan',
    'Ivatan',
    'Iwak',
    'Kabihug',
    'Kabihug - Manide',
    'Kagan/Kalagan',
    'Kalanguya',
    'Kalanguya - Yattuka',
    'Kalanguya-Ikalahan',
    'Kalinga',
    'Kalinga - Lubo',
    'Kalinga - Mangali',
    'Kalinga - Taloctoc',
    'Kalinga - Pangol',
    'Kalinga - Gaang',
    'Kalinga - Dacalan',
    'Kalinga - Guilayon',
    'Kalinga - Nanong',
    'Kalinga - Dallac',
    'Kalinga - Biga',
    'Kalinga - Tobog',
    'Kalinga - Gaddang',
    'Kalinga - Culminga',
    'Kalinga - Malbong',
    'Kalinga - Minanga',
    'Kalinga - Dao-Angan',
    'Kalinga - Banao',
    'Kalinga - Salegseg',
    'Kalinga - Gubang',
    'Kalinga - Mabaca',
    'Kalinga - Poswoy',
    'Kalinga - Abu-Abaan',
    'Kalinga - Buaya',
    'Kalinga - Bulatoc',
    'Kalinga - Dangtalan',
    'Kalinga - Cagaluan',
    'Kalinga - Balinciagao',
    'Kalinga - Ableg/Dalupa',
    'Kalinga - Limos',
    'Kalinga - Pinukpuk',
    'Kalinga - Magaogao',
    'Kalinga - Aciga',
    'Kalinga - Ballayangan',
    'Kalinga - Ammacian',
    'Kalinga - Dugpa',
    'Kalinga - Uma',
    'Kalinga - Lubuagan',
    'Kalinga - Mabongtot',
    'Kalinga - Tanglag',
    'Kalinga - Tulgao',
    'Kalinga - Dananao',
    'Kalinga - Tongrayan',
    'Kalinga - Bangad',
    'Kalinga - Basao',
    'Kalinga - Guina-Ang',
    'Kalinga - Sumadel',
    'Kalinga - Butbut',
    'Kamiguin',
    'Kankanaey',
    "Kankanaey - Hak'ki",
    'Karao',
    'Karulano',
    'Kolibugan',
    'Lambanguian',
    'Malaueg',
    'Mamanwa',
    'Mandaya',
    'Mangguangan',
    'Mangyan',
    'Mansaka',
    'Manobo',
    'Manobo - Pulanguinon',
    'Manobo - Dunggoanon',
    'Manobo - Kirenteken',
    'Manobo - Aromanon',
    'Manobo - Blit',
    'Manobo - Tasaday',
    'Manobo - Dulangan',
    'Manobo -Dulangan - Lambangian',
    'Ubo Monuvu/Manobo-Ubo/Ubo Manobo/Ubo Manuvu/Ubo Menuvu',
    'Matigsalog',
    'Molbog',
    'Obu-Manuvu',
    'Palawan-o',
    "Palawan-o - Tao't-Bato",
    'Palawan-o - Ken-ey',
    'Pan-ayanon',
    'Panay Bukidnon',
    'Parananum',
    'Sama',
    'Sama Badjao',
    'Sama Bangingi',
    'Sama Delaut',
    'Sibuyan Mangyan-Tagabukid',
    'Subanen/Subanon-Kolibugan',
    'Tagakaulo',
    'Tagbanua',
    'Tagbanua -Calamian',
    'Tagbanua Tandulanen',
    'Tadyawan Mangyan',
    'Talaandig',
    "T'boli/Tboli",
    'Tau-buid Mangyan',
    "T'duray/Teduray",
    'Tigwahanon',
    'Tinananen',
    'Tingguian',
    'Tuwali',
    'Tuwali - Kele-i',
    'Umayamnon',
    'Yakan',
    'Yapayao',
    'Yogad',
  ];

  @override
  void dispose() {
    _spouseNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final double labelSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final double fieldGap = isLargeTablet ? 22.0 : isTablet ? 18.0 : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;
    final double fieldHeight = isLargeTablet ? 54.0 : isTablet ? 50.0 : 44.0;
    final double radioSize = isLargeTablet ? 28.0 : isTablet ? 26.0 : 24.0;
    final double radioTextSize = isLargeTablet ? 17.0 : isTablet ? 16.0 : 15.0;

    return ProfilingStepWrapper(
      currentStep: 3,
      sectionTitle: 'Other Personal Information',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MEMBER OF AN INDIGENOUS GROUP
          _label('Member of an Indigenous Group:', labelSize),
          SizedBox(height: labelFieldGap),

          Row(
            children: [
              _radioOption(
                label: 'Yes',
                value: true,
                groupValue: _isIndigenous,
                onChanged: (value) {
                  setState(() {
                    _isIndigenous = value;
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
              SizedBox(width: width * 0.06),
              _radioOption(
                label: 'No',
                value: false,
                groupValue: _isIndigenous,
                onChanged: (value) {
                  setState(() {
                    _isIndigenous = value;
                    if (value == false) {
                      _selectedIndigenousGroup = null;
                    }
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
            ],
          ),

          if (_isIndigenous == true) ...[
            SizedBox(height: labelFieldGap + 4),
            Text(
              'if yes, please specify:',
              style: GoogleFonts.poppins(
                fontSize: labelSize - 2,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedAutocomplete(
                hint: 'Search Indigenous Group',
                options: _indigenousGroups,
                onSelected: (value) {
                  setState(() {
                    _selectedIndigenousGroup = value;
                  });
                },
              ),
            ),
          ],

          SizedBox(height: fieldGap),

          // PERSON WITH DISABILITY (PWD)
          _label('Person with Disability (PWD)', labelSize),
          SizedBox(height: labelFieldGap),

          Row(
            children: [
              _radioOption(
                label: 'Yes',
                value: true,
                groupValue: _isPWD,
                onChanged: (value) {
                  setState(() {
                    _isPWD = value;
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
              SizedBox(width: width * 0.06),
              _radioOption(
                label: 'No',
                value: false,
                groupValue: _isPWD,
                onChanged: (value) {
                  setState(() {
                    _isPWD = value;
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
            ],
          ),

          SizedBox(height: fieldGap),

          // NAME OF THE SPOUSE
          Row(
            children: [
              _label('Name of the Spouse ', labelSize),
              Flexible(
                child: Text(
                  '(if married)(LN, FN, MI)',
                  style: GoogleFonts.poppins(
                    fontSize: labelSize - 2,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _spouseNameCtrl,
              hint: 'Enter Spouse Name',
            ),
          ),
        ],
      ),
    );
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

  Widget _radioOption({
    required String label,
    required bool value,
    required bool? groupValue,
    required ValueChanged<bool?> onChanged,
    required double radioSize,
    required double textSize,
  }) {
    final isSelected = groupValue == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? DAColors.primaryGreen.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: radioSize,
              height: radioSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? DAColors.primaryGreen : Colors.white,
                border: Border.all(
                  color: isSelected ? DAColors.primaryGreen : Colors.grey.shade400,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? DAColors.primaryGreen.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: radioSize * 0.65,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: textSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? DAColors.primaryGreen : DAColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shadowedField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
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
      child: CustomTextField(
        controller: controller,
        hintText: hint,
      ),
    );
  }

  Widget _shadowedAutocomplete({
    required String hint,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
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
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return options.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: onSelected,
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: DAColors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
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
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: DAColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: index < options.length - 1
                                ? BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: DAColors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}