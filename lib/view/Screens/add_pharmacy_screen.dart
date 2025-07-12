// lib/view/Screens/add_pharmacy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/admin_login_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';

class AddPharmacyScreen extends StatefulWidget {
  final PharmacyModel? pharmacyToEdit;

  const AddPharmacyScreen({super.key, this.pharmacyToEdit});

  @override
  State<AddPharmacyScreen> createState() => _AddPharmacyScreenState();
}

class _AddPharmacyScreenState extends State<AddPharmacyScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isLoading = false;
  late final MapController _mapController;
  bool _isMapReady = false;
  late bool _isEditMode;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isEditMode = widget.pharmacyToEdit != null;

    if (_isEditMode) {
      final pharmacy = widget.pharmacyToEdit!;
      _nameController.text = pharmacy.name;
      // =========================================================================
      // =================== START: الكود الذي تم تعديله =======================
      // =========================================================================
      // ✨ استخدام '??' لتوفير قيمة افتراضية في حال كانت القيمة null
      _cityController.text = pharmacy.city ?? '';
      _licenseNumberController.text = pharmacy.licenseNumber ?? '';
      _latitudeController.text = (pharmacy.latitude ?? 0.0).toString();
      _longitudeController.text = (pharmacy.longitude ?? 0.0).toString();
      if (pharmacy.latitude != null && pharmacy.longitude != null) {
        _selectedLocation = LatLng(pharmacy.latitude!, pharmacy.longitude!);
      }
      // =========================================================================
      // ==================== END: الكود الذي تم تعديله ======================
      // =========================================================================
    }

    _setupAnimations();
    if (!_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _getCurrentLocation());
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
    _cityController.dispose();
    _licenseNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // _mapController is disposed by the FlutterMap widget itself
    _controller.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isMapReady = true;
      });

      _mapController.move(_selectedLocation!, 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error getting location: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final pharmacyViewModel = Provider.of<PharmacyViewModel>(context, listen: false);
        final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
        final latitude = double.parse(_latitudeController.text);
        final longitude = double.parse(_longitudeController.text);

        if (_isEditMode) {
          await pharmacyViewModel.updatePharmacy(
            id: widget.pharmacyToEdit!.id,
            name: _nameController.text,
            city: _cityController.text,
            licenseNumber: _licenseNumberController.text,
            latitude: latitude,
            longitude: longitude,
            password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
            authViewModel: authViewModel,
          );
        } else {
          await pharmacyViewModel.addPharmacy(
            name: _nameController.text,
            city: _cityController.text,
            licenseNumber: _licenseNumberController.text,
            latitude: latitude,
            longitude: longitude,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            authViewModel: authViewModel,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(_isEditMode ? 'Pharmacy updated successfully' : 'Pharmacy added successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = _isEditMode ? 'Error updating pharmacy' : 'Error adding pharmacy';
          if (e.toString().contains('Authentication') ||
              e.toString().contains('login') ||
              e.toString().contains('Session expired')) {
            errorMessage = 'Session expired. Please login again.';
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminLoginScreen(),
              ),
            );
          } else {
            errorMessage = e.toString();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GlowingTextField(
          controller: controller,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.white70),
          isPassword: isPassword,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ),
    );
  }


  Widget _buildMapSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF636AE8).withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(31.9539, 35.9106),
                    initialZoom: 13.0,
                    onMapReady: () {
                      setState(() => _isMapReady = true);
                      if (_isEditMode && _selectedLocation != null) {
                        _mapController.move(_selectedLocation!, 15.0);
                      }
                    },
                    onTap: (_, point) {
                      setState(() {
                        _selectedLocation = point;
                        _latitudeController.text = point.latitude.toStringAsFixed(6);
                        _longitudeController.text = point.longitude.toStringAsFixed(6);
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_on, color: Color(0xFF636AE8), size: 50),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F1A),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF636AE8).withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Tap to select location',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
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
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      Expanded(
                        child: Text(
                          _isEditMode ? 'Edit Pharmacy' : 'Add New Pharmacy',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildFormField(
                          controller: _nameController,
                          hintText: 'Pharmacy Name',
                          icon: Icons.business,
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter pharmacy name' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildFormField(
                          controller: _cityController,
                          hintText: 'City',
                          icon: Icons.location_city,
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter city name' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildFormField(
                          controller: _licenseNumberController,
                          hintText: 'License Number',
                          icon: Icons.assignment,
                          validator: (value) => (value == null || value.isEmpty) ? 'Please enter license number' : null,
                        ),
                        const SizedBox(height: 24),

                        _buildMapSection(),
                        const SizedBox(height: 16),

                        PulsingActionButton(
                          label: 'Use Current Location',
                          onTap: _getCurrentLocation,
                          buttonColor: const Color(0xFF636AE8),
                        ),
                        const SizedBox(height: 24),

                        _buildFormField(
                          controller: _passwordController,
                          hintText: _isEditMode ? 'New Password (Optional)' : 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (!_isEditMode && (value == null || value.isEmpty)) {
                              return 'Please enter password';
                            }
                            if (value != null && value.isNotEmpty && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildFormField(
                          controller: _confirmPasswordController,
                          hintText: _isEditMode ? 'Confirm New Password' : 'Confirm Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          validator: (value) {
                            if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        PulsingActionButton(
                          label: _isLoading
                              ? (_isEditMode ? 'Updating...' : 'Adding...')
                              : (_isEditMode ? 'UPDATE PHARMACY' : 'ADD PHARMACY'),
                          onTap: _isLoading ? () {} : _handleSubmit,
                          buttonColor: const Color(0xFF636AE8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}