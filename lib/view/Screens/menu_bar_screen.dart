// lib/view/Screens/menu_bar_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/view/Screens/available_pharmacy_screen.dart';
import 'package:smart_pharma_net/view/Screens/dashboard_screen.dart';
import 'package:smart_pharma_net/view/Screens/exchange_screen.dart';
import 'package:smart_pharma_net/view/Screens/settings_screen.dart';
import 'package:smart_pharma_net/view/Screens/welcome_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_orders_screen.dart';
import 'package:smart_pharma_net/view/Screens/pricing_screen.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Widgets/notification_icon.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';

class MenuBarScreen extends StatefulWidget {
  const MenuBarScreen({super.key});

  @override
  State<MenuBarScreen> createState() => _MenuBarScreenState();
}

class _MenuBarScreenState extends State<MenuBarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.isAdmin) {
        context.read<PharmacyViewModel>().loadPharmacies(
            searchQuery: '', authViewModel: authViewModel);
      }
      context.read<DashboardViewModel>().fetchDashboardStats();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    }
  }

  void _showSelectPharmacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: const Color(0xFF636AE8).withOpacity(0.5)),
        ),
        title: const Text('Pharmacy Not Selected', style: TextStyle(color: Colors.white)),
        content: const Text(
            'Please select a pharmacy from the dropdown menu first to access this feature.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF636AE8))),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isDisabled = false,
    Color? iconColor,
  }) {
    final color = isDisabled ? Colors.grey.shade600 : Colors.white;
    final finalIconColor = iconColor ?? (isDisabled ? Colors.grey.shade600 : const Color(0xFF636AE8));

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: finalIconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: finalIconColor, size: 28),
            ),
            title: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: color),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 20, color: color.withOpacity(0.7)),
            onTap: isDisabled ? null : onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacySelector(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final pharmacyVm = context.watch<PharmacyViewModel>();
    final dashboardVm = context.read<DashboardViewModel>();

    if (pharmacyVm.isLoading) {
      return const Center(child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF636AE8)));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF636AE8).withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: authVm.isImpersonating ? authVm.activePharmacyId.toString() : 'owner_mode',
          isExpanded: true,
          dropdownColor: const Color(0xFF0D0D1A),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
          hint: const Text("Select Pharmacy", style: TextStyle(color: Colors.white70)),
          items: [
            const DropdownMenuItem(
              value: 'owner_mode',
              child: Text("Owner Mode", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
            ...pharmacyVm.pharmacies.map<DropdownMenuItem<String>>((PharmacyModel pharmacy) {
              return DropdownMenuItem<String>(
                value: pharmacy.id.toString(),
                child: Text(pharmacy.name, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            final orderVm = context.read<OrderViewModel>();

            if (newValue == 'owner_mode') {
              authVm.stopImpersonation();
              dashboardVm.selectPharmacy(null);
            } else if (newValue != null) {
              final selectedPharmacy = pharmacyVm.pharmacies.firstWhere((p) => p.id.toString() == newValue);
              authVm.impersonatePharmacy(selectedPharmacy);

              // =================== الجزء الذي تم تصحيحه ===================
              // نقوم بتحويل النص (newValue) إلى رقم قبل إرساله
              final pharmacyId = int.tryParse(newValue);
              dashboardVm.selectPharmacy(pharmacyId);
              // ==========================================================
            }

            orderVm.loadImportantNotifications();
            orderVm.loadIncomingOrders();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    String welcomeText;
    String accountTypeText;

    if (authViewModel.isImpersonating) {
      welcomeText = 'Welcome, ${authViewModel.activePharmacyName ?? 'Pharmacy'}';
      accountTypeText = 'Owner (Impersonating)';
    } else if (authViewModel.isAdmin) {
      final email = authViewModel.ownerEmail;
      welcomeText = 'Welcome, ${(email != null && email.isNotEmpty) ? email.split('@')[0] : 'Owner'}';
      accountTypeText = 'Owner Account';
    } else if (authViewModel.isPharmacy) {
      welcomeText = 'Welcome, ${authViewModel.activePharmacyName ?? 'Pharmacy'}';
      accountTypeText = 'Pharmacy Account';
    } else {
      welcomeText = 'Welcome, User';
      accountTypeText = 'User Account';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 0),
      body: InteractiveParticleBackground(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                          onPressed: (){ Navigator.of(context).pop(); },
                        ),
                        const Spacer(),

                        if(authViewModel.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                            onPressed: () {
                              _navigateTo(context, const SettingsScreen());
                            },
                            tooltip: 'Settings',
                          ),

                        if (authViewModel.canActAsPharmacy)
                          const NotificationIcon(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: const Color(0xFF636AE8).withOpacity(0.5),
                            child: Icon(
                              authViewModel.isAdmin ? Icons.admin_panel_settings : Icons.storefront,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  welcomeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  accountTypeText,
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (Route<dynamic> route) => false,
                      );
                    },
                  ),

                  if (authViewModel.isAdmin || authViewModel.isPharmacy) ...[
                    _buildMenuItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      onTap: () => _navigateTo(context, const DashboardScreen()),
                    ),
                  ],

                  if (authViewModel.isAdmin) ...[
                    _buildPharmacySelector(context),
                    _buildMenuItem(
                      icon: Icons.store_mall_directory,
                      title: 'Manage Pharmacies',
                      onTap: () => _navigateTo(context, const AvailablePharmaciesScreen()),
                    ),
                    Divider(color: Colors.white.withOpacity(0.2), height: 20),
                    _buildMenuItem(
                      icon: Icons.swap_horiz,
                      title: 'Exchange',
                      isDisabled: !authViewModel.isImpersonating,
                      onTap: authViewModel.isImpersonating
                          ? () => _navigateTo(context, const ExchangeScreen())
                          : _showSelectPharmacyDialog,
                    ),
                    _buildMenuItem(
                      icon: Icons.star,
                      title: 'Subscriptions',
                      isDisabled: !authViewModel.isImpersonating,
                      onTap: authViewModel.isImpersonating
                          ? () => _navigateTo(context, const PricingScreen())
                          : _showSelectPharmacyDialog,
                    ),
                    if (authViewModel.isImpersonating)
                      _buildMenuItem(
                        icon: Icons.shopping_cart,
                        title: 'Incoming Orders',
                        onTap: () => _navigateTo(context, const PharmacyOrdersScreen()),
                      ),
                  ] else if (authViewModel.isPharmacy) ...[
                    _buildMenuItem(
                      icon: Icons.store,
                      title: 'My Pharmacy Details',
                      onTap: () => _navigateTo(context, const AvailablePharmaciesScreen()),
                    ),
                    _buildMenuItem(
                      icon: Icons.swap_horiz,
                      title: 'Exchange',
                      onTap: () => _navigateTo(context, const ExchangeScreen()),
                    ),
                    _buildMenuItem(
                      icon: Icons.star,
                      title: 'Subscriptions',
                      onTap: () => _navigateTo(context, const PricingScreen()),
                    ),
                    _buildMenuItem(
                      icon: Icons.shopping_cart,
                      title: 'My Incoming Orders',
                      onTap: () => _navigateTo(context, const PharmacyOrdersScreen()),
                    ),
                  ],

                  Divider(color: Colors.white.withOpacity(0.2), height: 40),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () => _handleLogout(context),
                    iconColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}