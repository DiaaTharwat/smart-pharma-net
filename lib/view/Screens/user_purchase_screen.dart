// lib/view/Screens/user_purchase_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/medicine_model.dart';
import 'package:smart_pharma_net/models/user_purchase_model.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/viewmodels/purchase_viewmodel.dart';

class UserPurchaseScreen extends StatefulWidget {
  final MedicineModel medicine;

  const UserPurchaseScreen({Key? key, required this.medicine})
      : super(key: key);

  @override
  State<UserPurchaseScreen> createState() => _UserPurchaseScreenState();
}

class _UserPurchaseScreenState extends State<UserPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedPurchaseType;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPurchaseType == 'visa') {
      final visaPaymentSuccess = await _showModernVisaDialog();
      if (visaPaymentSuccess == null || !visaPaymentSuccess) {
        return;
      }
    }

    final purchaseViewModel =
    Provider.of<PurchaseViewModel>(context, listen: false);

    final purchaseData = UserPurchase(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      medicine: widget.medicine.name,
      typePurchase: _selectedPurchaseType,
    );

    final success = await purchaseViewModel.submitPurchase(purchaseData);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'The operation was successful, and a confirmation message will be sent to the registered email.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
        _formKey.currentState?.reset();
        _usernameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _addressController.clear();
        setState(() {
          _selectedPurchaseType = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Purchase failed: ${purchaseViewModel.errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseViewModel = context.watch<PurchaseViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveParticleBackground(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 24.0).copyWith(top: 100),
            child: Column(
              children: [
                Text(
                  'Buy from ${widget.medicine.pharmacyName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Medicine: ${widget.medicine.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlowingTextField(
                        controller: _usernameController,
                        hintText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.white70),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Colors.white70),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: _phoneController,
                        hintText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: Colors.white70),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: _addressController,
                        hintText: 'Address',
                        prefixIcon: const Icon(Icons.home_outlined,
                            color: Colors.white70),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildGlowingDropdown(),
                      const SizedBox(height: 40),
                      PulsingActionButton(
                        label: purchaseViewModel.isLoading
                            ? 'Processing...'
                            : 'Confirm Purchase',
                        onTap:
                        purchaseViewModel.isLoading ? () {} : _handleSubmit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.5),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C54), Color(0xFF1A1A3D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPurchaseType,
        hint: const Text(
          'Select Payment Method',
          style: TextStyle(color: Colors.white70),
        ),
        onChanged: (String? newValue) {
          setState(() {
            _selectedPurchaseType = newValue;
          });
        },
        validator: (value) =>
        value == null ? 'Please select a payment method' : null,
        decoration: InputDecoration(
          prefixIcon:
          const Icon(Icons.payment_outlined, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Color(0xFF636AE8), width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
        dropdownColor: const Color(0xFF2C2C54),
        style: const TextStyle(color: Colors.white),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        items: <String>['cash_on_delivery', 'visa']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
                value == 'cash_on_delivery' ? 'Cash on Delivery' : 'Visa'),
          );
        }).toList(),
      ),
    );
  }

  Future<bool?> _showModernVisaDialog() {
    final visaFormKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryDateController = TextEditingController();
    final cvcController = TextEditingController();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF636AE8), width: 0.5),
          ),
          title: const Center(
            child: Text(
              'Enter Card Details',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: Form(
            key: visaFormKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  GlowingTextField(
                    controller: cardNumberController,
                    hintText: 'Card Number',
                    prefixIcon:
                    const Icon(Icons.credit_card, color: Colors.white70),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    validator: (v) => v == null || v.length != 16
                        ? 'Must be 16 digits'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GlowingTextField(
                          controller: expiryDateController,
                          hintText: 'MM/YY',
                          prefixIcon: const Icon(Icons.calendar_today,
                              color: Colors.white70),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (v) =>
                          v == null || v.length != 4 ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlowingTextField(
                          controller: cvcController,
                          hintText: 'CVC',
                          prefixIcon:
                          const Icon(Icons.lock, color: Colors.white70),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (v) =>
                          v == null || v.length != 3 ? '3 digits' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF636AE8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  child: const Text('Confirm Payment',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  onPressed: () {
                    if (visaFormKey.currentState!.validate()) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }
}