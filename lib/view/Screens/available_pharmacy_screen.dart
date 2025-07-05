// lib/view/Screens/available_pharmacy_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
// import 'package:smart_pharma_net/view/Screens/pharmacy_login_screen.dart'; // لم نعد بحاجة إليه هنا
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/add_pharmacy_screen.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_details_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/view/Screens/medicine_screen.dart'; // --- إضافة جديدة ---

class AvailablePharmaciesScreen extends StatefulWidget {
  const AvailablePharmaciesScreen({super.key});

  @override
  State<AvailablePharmaciesScreen> createState() =>
      _AvailablePharmaciesScreenState();
}

class _AvailablePharmaciesScreenState extends State<AvailablePharmaciesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPharmacies();
      _checkUserRole();
    });
  }

  Future<void> _checkUserRole() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userRole = await authViewModel.getUserRole();
    if (mounted) {
      setState(() {
        _isAdmin = userRole == 'admin';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    final pharmacyViewModel =
    Provider.of<PharmacyViewModel>(context, listen: false);
    pharmacyViewModel.loadPharmacies(searchQuery: _searchController.text.trim());
  }

  void _goToAdminHome() {
    // التأكد من إيقاف أي وضع تقمص شخصية عند العودة للشاشة الرئيسية
    context.read<AuthViewModel>().stopImpersonation();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
    );
  }

  // --- تم تعديل هذه الدالة بالكامل ---
  Widget _buildPharmacyCard(PharmacyModel pharmacy, int index) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
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
          // تم تغيير الهدف من الضغط على الكارت
          // أصبح الآن يقوم بتفعيل وضع التقمص والانتقال لشاشة الأدوية
          child: InkWell(
            onTap: () async {
              final authViewModel = context.read<AuthViewModel>();
              await authViewModel.impersonatePharmacy(pharmacy);
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MedicineScreen()),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF636AE8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pharmacy.city,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isAdmin)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF0F0F1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          onSelected: (value) async {
                            if (value == 'details') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PharmacyDetailsScreen(pharmacy: pharmacy),
                                ),
                              );
                            } else if (value == 'edit') {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddPharmacyScreen(pharmacyToEdit: pharmacy),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadPharmacies();
                              }
                            } else if (value == 'delete') {
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF0F0F1A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
                                  ),
                                  title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
                                  content: Text('Are you sure you want to delete ${pharmacy.name}?', style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                  ],
                                ),
                              );

                              if (confirmDelete == true && mounted) {
                                try {
                                  await context.read<PharmacyViewModel>().deletePharmacy(pharmacy.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pharmacy deleted successfully'),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.fixed,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      ),
                                    );
                                    _loadPharmacies();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete pharmacy: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.fixed,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          // تم إضافة خيار "التفاصيل"
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.cyan),
                                  const SizedBox(width: 8),
                                  Text('Details', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: Color(0xFF636AE8)),
                                  const SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge,
                        size: 20,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'License: ${pharmacy.licenseNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // تم تغيير وظيفة الزر أيضًا
                  PulsingActionButton(
                    label: 'Manage Pharmacy',
                    onTap: () async {
                      final authViewModel = context.read<AuthViewModel>();
                      await authViewModel.impersonatePharmacy(pharmacy);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MedicineScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyViewModel = Provider.of<PharmacyViewModel>(context);

    return WillPopScope(
      onWillPop: () async {
        _goToAdminHome();
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                            onPressed: _goToAdminHome,
                          ),
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
                              'Available Pharmacies',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                            onPressed: () => _loadPharmacies(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: GlowingTextField(
                            controller: _searchController,
                            hintText: 'Search pharmacies...',
                            icon: Icons.search,
                            onChanged: (value) {
                              pharmacyViewModel.loadPharmacies(searchQuery: value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: pharmacyViewModel.isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                  ),
                )
                    : pharmacyViewModel.pharmacies.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_pharmacy,
                        size: 80,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _searchController.text.isNotEmpty ? 'No pharmacies match your search' : 'No pharmacies found',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty) ...[
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
                )
                    : RefreshIndicator(
                  onRefresh: _loadPharmacies,
                  color: const Color(0xFF636AE8),
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: pharmacyViewModel.pharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = pharmacyViewModel.pharmacies[index];
                      return _buildPharmacyCard(pharmacy, index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _isAdmin
            ? FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPharmacyScreen(),
              ),
            );
            if (result == true) {
              _loadPharmacies();
            }
          },
          backgroundColor: const Color(0xFF636AE8),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Pharmacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        )
            : null,
      ),
    );
  }
}