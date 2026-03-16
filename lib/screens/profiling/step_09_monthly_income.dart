import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

/// Step 9 of 10 — Monthly Family Income
///
/// Fields:
///   • Derived from Agri-Related Activities Only (Gross)
///   • Derived from Non Agri-Related Activities Only (Gross)
///   • Main Sources of Income
class Step09MonthlyIncome extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step09MonthlyIncome({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step09MonthlyIncome> createState() => _Step09MonthlyIncomeState();
}

class _Step09MonthlyIncomeState extends State<Step09MonthlyIncome> {
  final ProfilingStorageService _storage = ProfilingStorageService();
  final TextEditingController _agriRelatedCtrl = TextEditingController();
  final TextEditingController _saadNetCtrl = TextEditingController();
  final TextEditingController _nonSAADNetCtrl = TextEditingController();
  final TextEditingController _nonAgriRelatedCtrl = TextEditingController();
  final TextEditingController _mainSourcesCtrl = TextEditingController();
  String _lastCommoditiesSignature = '';

  @override
  void initState() {
    super.initState();
    _agriRelatedCtrl.addListener(_autoSaveToCurrentData);
    _saadNetCtrl.addListener(_autoSaveToCurrentData);
    _nonSAADNetCtrl.addListener(_autoSaveToCurrentData);
    _nonAgriRelatedCtrl.addListener(_autoSaveToCurrentData);
    _mainSourcesCtrl.addListener(_autoSaveToCurrentData);
    _loadData();
    _refreshDerivedIncomes(force: true);
  }

  @override
  void didUpdateWidget(Step09MonthlyIncome oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local in-memory state authoritative while this step widget is alive.
    // Avoid reloads on parent rebuilds to prevent accidental field resets.
  }

  void _loadData() {
    if (widget.currentData != null) {
      _agriRelatedCtrl.text =
          widget.currentData!.agriRelatedIncome?.toString() ?? '';
      _nonSAADNetCtrl.text =
          widget.currentData!.nonSAADNetIncome?.toString() ?? '';
      _nonAgriRelatedCtrl.text =
          widget.currentData!.nonAgriRelatedIncome?.toString() ?? '';
      _mainSourcesCtrl.text = widget.currentData!.mainSourcesOfIncome ?? '';

      // Auto-calculate all net incomes and update agri-related sum
      _updateNetIncomes();
    }
  }

  String _signatureForEntries(List<Map<String, dynamic>>? entries) {
    if (entries == null || entries.isEmpty) return '[]';
    final values = entries
        .map((entry) {
          final totalAmount = entry['totalAmount']?.toString() ?? '';
          final expenses = entry['expenses']?.toString() ?? '';
          return '$totalAmount|$expenses';
        })
        .join(';');
    return values;
  }

  void _refreshDerivedIncomes({bool force = false}) {
    final data = widget.currentData;
    if (data == null) return;

    final signature =
        '${_signatureForEntries(data.saadCommodities)}::${_signatureForEntries(data.nonSAADCommodities)}';

    if (!force && signature == _lastCommoditiesSignature) {
      return;
    }

    _lastCommoditiesSignature = signature;
    _updateNetIncomes();
  }

  /// Calculate both SAAD and Non-SAAD Net Income from receivedTotalPrice and
  /// receivedExpenses, then update agriRelatedIncome as their sum.
  void _updateNetIncomes() {
    if (widget.currentData != null) {
      final saadMonthly = _calculateMonthlyNet(
        widget.currentData!.saadCommodities,
      );
      final nonSaadMonthly = _calculateMonthlyNet(
        widget.currentData!.nonSAADCommodities,
      );

      final saadWhole = saadMonthly.roundToDouble();
      final nonSaadWhole = nonSaadMonthly.roundToDouble();

      _saadNetCtrl.text = saadWhole.toStringAsFixed(0);
      _nonSAADNetCtrl.text = nonSaadWhole.toStringAsFixed(0);

      widget.currentData!.saadNetIncome = saadWhole;
      widget.currentData!.nonSAADNetIncome = nonSaadWhole;

      final agriSum = saadWhole + nonSaadWhole;
      widget.currentData!.agriRelatedIncome = agriSum;
      _agriRelatedCtrl.text = agriSum.toStringAsFixed(0);

      debugPrint(
        '📊 Net incomes auto-calculated: SAAD=$saadMonthly, Non-SAAD=$nonSaadMonthly, '
        'AgriRelated=$agriSum',
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final text = value.toString().replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0.0;
  }

  double? _toNullableDouble(String text) {
    final normalized = text.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  double _calculateMonthlyNet(List<Map<String, dynamic>>? entries) {
    if (entries == null || entries.isEmpty) return 0.0;

    double monthlyTotal = 0.0;
    for (final entry in entries) {
      final totalAmount = _toDouble(entry['totalAmount']);
      final expenses = _toDouble(entry['expenses']);
      final net = totalAmount - expenses;
      if (net > 0) {
        monthlyTotal += net / 12;
      }
    }
    return monthlyTotal;
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      final data = widget.currentData!;
      // parse net income fields (agriRelated will be recalculated below)
      final saadVal = double.tryParse(_saadNetCtrl.text) ?? 0.0;
      final nonSaadVal = double.tryParse(_nonSAADNetCtrl.text) ?? 0.0;

      data.saadNetIncome = saadVal;
      data.nonSAADNetIncome = nonSaadVal;

      // agriRelated is always the sum of the two net incomes
      final agriSum = saadVal + nonSaadVal;
      data.agriRelatedIncome = agriSum;
      _agriRelatedCtrl.text = agriSum.toStringAsFixed(0);

      data.nonAgriRelatedIncome = _toNullableDouble(_nonAgriRelatedCtrl.text);
      data.mainSourcesOfIncome = _mainSourcesCtrl.text.trim();

      final selectedYear = data.yearCovered?.toString().trim();
      if (selectedYear != null && selectedYear.isNotEmpty) {
        final all = Map<String, dynamic>.from(data.recurrenceByYear ?? {});
        final existingRaw = all[selectedYear];
        final existing = existingRaw is Map
            ? Map<String, dynamic>.from(existingRaw)
            : <String, dynamic>{};
        all[selectedYear] = {
          ...existing,
          'agriRelatedIncome': agriSum,
          'saadNetIncome': saadVal,
          'nonSAADNetIncome': nonSaadVal,
          'nonAgriRelatedIncome': data.nonAgriRelatedIncome,
          'mainSourcesOfIncome': data.mainSourcesOfIncome,
        };
        data.recurrenceByYear = all;
      }
    }
  }

  @override
  void deactivate() {
    _autoSaveToCurrentData();
    super.deactivate();
  }

  @override
  void dispose() {
    _autoSaveToCurrentData();
    _agriRelatedCtrl.dispose();
    _saadNetCtrl.dispose();
    _nonSAADNetCtrl.dispose();
    _nonAgriRelatedCtrl.dispose();
    _mainSourcesCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();
    if (widget.currentData != null) {
      // recalc everything before saving
      _updateNetIncomes();

      // non-agri and sources remain manual
      widget.currentData!.nonAgriRelatedIncome = _toNullableDouble(
        _nonAgriRelatedCtrl.text,
      );
      widget.currentData!.mainSourcesOfIncome = _mainSourcesCtrl.text.trim();
    }
    widget.onNext();
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    _autoSaveToCurrentData();
    widget.onBack?.call();
  }

  void _handleHeaderBack() {
    FocusScope.of(context).unfocus();
    _autoSaveToCurrentData();
    if (widget.onHeaderBack != null) {
      widget.onHeaderBack!();
    } else {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    _refreshDerivedIncomes();

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

    return ProfilingStepWrapper(
      currentStep: 10,
      sectionTitle: 'MONTHLY FAMILY INCOME',
      onNext: _handleNext,
      onBack: _handleBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(
            'Derived from Agri-Related Activities Only (Gross)',
            labelSize,
          ),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _agriRelatedCtrl,
              hint: '0.00',
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
          ),

          SizedBox(height: fieldGap),

          _label('SAAD Net Income (Auto-calculated)', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _saadNetCtrl,
              hint: '0.00',
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
          ),

          SizedBox(height: fieldGap),

          _label('Non-SAAD Net Income (Auto-calculated)', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _nonSAADNetCtrl,
              hint: '0.00',
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
          ),

          SizedBox(height: fieldGap),

          _label(
            'Derived from Non Agri-Related Activities Only (Gross)',
            labelSize,
          ),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _nonAgriRelatedCtrl,
              hint: 'Enter Amount',
              keyboardType: TextInputType.number,
            ),
          ),

          SizedBox(height: fieldGap),

          _label('Main Sources of Income', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _mainSourcesCtrl,
              hint: 'Enter Main Sources',
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

  Widget _shadowedField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool readOnly = false,
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
        keyboardType: keyboardType,
        readOnly: readOnly,
        onChanged: (_) => _autoSaveToCurrentData(),
      ),
    );
  }
}
