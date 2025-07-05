// lib/view/Widgets/notification_icon.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Screens/pharmacy_orders_screen.dart';
import 'package:smart_pharma_net/view/Widgets/important_notifications_dialog.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({Key? key}) : super(key: key);

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadOrders();
    });
  }

  // --- تم تعديل هذه الدالة بالكامل ---
  Future<void> _checkAndLoadOrders() async {
    if (!mounted) return;

    final authViewModel = context.read<AuthViewModel>();
    final orderViewModel = context.read<OrderViewModel>();

    // نتحقق إذا كان يمكن للمستخدم التصرف كصيدلية
    if (authViewModel.canActAsPharmacy) {
      // نجلب الـ ID الخاص بالصيدلية الفعالة (سواء حقيقية أو متقمصة)
      final pharmacyId = await authViewModel.getPharmacyId();
      if (pharmacyId != null && mounted) {
        // نستخدم الـ ID لتحميل الطلبات والإشعارات الصحيحة
        orderViewModel.loadIncomingOrders();
        orderViewModel.loadImportantNotifications();
      }
    }
  }

  void _showNotificationMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(const Offset(-150, 40), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(const Offset(0, 40)),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.top,
              left: position.left,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Consumer<OrderViewModel>(
                    builder: (context, orderViewModel, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMenuItem(
                            context,
                            title: 'Orders (${orderViewModel.pendingOrdersCount})',
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
                          const Divider(height: 1),
                          _buildMenuItem(
                            context,
                            title: 'Important (${orderViewModel.importantNotificationsCount})',
                            icon: Icons.notification_important,
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) =>
                                const ImportantNotificationsDialog(),
                              );
                              orderViewModel.markNotificationsAsRead();
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

  Widget _buildMenuItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthViewModel, OrderViewModel>(
      builder: (context, authViewModel, orderViewModel, _) {
        // --- تم تعديل الشرط المنطقي هنا ---
        // سيتم إظهار الأيقونة إذا كان المستخدم صيدلية حقيقية أو يتقمص شخصية صيدلية
        if (authViewModel.canActAsPharmacy) {
          final totalCount = orderViewModel.pendingOrdersCount + orderViewModel.importantNotificationsCount;

          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => _showNotificationMenu(context),
              ),
              if (totalCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5)
                    ),
                    constraints:
                    const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}