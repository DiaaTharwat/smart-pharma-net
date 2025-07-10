// lib/view/Widgets/notification_icon.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_orders_screen.dart';
import 'package:smart_pharma_net/view/Widgets/important_notifications_dialog.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';

// =================== START: MODIFICATION 1 ===================
// The widget has been converted to a StatelessWidget for better performance and simplicity,
// as it no longer manages its own state. It purely relies on the providers.
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({Key? key}) : super(key: key);

  // The logic for showing the popup menu remains, but is now a method of the StatelessWidget.
  void _showNotificationMenu(BuildContext context) {
    // We get the OrderViewModel here because we need it inside the dialog.
    final orderViewModel = context.read<OrderViewModel>();
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(-200, 45), ancestor: overlay), // Adjusted position
        button.localToGlobal(button.size.bottomRight(const Offset(50, 45)), // Adjusted position
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1), // Slightly visible barrier
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.top,
              left: position.left,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280, // Increased width for better text display
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2D), // Darker background
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  // We use a Consumer here to ensure the counts in the dialog are always up-to-date
                  // even if the dialog is open while data changes.
                  child: Consumer<OrderViewModel>(
                    builder: (context, orderVm, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            context,
                            // Displaying pending orders which are a subset of incoming orders
                            title: 'Pending Orders (${orderVm.pendingOrdersCount})',
                            icon: Icons.inbox,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const PharmacyOrdersScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1, color: Colors.white24),
                          _buildMenuItem(
                            context,
                            title: 'Important Msgs (${orderVm.importantNotificationsCount})',
                            icon: Icons.notification_important,
                            onTap: () {
                              Navigator.pop(context);
                              // Show the dialog for important notifications
                              showDialog(
                                context: context,
                                builder: (context) =>
                                const ImportantNotificationsDialog(),
                              );
                              // Mark notifications as read after opening them
                              orderVm.markNotificationsAsRead();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build menu items, with improved styling.
  Widget _buildMenuItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF636AE8)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      onTap: onTap,
      hoverColor: const Color(0xFF636AE8).withOpacity(0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use Consumer2 to listen to changes in both AuthViewModel and OrderViewModel.
    return Consumer2<AuthViewModel, OrderViewModel>(
      builder: (context, authViewModel, orderViewModel, _) {
        // The condition is simplified: show the icon if the user can act as a pharmacy
        // (either a real pharmacy or an admin impersonating one).
        if (authViewModel.canActAsPharmacy) {
          // The total count now correctly includes pending orders and unread important notifications.
          final totalCount = orderViewModel.pendingOrdersCount +
              orderViewModel.importantNotificationsCount;

          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                tooltip: 'Notifications',
                onPressed: () => _showNotificationMenu(context),
              ),
              // The badge is only shown if there's at least one notification/order.
              if (totalCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5)),
                    constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          // If the user cannot act as a pharmacy, show nothing.
          return const SizedBox.shrink();
        }
      },
    );
  }
}
// =================== END: MODIFICATION ===================