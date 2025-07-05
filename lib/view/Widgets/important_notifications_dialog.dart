// lib/view/Widgets/important_notifications_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/viewmodels/order_viewmodel.dart';
import 'package:intl/intl.dart';

class ImportantNotificationsDialog extends StatefulWidget {
  const ImportantNotificationsDialog({Key? key}) : super(key: key);

  @override
  State<ImportantNotificationsDialog> createState() =>
      _ImportantNotificationsDialogState();
}

class _ImportantNotificationsDialogState
    extends State<ImportantNotificationsDialog> {
  @override
  void initState() {
    super.initState();
    // البيانات تم تحميلها بالفعل قبل فتح النافذة
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final correctedUtcString = dateString.endsWith('Z') ? dateString : '${dateString}Z';
      final utcDateTime = DateTime.parse(correctedUtcString);
      final localDateTime = utcDateTime.toLocal();
      return DateFormat('MMM d, hh:mm a').format(localDateTime);
    } catch (e) {
      print("Error parsing date: $e");
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.all(0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      title: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Important",
                style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Fixed height for the content area
        child: Consumer<OrderViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              return Center(child: Text('Error: ${viewModel.errorMessage}'));
            }

            if (viewModel.importantNotifications.isEmpty) {
              return const Center(
                child: Text("No important notifications yet."),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: viewModel.importantNotifications.length,
              itemBuilder: (context, index) {
                final notification = viewModel.importantNotifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(Icons.notifications_active,
                        color: Theme.of(context).primaryColor),
                    title: Text(
                      // ** تم إرجاع الرسالة إلى النص الأصلي من الباك اند **
                      notification.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Order #${notification.orderId} • ${_formatDate(notification.createdAt)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}