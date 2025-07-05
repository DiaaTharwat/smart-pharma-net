import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/order_model.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';
import 'package:intl/intl.dart';
// Import the new common UI elements file
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart'; //


class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key}); // Fixed: Changed 'Key: key' to 'super.key'

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadOrders();
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

  Future<void> _loadOrders() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderViewModel>().loadIncomingOrders();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logoutFromPharmacy() async {
    final authViewModel = context.read<AuthViewModel>();
    try {
      await authViewModel.restoreAdminSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Switched back to Admin mode.'),
            backgroundColor: Color(0xFF636AE8), // Consistent color
            behavior: SnackBarBehavior.fixed, // تم التعديل هنا
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch mode: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed, // تم التعديل هنا
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final correctedUtcString =
      dateString.endsWith('Z') ? dateString : '${dateString}Z';
      final utcDateTime = DateTime.parse(correctedUtcString);
      final localDateTime = utcDateTime.toLocal();
      return DateFormat('MMM d, hh:mm a').format(localDateTime);
    } catch (e) {
      print("Error parsing date in PharmacyOrdersScreen: $e");
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orangeAccent; // Brighter color
      case 'Completed':
        return Colors.greenAccent; // Brighter color
      case 'Cancelled':
        return Colors.redAccent; // Brighter color
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade800.withOpacity(0.2); // Darker background, transparent
      case 'Completed':
        return Colors.green.shade800.withOpacity(0.2);
      case 'Cancelled':
        return Colors.red.shade800.withOpacity(0.2);
      default:
        return Colors.grey.shade800.withOpacity(0.2);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final orderViewModel = context.read<OrderViewModel>();
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updating order status to $newStatus...'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.blueAccent, // Info color
            behavior: SnackBarBehavior.fixed, // تم التعديل هنا
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }

      await orderViewModel.updateOrderStatus(orderId, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $newStatus successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed, // تم التعديل هنا
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
        await _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.fixed, // تم التعديل هنا
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend body behind custom app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        toolbarHeight: 0, // Hide default AppBar to use custom one
      ),
      body: InteractiveParticleBackground( // Using InteractiveParticleBackground
        child: Column(
          children: [
            // Custom AppBar equivalent (Header)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28), // Consistent icon
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white, size: 28), // Consistent icon
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
                            'My Pharmacy Orders',
                            style: TextStyle(
                              fontSize: 26, // Larger font
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 10.0, color: Color(0xFF636AE8))], // Glowing effect
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 28), // Consistent icon
                          onPressed: _loadOrders,
                        ),
                        if (authViewModel.isAdmin && authViewModel.isPharmacy)
                          IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 28), // Consistent icon
                            tooltip: 'Logout from Pharmacy',
                            onPressed: _logoutFromPharmacy,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20), // Increased spacing
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15), // Increased padding
                          decoration: BoxDecoration(
                            color: const Color(0xFF636AE8).withOpacity(0.2), // Subtle background
                            borderRadius: BorderRadius.circular(15), // More rounded
                            border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)), // Border
                          ),
                          child: Consumer<OrderViewModel>(
                            builder: (context, viewModel, _) {
                              final pendingCount = viewModel.pendingOrdersCount;
                              return Text(
                                pendingCount > 0
                                    ? 'You have $pendingCount new pending orders!'
                                    : 'No new pending orders.',
                                style: const TextStyle(
                                  fontSize: 17, // Larger font
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Consumer<OrderViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF636AE8)),
                      ),
                    );
                  }
                  if (viewModel.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0), // Increased padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60, // Larger icon
                              color: Colors.red.shade400, // Lighter red
                            ),
                            const SizedBox(height: 20), // Increased spacing
                            Text(
                              'Error: ${viewModel.errorMessage}',
                              style:  TextStyle(color: Colors.red.shade200, fontSize: 17), // Lighter red text, larger font
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20), // Increased spacing
                            PulsingActionButton( // Reusing PulsingActionButton
                              label: 'Retry',
                              onTap: _loadOrders,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (viewModel.incomingOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80, // Larger icon
                            color: Colors.grey.shade600, // Darker grey
                          ),
                          const SizedBox(height: 20), // Increased spacing
                          Text(
                            'No orders received yet.',
                            style: TextStyle(
                              fontSize: 20, // Larger font
                              color: Colors.white.withOpacity(0.7), // Lighter text
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20), // Increased spacing
                          PulsingActionButton( // Reusing PulsingActionButton
                            label: 'Refresh Orders',
                            onTap: _loadOrders,
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _loadOrders,
                    color: const Color(0xFF636AE8),
                    backgroundColor: Colors.white.withOpacity(0.8), // Refresh indicator background
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20), // More padding
                      itemCount: viewModel.incomingOrders.length,
                      itemBuilder: (context, index) {
                        final order = viewModel.incomingOrders[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Define dynamic properties outside BoxDecoration to avoid const issues
    final Color borderColor = _getStatusBackgroundColor(order.status).withOpacity(0.5);
    final Color shadowColor = _getStatusBackgroundColor(order.status).withOpacity(0.15);

    return Container( // Changed from Card to Container for consistent styling
      margin: const EdgeInsets.only(bottom: 20), // Increased margin
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A), // Darker background
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(color: borderColor, width: 2), // Use the non-constant border
        boxShadow: [
          BoxShadow(
            color: shadowColor, // Use the non-constant boxShadow
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.medicineName,
                    style: const TextStyle(
                      fontSize: 20, // Larger font
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased padding
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order.status).withOpacity(0.4), // Darker background for status label
                    borderRadius: BorderRadius.circular(15), // More rounded
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 15, // Larger font
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status), // Status color
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Increased spacing
            Text(
              'Requested by: ${order.pharmacyBuyer}',
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)), // Larger, lighter text
            ),
            const SizedBox(height: 6), // Increased spacing
            Text(
              'Quantity: ${order.quantity} | Price: \$${double.parse(order.price).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)), // Larger, lighter text
            ),
            const SizedBox(height: 6), // Increased spacing
            Text(
              'Total: \$${(order.quantity * double.parse(order.price)).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18, // Larger font
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50)), // Green for total
            ),
            const SizedBox(height: 12), // Increased spacing
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Order Date: ${_formatDate(order.createdAt)}',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)), // Lighter text
              ),
            ),
            if (order.status == 'Pending') ...[
              Divider(height: 30, color: Colors.white.withOpacity(0.2)), // White, subtle divider
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon( // Styled ElevatedButton for Accept
                      onPressed: () => _updateOrderStatus(order.id, 'Completed'),
                      icon: const Icon(Icons.check, color: Colors.white, size: 24), // Larger, white icon
                      label: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), // White text, larger
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Green for accept
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.green.withOpacity(0.6), // Glowing shadow
                      ),
                    ),
                  ),
                  const SizedBox(width: 15), // Increased spacing
                  Expanded(
                    child: ElevatedButton.icon( // Styled ElevatedButton for Reject
                      onPressed: () => _updateOrderStatus(order.id, 'Cancelled'),
                      icon: const Icon(Icons.cancel, color: Colors.white, size: 24), // Larger, white icon
                      label: const Text('Reject', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), // White text, larger
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red for reject
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.red.withOpacity(0.6), // Glowing shadow
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (order.status != 'Pending') ...[
              const SizedBox(height: 16), // Increased spacing
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Order ${order.status}',
                  style: TextStyle(
                    fontSize: 18, // Larger font
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status), // Status color
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}