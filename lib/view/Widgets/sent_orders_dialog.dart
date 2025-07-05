// lib/view/Widgets/sent_orders_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/order_model.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';
import 'package:intl/intl.dart';

class SentOrdersDialog extends StatefulWidget {
  const SentOrdersDialog({Key? key}) : super(key: key);

  @override
  State<SentOrdersDialog> createState() => _SentOrdersDialogState();
}

class _SentOrdersDialogState extends State<SentOrdersDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderViewModel>().loadMySentOrders();
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, hh:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("My Sent Orders Status"),
      content: SizedBox(
        width: double.maxFinite,
        child: Consumer<OrderViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Text('Error: ${viewModel.errorMessage}'));
            }

            if (viewModel.mySentOrders.isEmpty) {
              return const Center(
                child: Text("You haven't sent any orders yet."),
              );
            }

            // Filter for orders that are not pending
            final nonPendingOrders = viewModel.mySentOrders
                .where((order) => order.status != 'Pending')
                .toList();

            if (nonPendingOrders.isEmpty) {
              return const Center(
                child: Text("No updates on your sent orders yet."),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: nonPendingOrders.length,
              itemBuilder: (context, index) {
                final order = nonPendingOrders[index];
                final statusColor = order.status == 'Completed'
                    ? Colors.green.shade700
                    : Colors.red.shade700;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          const TextSpan(text: 'Your order for '),
                          TextSpan(
                              text: order.medicineName,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' has been '),
                          TextSpan(
                            text: order.status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text(
                      'Order #${order.id} • ${_formatDate(order.updatedAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        ),
      ],
    );
  }
}