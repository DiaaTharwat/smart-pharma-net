import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/medicine_model.dart';
import 'package:smart_pharma_net/models/user_purchase_model.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/viewmodels/purchase_viewmodel.dart';

class UserPurchaseScreen extends StatefulWidget {
  final MedicineModel medicine;

  const UserPurchaseScreen({Key? key, required this.medicine}) : super(key: key);

  @override
  State<UserPurchaseScreen> createState() => _UserPurchaseScreenState();
}

class _UserPurchaseScreenState extends State<UserPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

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

    final purchaseViewModel =
    Provider.of<PurchaseViewModel>(context, listen: false);

    final purchaseData = UserPurchaseModel(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      medicine: widget.medicine.name,
    );

    final success = await purchaseViewModel.submitPurchase(purchaseData);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase successful! Your request has been sent.'),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(top: 100),
            child: Column(
              children: [
                Text(
                  'Buy from ${widget.medicine.pharmacyName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlowingTextField(
                        controller: _usernameController,
                        hintText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          if (value.length > 150) {
                            return 'Username cannot exceed 150 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          if (value.length > 254) {
                            return 'Email cannot exceed 254 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: _phoneController,
                        hintText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Colors.white70),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length > 15) {
                            return 'Phone number cannot exceed 15 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GlowingTextField(
                        controller: _addressController,
                        hintText: 'Address',
                        prefixIcon: const Icon(Icons.home_outlined, color: Colors.white70),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your address';
                          }
                          if (value.length > 255) {
                            return 'Address cannot exceed 255 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      PulsingActionButton(
                        label: purchaseViewModel.isLoading ? 'Processing...' : 'Confirm Purchase',
                        onTap: purchaseViewModel.isLoading ? () {} : _handleSubmit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
