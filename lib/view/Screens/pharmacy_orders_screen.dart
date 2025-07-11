import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/order_model.dart';
import 'package:smart_pharma_net/view/Screens/home_screen.dart';
import 'package:smart_pharma_net/view/Screens/menu_bar_screen.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

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
            backgroundColor: Color(0xFF636AE8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
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
        return Colors.orangeAccent;
      case 'Completed':
        return Colors.greenAccent;
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade800.withOpacity(0.2);
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Updating order status to $newStatus...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    try {
      final success =
      await orderViewModel.updateOrderStatus(context, orderId, newStatus);

      scaffoldMessenger.hideCurrentSnackBar();

      if (success && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Order status updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
        // No need to call _loadOrders() again.
        // The ViewModel's notifyListeners() handles the UI update.
      } else if (!success && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
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
    final authViewModel = context.watch<AuthViewModel>();
    return Scaffold(
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
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu,
                              color: Colors.white, size: 28),
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
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    blurRadius: 10.0, color: Color(0xFF636AE8))
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 28),
                          onPressed: _loadOrders,
                        ),
                        if (authViewModel.isAdmin &&
                            authViewModel.isImpersonating)
                          IconButton(
                            icon: const Icon(Icons.exit_to_app,
                                color: Colors.white, size: 28),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF636AE8).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: const Color(0xFF636AE8).withOpacity(0.3)),
                          ),
                          child: Consumer<OrderViewModel>(
                            builder: (context, viewModel, _) {
                              final pendingCount = viewModel.pendingOrdersCount;
                              return Text(
                                pendingCount > 0
                                    ? 'You have $pendingCount new pending orders!'
                                    : 'No new pending orders.',
                                style: const TextStyle(
                                  fontSize: 17,
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
                              'Error: ${viewModel.errorMessage}',
                              style: TextStyle(
                                  color: Colors.red.shade200, fontSize: 17),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            PulsingActionButton(
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
                            size: 80,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No orders received yet.',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          PulsingActionButton(
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
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
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
    final Color borderColor =
    _getStatusBackgroundColor(order.status).withOpacity(0.5);
    final Color shadowColor =
    _getStatusBackgroundColor(order.status).withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(order.status)
                        .withOpacity(0.4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requested by: ${order.pharmacyBuyer}',
              style:
              TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 6),
            Text(
              'Quantity: ${order.quantity} | Price: \$${double.parse(order.price).toStringAsFixed(2)}',
              style:
              TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 6),
            Text(
              'Total: \$${(order.quantity * double.parse(order.price)).toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Order Date: ${_formatDate(order.createdAt)}',
                style:
                TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
              ),
            ),
            if (order.status == 'Pending') ...[
              Divider(height: 30, color: Colors.white.withOpacity(0.2)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateOrderStatus(order.id.toString(), 'Completed'),
                      icon: const Icon(Icons.check,
                          color: Colors.white, size: 24),
                      label: const Text('Accept',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.green.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateOrderStatus(order.id.toString(), 'Cancelled'),
                      icon: const Icon(Icons.cancel,
                          color: Colors.white, size: 24),
                      label: const Text('Reject',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: Colors.red.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (order.status != 'Pending') ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Order ${order.status}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(order.status),
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
