import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/models/commodity_data.dart';
import 'package:da_project_1/services/commodity_service.dart';
import 'package:da_project_1/widgets/green_header_section.dart';

/// AdminCommodityPage — Admin-only interface to manage commodity data
/// Add, edit, delete commodity entries with field requirement checkboxes
class AdminCommodityPage extends StatefulWidget {
  const AdminCommodityPage({super.key});

  @override
  State<AdminCommodityPage> createState() => _AdminCommodityPageState();
}

class _AdminCommodityPageState extends State<AdminCommodityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  final CommodityService _commodityService = CommodityService();
  List<CommodityData> _commodities = [];
  bool _loading = true;

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

    _leafLeftAnim = Tween<double>(begin: -120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _leafRightAnim = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _loadCommodities();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCommodities() async {
    try {
      setState(() => _loading = true);
      final commodities = await _commodityService.getAllCommodities();
      if (mounted) {
        setState(() {
          _commodities = commodities;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading commodities: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  void _openAddEditModal(CommodityData? editData) {
    showDialog(
      context: context,
      builder: (context) => _CommodityEditModal(
        commodityService: _commodityService,
        commodityData: editData,
        onSave: (data) async {
          try {
            if (editData == null) {
              await _commodityService.addCommodity(data);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Commodity added successfully'),
                  backgroundColor: DAColors.primaryGreen,
                ),
              );
            } else {
              await _commodityService.updateCommodity(data.id!, data);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Commodity updated successfully'),
                  backgroundColor: DAColors.primaryGreen,
                ),
              );
            }
            if (mounted) {
              Navigator.pop(context);
              await _loadCommodities();
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteCommodity(CommodityData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Commodity?'),
        content: Text('Are you sure you want to delete "${data.productForm}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _commodityService.deleteCommodity(data.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Commodity deleted'),
                      backgroundColor: DAColors.primaryGreen,
                    ),
                  );
                  await _loadCommodities();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final headerHeight = _refHeight * 0.28 * scale;
    final titleFontSize = _refWidth * 0.065 * scale;
    final subtitleFontSize = _refWidth * 0.03 * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E8E8),
      body: Column(
        children: [
          /// GREEN HEADER
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                GreenHeaderSection(
                  leafLeftAnimation: _leafLeftAnim,
                  leafRightAnimation: _leafRightAnim,
                  customHeight: headerHeight,
                ),
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
                      horizontal: _refWidth * 0.06 * scale,
                      vertical: _refHeight * 0.025 * scale,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Commodity Management',
                              style: GoogleFonts.poppins(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Admin Control Panel',
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(DAColors.primaryGreen),
                    ),
                  )
                : _commodities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No commodities yet',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCommodities,
                        color: DAColors.primaryGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _commodities.length,
                          itemBuilder: (context, index) {
                            final commodity = _commodities[index];
                            return _buildCommodityCard(commodity, scale);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditModal(null),
        backgroundColor: DAColors.primaryGreen,
        label: const Text('Add Commodity'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCommodityCard(CommodityData commodity, double scale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              commodity.productForm ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if ((commodity.type ?? '').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildTag(commodity.type!, Colors.teal),
                          ],
                        ],
                      ),
                      Text(
                        '${commodity.commodity ?? 'N/A'} • ${commodity.saleMeth ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openAddEditModal(commodity);
                    } else if (value == 'delete') {
                      _deleteCommodity(commodity);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (commodity.maleRequired == true) _buildTag('Male', Colors.blue),
                if (commodity.femaleRequired == true) _buildTag('Female', Colors.pink),
                if (commodity.totalWeightRequired == true) _buildTag('Weight', Colors.orange),
                if (commodity.totalPriceRequired == true) _buildTag('Price', Colors.green),
                if (commodity.expensesRequired == true) _buildTag('Expenses', Colors.red),
              ],
            ),
            if ((commodity.remarks ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Remarks: ${commodity.remarks}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Modal for adding/editing commodities
class _CommodityEditModal extends StatefulWidget {
  final CommodityService commodityService;
  final CommodityData? commodityData;
  final Function(CommodityData) onSave;

  const _CommodityEditModal({
    required this.commodityService,
    required this.commodityData,
    required this.onSave,
  });

  @override
  State<_CommodityEditModal> createState() => _CommodityEditModalState();
}

class _CommodityEditModalState extends State<_CommodityEditModal> {
  late CommodityData _data;
  final _pricingBasisController = TextEditingController();
  final _unitController = TextEditingController();
  final _remarksController = TextEditingController();
  // Controllers for Add-mode text inputs
  final _typeTextController = TextEditingController();
  final _commodityTextController = TextEditingController();
  final _saleMethodTextController = TextEditingController();
  final _productFormTextController = TextEditingController();
  String? _selectedType;
  String? _selectedCommodity;
  String? _selectedSaleMethod;
  String? _selectedProductForm;
  
  final List<String> _typeOptions = ['Livestock', 'Poultry', 'HVC', 'Corn', 'Rice', 'Others'];
  List<String> _commodityOptions = [];
  List<String> _saleMethodOptions = [];
  List<String> _productFormOptions = [];

  @override
  void initState() {
    super.initState();
    _data = widget.commodityData ?? CommodityData();
    _selectedType = _data.type;
    _selectedCommodity = _data.commodity;
    _selectedSaleMethod = _data.saleMeth;
    _selectedProductForm = _data.productForm;
    _pricingBasisController.text = _data.pricingBasis ?? '';
    _unitController.text = _data.unit ?? '';
    _remarksController.text = _data.remarks ?? '';
    // Seed add-mode text controllers so the admin can type new records
    _typeTextController.text = _data.type ?? '';
    _commodityTextController.text = _data.commodity ?? '';
    _saleMethodTextController.text = _data.saleMeth ?? '';
    _productFormTextController.text = _data.productForm ?? '';
    
    // Load initial filtered options
    if (_selectedType != null) {
      _loadCommodityOptions(_selectedType!);
    }
    if (_selectedType != null && _selectedCommodity != null) {
      _loadSaleMethodOptions(_selectedType!, _selectedCommodity!);
    }
    if (_selectedType != null && _selectedCommodity != null && _selectedSaleMethod != null) {
      _loadProductFormOptions(_selectedType!, _selectedCommodity!, _selectedSaleMethod!);
    }
  }

  Future<void> _loadCommodityOptions(String type) async {
    try {
      final commodities = await widget.commodityService.getAllCommodities();
      final options = commodities
          .where((c) => c.type == type)
          .map((c) => c.commodity ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      if (mounted) {
        setState(() => _commodityOptions = options);
      }
    } catch (e) {
      debugPrint('❌ Error loading commodity options: $e');
    }
  }

  Future<void> _loadSaleMethodOptions(String type, String commodity) async {
    try {
      final commodities = await widget.commodityService.getAllCommodities();
      final options = commodities
          .where((c) => c.type == type && c.commodity == commodity)
          .map((c) => c.saleMeth ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (mounted) {
        setState(() => _saleMethodOptions = options);
      }
    } catch (e) {
      debugPrint('❌ Error loading sale method options: $e');
    }
  }

  Future<void> _loadProductFormOptions(String type, String commodity, String saleMethod) async {
    try {
      final commodities = await widget.commodityService.getAllCommodities();
      final options = commodities
          .where((c) => c.type == type && c.commodity == commodity && c.saleMeth == saleMethod)
          .map((c) => c.productForm ?? '')
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList();
      if (mounted) {
        setState(() => _productFormOptions = options);
      }
    } catch (e) {
      debugPrint('❌ Error loading product form options: $e');
    }
  }

  @override
  void dispose() {
    _pricingBasisController.dispose();
    _unitController.dispose();
    _remarksController.dispose();
    _typeTextController.dispose();
    _commodityTextController.dispose();
    _saleMethodTextController.dispose();
    _productFormTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.commodityData == null ? 'Add Commodity' : 'Edit Commodity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.commodityData == null) ...[
              // Add mode - allow typing new master records
              _buildTextField('Commodity Type', _typeTextController, 'Livestock, Poultry, HVC, etc.'),
              _buildTextField('Commodity', _commodityTextController, 'Swine, Cattle, Goat, Carabao, etc.'),
              _buildTextField('Sale Method', _saleMethodTextController, 'Live Animal, Meat Retail, etc.'),
              _buildTextField('Product Form', _productFormTextController, 'Weaner, Pork Cuts, Whole Animal, etc.'),
              const SizedBox(height: 12),
            ] else ...[
              // Edit mode - use cascading dropdowns from existing records
              _buildTypeDropdown(),
              const SizedBox(height: 12),
              if (_selectedType != null) ...[
                _buildCommodityDropdown(),
                const SizedBox(height: 12),
              ],
              if (_selectedType != null && _selectedCommodity != null) ...[
                _buildSaleMethodDropdown(),
                const SizedBox(height: 12),
              ],
              if (_selectedType != null && _selectedCommodity != null && _selectedSaleMethod != null) ...[
                _buildProductFormDropdown(),
                const SizedBox(height: 12),
              ],
            ],
            
            _buildTextField('Pricing Basis', _pricingBasisController, 'Per Head, Per Kilogram, etc.'),
            _buildTextField('Unit', _unitController, 'Head, Kilograms, Liters, etc.'),
            _buildTextField('Remarks', _remarksController, 'Optional notes'),
            const SizedBox(height: 16),
            Text(
              'Field Requirements (Checkboxes)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildCheckbox('Male Required', _data.maleRequired ?? false, (val) {
              setState(() => _data.maleRequired = val);
            }),
            _buildCheckbox('Female Required', _data.femaleRequired ?? false, (val) {
              setState(() => _data.femaleRequired = val);
            }),
            _buildCheckbox('Total Weight Required', _data.totalWeightRequired ?? false, (val) {
              setState(() => _data.totalWeightRequired = val);
            }),
            _buildCheckbox('Total Price Required', _data.totalPriceRequired ?? false, (val) {
              setState(() => _data.totalPriceRequired = val);
            }),
            _buildCheckbox('Expenses Required', _data.expensesRequired ?? false, (val) {
              setState(() => _data.expensesRequired = val);
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Support both Add (typing new record) and Edit (selecting existing)
            if (widget.commodityData == null) {
              // Add-mode: read from text controllers
              _data.type = _typeTextController.text.trim();
              _data.commodity = _commodityTextController.text.trim();
              _data.saleMeth = _saleMethodTextController.text.trim();
              _data.productForm = _productFormTextController.text.trim();
            } else {
              // Edit-mode: read from selected dropdowns
              _data.type = _selectedType;
              _data.commodity = _selectedCommodity;
              _data.saleMeth = _selectedSaleMethod;
              _data.productForm = _selectedProductForm;
            }

            _data.pricingBasis = _pricingBasisController.text;
            _data.unit = _unitController.text;
            _data.remarks = _remarksController.text;

            if ((_data.type == null || _data.type!.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Commodity Type is required')),
              );
              return;
            }

            if ((_data.commodity == null || _data.commodity!.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Commodity is required')),
              );
              return;
            }

            if ((_data.saleMeth == null || _data.saleMeth!.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Sale Method is required')),
              );
              return;
            }

            if ((_data.productForm == null || _data.productForm!.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('❌ Product Form is required')),
              );
              return;
            }

            widget.onSave(_data);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DAColors.primaryGreen,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commodity Type', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: _typeOptions
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value;
                _selectedCommodity = null;
                _selectedSaleMethod = null;
                _selectedProductForm = null;
                _commodityOptions = [];
                _saleMethodOptions = [];
                _productFormOptions = [];
              });
              if (value != null) {
                _loadCommodityOptions(value);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select commodity type',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commodity', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _selectedCommodity,
            items: _commodityOptions
                .map((commodity) => DropdownMenuItem(
                      value: commodity,
                      child: Text(commodity),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCommodity = value;
                _selectedSaleMethod = null;
                _selectedProductForm = null;
                _saleMethodOptions = [];
                _productFormOptions = [];
              });
              if (value != null && _selectedType != null) {
                _loadSaleMethodOptions(_selectedType!, value);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select commodity',
            ),
          ),
          if (_commodityOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No commodities found. Add Commodity records first.',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaleMethodDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sale Method', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _selectedSaleMethod,
            items: _saleMethodOptions
                .map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSaleMethod = value;
                _selectedProductForm = null;
                _productFormOptions = [];
              });
              if (value != null && _selectedType != null && _selectedCommodity != null) {
                _loadProductFormOptions(_selectedType!, _selectedCommodity!, value);
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select sale method',
            ),
          ),
          if (_saleMethodOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No sale methods found. Add Sale Method records first.',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductFormDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Form', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _selectedProductForm,
            items: _productFormOptions
                .map((form) => DropdownMenuItem(
                      value: form,
                      child: Text(form),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedProductForm = value);
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'Select product form',
            ),
          ),
          if (_productFormOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No product forms found. Add Product Form records first.',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
