// lib/view/Screens/exchange_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/exchange_medicine_model.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/exchange_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_login_screen.dart';
import 'package:smart_pharma_net/view/Widgets/notification_icon.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';


class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({Key? key}) : super(key: key);

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPharmacyAccessAndLoadMedicines();
    });
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

  Future<void> _checkPharmacyAccessAndLoadMedicines() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    // Use the new getter to check for access
    if (!authViewModel.canActAsPharmacy) {
      // Logic for what happens if not logged in as a pharmacy or impersonating
    } else {
      context.read<ExchangeViewModel>().loadExchangeMedicines();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    Navigator.pop(context);
  }

  Future<void> _logoutFromPharmacy() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      await authViewModel.restoreAdminSession();
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Logged out from pharmacy session.'),
            backgroundColor: Color(0xFF636AE8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to logout from pharmacy: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: InteractiveParticleBackground(
            child: Consumer<ExchangeViewModel>(
              builder: (context, exchangeViewModel, child) {
                if (exchangeViewModel.exchangeOrderPlacedSuccessfully) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exchange order placed successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    );
                    exchangeViewModel.resetExchangeOrderPlacedSuccess();
                  });
                }

                return Column(
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
                                    // --- إصلاح: تم استخدام المتغير الصحيح ---
                                    authViewModel.canActAsPharmacy
                                        ? 'Exchange for ${authViewModel.currentPharmacyName}'
                                        : 'Medicine Exchange',
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
                                  onPressed: () => context
                                      .read<ExchangeViewModel>()
                                      .loadExchangeMedicines(),
                                ),
                                const NotificationIcon(),
                                if (authViewModel.isAdmin && authViewModel.isPharmacy)
                                  IconButton(
                                    icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 28),
                                    tooltip: 'Logout from Pharmacy',
                                    onPressed: _logoutFromPharmacy,
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
                                  hintText: 'Search medicines or pharmacies...',
                                  icon: Icons.search,
                                  onChanged: (value) {
                                    context
                                        .read<ExchangeViewModel>()
                                        .setSearchQuery(value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if (exchangeViewModel.isLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                              ),
                            );
                          }
                          if (exchangeViewModel.errorMessage != null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 60,
                                      color: Colors.red.shade400,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Error: ${exchangeViewModel.errorMessage}',
                                      style:
                                      TextStyle(color: Colors.red.shade200, fontSize: 17),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    PulsingActionButton(
                                      label: 'Retry',
                                      onTap: () => exchangeViewModel.loadExchangeMedicines(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (exchangeViewModel.exchangeMedicines.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_pharmacy_outlined,
                                    size: 80,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'No matching medicines found.'
                                        : 'No medicines available for exchange right now.',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Try a different search term or clear the search.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  PulsingActionButton(
                                    label: 'Refresh List',
                                    onTap: () => exchangeViewModel.loadExchangeMedicines(),
                                  ),
                                ],
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () => exchangeViewModel.loadExchangeMedicines(),
                            color: const Color(0xFF636AE8),
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: exchangeViewModel.exchangeMedicines.length,
                              itemBuilder: (context, index) {
                                final medicine = exchangeViewModel.exchangeMedicines[index];
                                return _buildExchangeMedicineCard(medicine);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeMedicineCard(ExchangeMedicineModel medicine) {
    return Container(
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
      child: InkWell(
        onTap: () => _showBuyMedicineModal(medicine),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
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
                      Icons.medication_outlined,
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
                          medicine.medicineName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'From: ${medicine.pharmacyName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${double.parse(medicine.medicinePriceToSell).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 20, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        'Available: ${medicine.medicineQuantityToSell}',
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showBuyMedicineModal(medicine),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.white),
                    label: const Text('Buy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 5,
                      shadowColor: const Color(0xFF4CAF50).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuyMedicineModal(ExchangeMedicineModel medicine) {
    int quantityToBuy = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1A),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Confirm Purchase',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.medication_outlined, color: Color(0xFF636AE8), size: 30),
                    title: Text(medicine.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                    subtitle: Text('From: ${medicine.pharmacyName}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                    trailing: Text('\$${double.parse(medicine.medicinePriceToSell).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF636AE8), size: 30),
                        onPressed: () {
                          if (quantityToBuy > 1) {
                            setModalState(() {
                              quantityToBuy--;
                            });
                          }
                        },
                      ),
                      Text(quantityToBuy.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF636AE8), size: 30),
                        onPressed: () {
                          if (quantityToBuy < int.parse(medicine.medicineQuantityToSell)) {
                            setModalState(() {
                              quantityToBuy++;
                            });
                          } else {
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(
                                content: Text('Cannot buy more than available quantity.'),
                                backgroundColor: Colors.orangeAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: \$${(quantityToBuy * double.parse(medicine.medicinePriceToSell)).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(height: 24),
                  PulsingActionButton(
                    label: 'Confirm Order',
                    onTap: () async {
                      Navigator.pop(modalContext);

                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Sending order...'),
                            backgroundColor: Colors.blueAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          ),
                        );
                      }

                      try {
                        await this.context.read<ExchangeViewModel>().createBuyOrder(
                          medicineId: medicine.id,
                          medicineName: medicine.medicineName,
                          price: medicine.medicinePriceToSell,
                          quantity: quantityToBuy,
                          pharmacySeller: medicine.pharmacyName,
                        );
                      } catch (e) {
                        if (mounted) {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            SnackBar(
                              content: Text('Failed to place order: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(modalContext),
                    child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}