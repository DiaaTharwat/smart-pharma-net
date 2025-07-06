import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/medicine_viewmodel.dart';
import 'package:smart_pharma_net/view/Widgets/notification_icon.dart';
import '../../models/medicine_model.dart';
import 'add_medicine_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({Key? key}) : super(key: key);

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
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

  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final authVm = context.read<AuthViewModel>();
        final medicineVm = context.read<MedicineViewModel>();
        final pharmacyId = authVm.activePharmacyId;

        if (pharmacyId != null) {
          medicineVm.loadMedicines(pharmacyId: pharmacyId);
        } else {
          print("Error: No pharmacy context found in MedicineScreen.");
        }
      }
    });
  }

  // ========== Fix Start: Modified back navigation logic ==========
  Future<void> _handleBackNavigation() async {
    final authViewModel = context.read<AuthViewModel>();
    // Stop impersonation only if it's an admin impersonating
    if (authViewModel.isImpersonating) {
      await authViewModel.stopImpersonation();
    }
    // For all cases (admin or pharmacy), just pop the screen
    if (mounted) {
      Navigator.pop(context);
    }
  }
  // ========== Fix End ==========


  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMedicineCard(MedicineModel medicine, double cardWidth) {
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
        child: InkWell(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    return WillPopScope(
      onWillPop: () async {
        await _handleBackNavigation();
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
                            onPressed: _handleBackNavigation,
                          ),
                          if (authViewModel.isPharmacy)
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
                          Expanded(
                            child: Text(
                              authViewModel.activePharmacyName ?? 'Medicines',
                              style: const TextStyle(
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
                            onPressed: _initializeData,
                          ),
                          if (authViewModel.canActAsPharmacy) const NotificationIcon(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: GlowingTextField(
                            controller: _searchController,
                            hintText: 'Search medicines...',
                            icon: Icons.search,
                            onChanged: (value) async {
                              final pharmacyId = authViewModel.activePharmacyId;
                              if (pharmacyId != null) {
                                context.read<MedicineViewModel>().searchMedicines(value, pharmacyId: pharmacyId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Consumer<MedicineViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF636AE8))));
                    }
                    if (viewModel.medicines.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_outlined, size: 80, color: Colors.grey.shade600),
                            const SizedBox(height: 20),
                            Text('No medicines found', style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      );
                    }
                    final screenPadding = const EdgeInsets.all(20.0);
                    final horizontalSpacing = 20.0;
                    final verticalSpacing = 20.0;
                    return RefreshIndicator(
                      onRefresh: _initializeData,
                      color: const Color(0xFF636AE8),
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: SingleChildScrollView(
                        padding: screenPadding,
                        child: Wrap(
                          spacing: horizontalSpacing,
                          runSpacing: verticalSpacing,
                          alignment: WrapAlignment.start,
                          children: viewModel.medicines.map((medicine) {
                            final double screenWidth = MediaQuery.of(context).size.width;
                            final double totalHorizontalPadding = screenPadding.left + screenPadding.right;
                            final double totalSpacing = horizontalSpacing * 2;
                            final double cardWidth = (screenWidth > 1200) ? (screenWidth - totalHorizontalPadding - totalSpacing) / 3 : (screenWidth > 800) ? (screenWidth - totalHorizontalPadding - horizontalSpacing) / 2 : (screenWidth - totalHorizontalPadding);
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final pharmacyId = authViewModel.activePharmacyId;
            if (pharmacyId == null) return;

            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => AddMedicineScreen(pharmacyId: pharmacyId),
              ),
            );
            if (result == true && mounted) {
              _initializeData();
            }
          },
          backgroundColor: const Color(0xFF636AE8),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          label: const Text('Add Medicine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
        ),
      ),
    );
  }

  void _showMedicineDetails(MedicineModel medicine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMedicineDetailsSheet(medicine),
    );
  }

  Widget _buildMedicineDetailsSheet(MedicineModel medicine) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF636AE8).withOpacity(0.6),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.medication_outlined, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailCard(title: 'Category', value: medicine.category, icon: Icons.category),
                      const SizedBox(height: 20),
                      _buildDetailCard(title: 'Description', value: medicine.description, icon: Icons.description),
                      const SizedBox(height: 20),
                      _buildDetailCard(title: 'Price', value: '\$${medicine.price.toStringAsFixed(2)}', icon: Icons.attach_money),
                      const SizedBox(height: 20),
                      _buildDetailCard(title: 'Quantity', value: '${medicine.quantity} units', icon: Icons.inventory_2),
                      const SizedBox(height: 20),
                      _buildDetailCard(title: 'Expiry Date', value: medicine.expiryDate, icon: Icons.calendar_today),
                      const SizedBox(height: 20),
                      _buildDetailCard(title: 'Sell Price', value: '\$${medicine.priceSell.toStringAsFixed(2)}', icon: Icons.sell),
                      const SizedBox(height: 20),
                      _buildDetailCard(title: 'Quantity To Sell', value: '${medicine.quantityToSell ?? 'N/A'} units', icon: Icons.shopping_cart),
                      const SizedBox(height: 30),
                      _buildAdminActionButtons(medicine)
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({required String title, required String value, required IconData icon,}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF636AE8).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF636AE8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7),),),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionButtons(MedicineModel medicine) {
    return Row(
      children: [
        Expanded(
          child: PulsingActionButton(
            label: 'Edit',
            onTap: () => _handleEditMedicine(medicine),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: PulsingActionButton(
            label: 'Delete',
            buttonColor: Colors.red,
            shadowBaseColor: Colors.red,
            onTap: () => _handleDeleteMedicine(medicine),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEditMedicine(MedicineModel medicine) async {
    Navigator.pop(context);
    final authViewModel = context.read<AuthViewModel>();
    final pharmacyId = authViewModel.activePharmacyId;
    if(pharmacyId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          pharmacyId: pharmacyId,
          medicine: medicine,
        ),
      ),
    );
    if (result == true && mounted) {
      _initializeData();
    }
  }

  Future<void> _handleDeleteMedicine(MedicineModel medicine) async {
    Navigator.pop(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
        ),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this medicine?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authViewModel = context.read<AuthViewModel>();
      final pharmacyId = authViewModel.activePharmacyId;
      if(pharmacyId == null) return;

      try {
        await context.read<MedicineViewModel>().deleteMedicine(
            pharmacyId: pharmacyId,
            medicineId: medicine.id
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medicine deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _initializeData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting medicine: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}