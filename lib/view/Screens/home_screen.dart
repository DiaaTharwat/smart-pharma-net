// lib/view/Screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/view/Screens/welcome_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../models/medicine_model.dart';
import 'add_medicine_screen.dart';
import 'chat_ai_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'user_purchase_screen.dart'; // Import the new screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = false;
  bool _isPharmacyUser = false;
  String? _currentPharmacyIdForUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSortingByDistance = false;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkUserStatus();
      final authViewModel = context.read<AuthViewModel>();
      final medicineViewModel = context.read<MedicineViewModel>();
      final pharmacyViewModel = context.read<PharmacyViewModel>();

      medicineViewModel.loadMedicines(
          pharmacyId: _currentPharmacyIdForUser, forceLoadAll: authViewModel.isAdmin && !authViewModel.isPharmacy);

      pharmacyViewModel.loadPharmacies(searchQuery: '').catchError((error) {
        print("Could not load pharmacies, continuing without them. Error: $error");
      });
    });
  }

  Future<void> _checkUserStatus() async {
    final authViewModel = context.read<AuthViewModel>();
    final role = await authViewModel.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
        _isPharmacyUser = role == 'pharmacy';
      });
      if (_isPharmacyUser) {
        _currentPharmacyIdForUser = await authViewModel.getPharmacyId();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (route) => false);
    }
  }

  Future<void> _returnToAdminHomeAndLogoutPharmacy() async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.restoreAdminSession();
    if(mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<LatLng?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ));
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.'),
                backgroundColor: Colors.orangeAccent,
                behavior: SnackBarBehavior.fixed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              ));
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied. Please enable them from app settings.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ));
      }
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get current location: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.fixed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ));
      }
      return null;
    }
  }

  Future<void> _handleDeleteMedicine(BuildContext context, MedicineModel medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
        ),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${medicine.name}?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final medicineViewModel = context.read<MedicineViewModel>();
      try {
        await medicineViewModel.deleteMedicine(medicine.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully'), backgroundColor: Colors.green),
          );
          medicineViewModel.loadMedicines(forceLoadAll: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete medicine: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleEditMedicine(BuildContext context, MedicineModel medicine) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          medicine: medicine,
          pharmacyId: medicine.pharmacyId,
        ),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Medicine updated successfully!'),
            backgroundColor: Colors.green),
      );
      context.read<MedicineViewModel>().loadMedicines(forceLoadAll: true);
    }
  }


  Widget _buildMedicineCard(MedicineModel medicine, double cardWidth) {
    final pharmacyViewModel = context.read<PharmacyViewModel>();
    final ownedPharmacyIds = pharmacyViewModel.pharmacies.map((p) => p.id).toSet();
    final bool canAdminEdit = _isAdmin && ownedPharmacyIds.contains(medicine.pharmacyId);

    Widget imageWidget;
    if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        medicine.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.medication_liquid_outlined,
            size: 90,
            color: Color(0xFF636AE8),
          );
        },
      );
    } else {
      imageWidget = const Icon(
        Icons.medication_liquid_outlined,
        size: 90,
        color: Color(0xFF636AE8),
      );
    }

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3), width: 1.0),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _showMedicineDetails(medicine),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF636AE8).withOpacity(0.2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: imageWidget,
                        ),
                        if (medicine.canBeSell)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          medicine.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          medicine.category,
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (!_isPharmacyUser) ...[
                          Row(
                            children: [
                              Icon(Icons.store_outlined, size: 12, color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  medicine.pharmacyName,
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 11, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Exp: ${medicine.expiryDate}',
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${medicine.quantity} units',
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            ),
                            Text(
                              '\$${medicine.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 17, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- إضافة: أزرار التحكم للمالك ---
            if(canAdminEdit) ...[
              const Divider(color: Color(0xFF636AE8), height: 1),
              Container(
                color: const Color(0xFF636AE8).withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                      tooltip: 'Edit Medicine',
                      onPressed: () => _handleEditMedicine(context, medicine),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                      tooltip: 'Delete Medicine',
                      onPressed: () => _handleDeleteMedicine(context, medicine),
                    ),
                  ],
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showMedicineDetails(MedicineModel medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserPurchaseScreen(medicine: medicine)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final medicineViewModel = context.watch<MedicineViewModel>();

    return WillPopScope(
      onWillPop: () async {
        if (authViewModel.isAdmin && authViewModel.isPharmacy) {
          await _returnToAdminHomeAndLogoutPharmacy();
          return false;
        }
        return true;
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MenuBarScreen(),
                                ),
                              );
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'Smart PharmaNet',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          InkWell(
                            onTap: authViewModel.isAdmin && authViewModel.isPharmacy
                                ? _returnToAdminHomeAndLogoutPharmacy
                                : () => _handleLogout(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    authViewModel.isAdmin && authViewModel.isPharmacy
                                        ? Icons.exit_to_app
                                        : Icons.logout,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    authViewModel.isAdmin && authViewModel.isPharmacy
                                        ? 'Exit Pharmacy'
                                        : 'Logout',
                                    style: const TextStyle(color: Colors.white, fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Available Medications',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 8.0, color: Color(0xFF636AE8))],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            GlowingTextField(
                              controller: _searchController,
                              hintText: 'Search medicines...',
                              icon: Icons.search,
                              onChanged: (value) {
                                setState(() { _searchQuery = value; });
                                context
                                    .read<MedicineViewModel>()
                                    .searchMedicines(value, pharmacyId: _isPharmacyUser ? _currentPharmacyIdForUser : null);
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: Icon(
                                _isLoadingLocation
                                    ? null
                                    : (_isSortingByDistance ? Icons.filter_list_off_outlined : Icons.location_on_outlined),
                                color: _isLoadingLocation ? Colors.transparent : Colors.white,
                                size: 24,
                              ),
                              label: _isLoadingLocation
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                                  : Text(
                                _isSortingByDistance ? "CLEAR SORT" : "SORT BY DISTANCE",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF636AE8).withAlpha(_isSortingByDistance ? 200: 255),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                    side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.0)
                                ),
                                elevation: 5,
                                shadowColor: const Color(0xFF636AE8).withOpacity(0.6),
                              ),
                              onPressed: _isLoadingLocation ? null : () async {
                                final pharmacyViewModel = context.read<PharmacyViewModel>();
                                final medicineViewModel = context.read<MedicineViewModel>();
                                setState(() { _isLoadingLocation = true; });
                                if (_isSortingByDistance) {
                                  medicineViewModel.clearDistanceSort(pharmacyIdForReset: _currentPharmacyIdForUser);
                                  setState(() { _isSortingByDistance = false; });
                                } else {
                                  LatLng? userLocation = await _getUserLocation();
                                  if (userLocation != null && mounted) {
                                    if (pharmacyViewModel.pharmacies.isEmpty) {
                                      await pharmacyViewModel.loadPharmacies(searchQuery: '');
                                    }
                                    if (!_isPharmacyUser && (medicineViewModel.medicines.length != medicineViewModel.medicines.length || _searchQuery.isNotEmpty)) {
                                      await medicineViewModel.loadMedicines(forceLoadAll: true);
                                    }

                                    if (mounted && pharmacyViewModel.pharmacies.isNotEmpty) {
                                      await medicineViewModel.sortMedicinesByDistance(userLocation, pharmacyViewModel.pharmacies);
                                      setState(() { _isSortingByDistance = true; });
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Could not load pharmacies for sorting.'),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.fixed,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                          ));
                                    }
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not get location. Please ensure location services and permissions are enabled.'),
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                        ));
                                  }
                                }
                                setState(() { _isLoadingLocation = false; });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Consumer<MedicineViewModel>(
                  builder: (context, medicineViewModel, child) {
                    if (medicineViewModel.isLoading && !_isLoadingLocation) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                        ),
                      );
                    }

                    if (medicineViewModel.error.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Error: ${medicineViewModel.error}',
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 17,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            PulsingActionButton(
                              label: 'Retry',
                              onTap: () {
                                medicineViewModel.loadMedicines(pharmacyId: _currentPharmacyIdForUser, forceLoadAll: !_isPharmacyUser);
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    final displayedMedicines = medicineViewModel.medicines;

                    if (displayedMedicines.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty ? 'No medicines match your search' : 'No medicines found',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Try a different search term',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    final screenPadding = const EdgeInsets.all(20.0);
                    final horizontalSpacing = 20.0;
                    final verticalSpacing = 20.0;

                    return RefreshIndicator(
                      onRefresh: () async {
                        medicineViewModel.loadMedicines(pharmacyId: _currentPharmacyIdForUser, forceLoadAll: !_isPharmacyUser);
                      },
                      color: const Color(0xFF636AE8),
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: SingleChildScrollView(
                        padding: screenPadding,
                        child: Wrap(
                          spacing: horizontalSpacing,
                          runSpacing: verticalSpacing,
                          alignment: WrapAlignment.start,
                          children: displayedMedicines.map((medicine) {
                            final double screenWidth = MediaQuery.of(context).size.width;
                            final double totalHorizontalPadding = screenPadding.left + screenPadding.right;
                            final double totalSpacing = horizontalSpacing * 2;
                            final double cardWidth = (screenWidth - totalHorizontalPadding - totalSpacing) / 3;
                            return _buildMedicineCard(medicine, cardWidth);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Stack(
          children: <Widget>[
            if (_isPharmacyUser)
              Positioned(
                bottom: 0,
                right: 0,
                child: FloatingActionButton.extended(
                  heroTag: 'add_medicine_fab',
                  onPressed: () async {
                    if (_currentPharmacyIdForUser != null && mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMedicineScreen(
                            pharmacyId: _currentPharmacyIdForUser!,
                          ),
                        ),
                      );
                      if (result == true && mounted && _currentPharmacyIdForUser != null) {
                        medicineViewModel.loadMedicines(pharmacyId: _currentPharmacyIdForUser);
                      }
                    } else if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not determine pharmacy to add medicine.'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.fixed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ));
                    }
                  },
                  backgroundColor: const Color(0xFF636AE8),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
              ),
            Positioned(
              bottom: _isPharmacyUser ? 80.0 : 0.0,
              right: 0,
              child: FloatingActionButton(
                heroTag: 'chat_ai_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatAiScreen()),
                  );
                },
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                tooltip: 'Chat with AI',
                child: const Icon(Icons.support_agent, color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}