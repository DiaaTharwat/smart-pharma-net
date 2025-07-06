import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/medicine_screen.dart';
import 'package:smart_pharma_net/view/Screens/exchange_screen.dart';
import 'package:smart_pharma_net/view/Screens/pricing_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


enum PharmacyLoginTargetScreen {
  medicineScreen,
  exchangeScreen,
  pricingScreen,
}

class PharmacyLoginScreen extends StatefulWidget {
  final String? pharmacyId;
  final bool isAdminViewing;
  final PharmacyLoginTargetScreen targetScreen;

  const PharmacyLoginScreen({
    Key? key,
    this.pharmacyId,
    this.isAdminViewing = false,
    this.targetScreen = PharmacyLoginTargetScreen.medicineScreen,
  }) : super(key: key);

  @override
  State<PharmacyLoginScreen> createState() => _PharmacyLoginScreenState();
}

class _PharmacyLoginScreenState extends State<PharmacyLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadPharmacyInfo();
    _setupAnimations();
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

  Future<void> _loadPharmacyInfo() async {
    if (widget.pharmacyId != null && widget.pharmacyId!.isNotEmpty) {
      try {
        final pharmacyViewModel = Provider.of<PharmacyViewModel>(context, listen: false);
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final pharmacy = await pharmacyViewModel.getPharmacyDetails(widget.pharmacyId!);
        if (mounted) {
          setState(() {
            _nameController.text = pharmacy.name;
          });
        }
      } catch (e) {
        print('Error loading pharmacy name: $e');
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load pharmacy details: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ========== Fix Start: Handling the String? return type correctly ==========
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // The function now returns an error message string on failure, and null on success.
    final String? errorResult = await authViewModel.pharmacyLogin(
      name: _nameController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // If errorResult is null, it means login was successful.
      if (errorResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Welcome.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MenuBarScreen(),
          ),
        );

      } else {
        // If there's an error string, this is the failure case.
        setState(() {
          _errorMessage = errorResult;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }
  // ========== Fix End ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InteractiveParticleBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF636AE8).withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF636AE8).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_pharmacy,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Pharmacy Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 15.0, color: Color(0xFF636AE8)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _nameController.text.isNotEmpty ? 'Welcome to ${_nameController.text}' : 'Login to your pharmacy account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlowingTextField(
                            controller: _nameController,
                            hintText: 'Pharmacy Name',
                            icon: Icons.store,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter pharmacy name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          GlowingTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock,
                            isPassword: true,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade400),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade200),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                          PulsingActionButton(
                            label: 'LOGIN',
                            onTap: _isLoading ? () {} : _handleLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}