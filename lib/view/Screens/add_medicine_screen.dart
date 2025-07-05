// lib/view/Screens/add_medicine_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_null_comparison, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/medicine_model.dart';
import 'package:smart_pharma_net/viewmodels/medicine_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


class AddMedicineScreen extends StatefulWidget {
  final String pharmacyId;
  final MedicineModel? medicine;

  const AddMedicineScreen({
    Key? key,
    required this.pharmacyId,
    this.medicine,
  }) : super(key: key);

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _quantityToSellController = TextEditingController();
  final _priceSellController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Dental and oral agents';
  String _selectedCanBeSell = 'Yes';
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _categories = [
    'Dental and oral agents',
    'Antibiotics',
    'Blood products',
  ];

  final List<String> _canBeSellOptions = ['Yes', 'No'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    if (widget.medicine != null) {
      _nameController.text = widget.medicine!.name;
      _descriptionController.text = widget.medicine!.description;
      _priceController.text = widget.medicine!.price.toString();
      _quantityController.text = widget.medicine!.quantity.toString();
      _selectedCategory = widget.medicine!.category;
      _expiryDateController.text = widget.medicine!.expiryDate;
      _selectedCanBeSell = widget.medicine!.canBeSell ? 'Yes' : 'No';
      _quantityToSellController.text = widget.medicine!.quantityToSell?.toString() ?? '0';
      _priceSellController.text = widget.medicine!.priceSell.toString();
      _imageUrlController.text = widget.medicine!.imageUrl ?? '';
    } else {
      _quantityToSellController.text = '0';
      _priceSellController.text = '0.0';
      if (_expiryDateController.text.isEmpty) {
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 365)));
      }
    }
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
    _quantityToSellController.dispose();
    _priceSellController.dispose();
    _imageUrlController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_expiryDateController.text) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF636AE8),
              onPrimary: Colors.white,
              surface: Color(0xFF0F0F1A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF636AE8),
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0F0F1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              titleTextStyle: TextStyle(color: Colors.white),
              contentTextStyle: TextStyle(color: Colors.white70),
            ),
            appBarTheme: const AppBarTheme(
              color: Color(0xFF0D0D1A),
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final medicineViewModel = context.read<MedicineViewModel>();
      bool success = false;

      if (widget.medicine == null) {
        success = await medicineViewModel.addMedicine(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          pharmacyId: widget.pharmacyId,
          category: _selectedCategory,
          expiryDate: _expiryDateController.text,
          canBeSell: _selectedCanBeSell == 'Yes',
          quantityToSell: int.parse(_quantityToSellController.text),
          priceSell: double.parse(_priceSellController.text),
          imageUrl: _imageUrlController.text,
        );
      } else {
        success = await medicineViewModel.updateMedicine(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          category: _selectedCategory,
          expiryDate: _expiryDateController.text,
          medicineId: widget.medicine!.id,
          pharmacyId: widget.medicine!.pharmacyId,
          canBeSell: _selectedCanBeSell == 'Yes',
          quantityToSell: int.parse(_quantityToSellController.text),
          priceSell: double.parse(_priceSellController.text),
          imageUrl: _imageUrlController.text,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.medicine == null ? 'Medicine added successfully!' : 'Medicine updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${medicineViewModel.error}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: GlowingTextField(
            controller: controller,
            hintText: hintText,
            icon: icon,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: (value) {},
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0xFF636AE8).withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF636AE8).withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: const Color(0xFF0D0D1A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  child: Icon(icon, color: Colors.white70),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              ),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onChanged,
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: InteractiveParticleBackground(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.medicine == null ? 'Add New Medicine' : 'Edit Medicine',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildFormField(
                          controller: _nameController,
                          hintText: 'Medicine Name',
                          icon: Icons.medication_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter medicine name';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          controller: _imageUrlController,
                          hintText: 'Image URL (Optional)',
                          icon: Icons.image_outlined,
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null;
                            }
                            final uri = Uri.tryParse(value);
                            if (uri == null || !uri.isAbsolute) {
                              return 'Please enter a valid URL format';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          controller: _descriptionController,
                          hintText: 'Description',
                          icon: Icons.description,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter description';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          controller: _priceController,
                          hintText: 'Price',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null || double.parse(value) < 0) {
                              return 'Please enter a valid positive price';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          controller: _quantityController,
                          hintText: 'Quantity',
                          icon: Icons.inventory_2,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null || int.parse(value) < 0) {
                              return 'Please enter a valid positive quantity';
                            }
                            return null;
                          },
                        ),
                        _buildDropdownField(
                            label: 'Category',
                            icon: Icons.category,
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            }
                        ),
                        _buildFormField(
                          controller: _expiryDateController,
                          hintText: 'Expiry Date',
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select expiry date';
                            }
                            return null;
                          },
                        ),
                        _buildDropdownField(
                            label: 'Can Be Sold',
                            icon: Icons.sell_outlined,
                            value: _selectedCanBeSell,
                            items: _canBeSellOptions,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCanBeSell = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please specify if it can be sold';
                              }
                              return null;
                            }
                        ),
                        if (_selectedCanBeSell == 'Yes') ...[
                          _buildFormField(
                            controller: _quantityToSellController,
                            hintText: 'Quantity To Sell',
                            icon: Icons.shopping_cart_checkout_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity to sell';
                              }
                              final intValue = int.tryParse(value);
                              if (intValue == null || intValue < 0) {
                                return 'Please enter a valid positive quantity';
                              }
                              final totalQuantity = int.tryParse(_quantityController.text);
                              if (totalQuantity != null && intValue > totalQuantity) {
                                return 'Quantity to sell cannot exceed total quantity';
                              }
                              return null;
                            },
                          ),
                          _buildFormField(
                            controller: _priceSellController,
                            hintText: 'Sell Price',
                            icon: Icons.price_change_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter sell price';
                              }
                              if (double.tryParse(value) == null || double.parse(value) < 0) {
                                return 'Please enter a valid positive price';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        PulsingActionButton(
                          label: _isLoading
                              ? (widget.medicine == null ? 'Adding...' : 'Updating...')
                              : (widget.medicine == null ? 'Add Medicine' : 'Update Medicine'),
                          onTap: _isLoading ? () {} : _handleSubmit,
                          buttonColor: const Color(0xFF636AE8),
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
    );
  }
}