// lib/viewmodels/order_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pharma_net/models/order_model.dart';
import 'package:smart_pharma_net/models/important_notification_model.dart';
import 'package:smart_pharma_net/repositories/order_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/dashboard_viewmodel.dart';

class OrderViewModel extends BaseViewModel {
  final OrderRepository _orderRepository;
  final AuthViewModel _authViewModel;

  List<OrderModel> _incomingOrders = [];
  List<ImportantNotificationModel> _importantNotifications = [];
  int _unreadNotificationCount = 0;
  String? _lastReadNotificationTimestamp;

  // المتغيرات الجديدة اللي هتتحكم في عداد الطلبات
  int _newOrdersBadgeCount = 0;
  String? _lastViewedOrderTimestamp;

  bool _isDisposed = false;
  Timer? _notificationTimer;

  // مفاتيح للحفظ الدائم في ذاكرة الهاتف
  static const String _lastReadTimestampKey = 'lastReadNotificationTimestamp';
  static const String _lastViewedOrderTimestampKey = 'lastViewedOrderTimestamp';

  OrderViewModel(this._orderRepository, this._authViewModel) {
    _loadLastReadTimestamp();
    _loadLastViewedOrderTimestamp(); // تحميل آخر تاريخ عند بدء التشغيل
    _startPollingForNotifications();
  }

  // Getters
  List<OrderModel> get incomingOrders => _incomingOrders;
  List<ImportantNotificationModel> get importantNotifications => _importantNotifications;
  int get pendingOrdersCount => _incomingOrders.where((order) => order.status == 'Pending').length;
  int get importantNotificationsCount => _unreadNotificationCount;
  int get newOrdersCount => _newOrdersBadgeCount; // الـ Getter الجديد للـ Badge

  /// تحميل التاريخ المحفوظ من ذاكرة الهاتف عند بدء التشغيل
  Future<void> _loadLastViewedOrderTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    _lastViewedOrderTimestamp = prefs.getString(_lastViewedOrderTimestampKey);
    print("Loaded last viewed order timestamp: $_lastViewedOrderTimestamp");
    await loadIncomingOrders(); // Load orders right after loading the timestamp
  }

  /// الدالة دي بناديها لما المستخدم يفتح شاشة الطلبات
  /// بتسجل تاريخ أحدث طلب، وبتصفّر العداد
  void markOrdersAsViewed() async {
    if (_incomingOrders.isNotEmpty) {
      // Sort to find the newest order
      _incomingOrders.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      final latestTimestamp = _incomingOrders.first.createdAt;

      if (latestTimestamp != null && latestTimestamp.isNotEmpty) {
        _lastViewedOrderTimestamp = latestTimestamp;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastViewedOrderTimestampKey, _lastViewedOrderTimestamp!);
        print("Orders viewed. New latest timestamp SAVED: $_lastViewedOrderTimestamp");
      }
    }
    // تصفير العداد وإعلام الواجهة بالتغيير
    _newOrdersBadgeCount = 0;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// عند مسح الطلبات (مثلاً عند الخروج من وضع الصيدلية)
  void clearOrders() async {
    _incomingOrders = [];
    _newOrdersBadgeCount = 0;
    _lastViewedOrderTimestamp = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastViewedOrderTimestampKey);

    print("Local orders and saved timestamp cleared.");
    notifyListeners();
  }

  void clearNotifications() {
    _importantNotifications = [];
    _unreadNotificationCount = 0;
    print("Local notifications cleared.");
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startPollingForNotifications() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDisposed) {
        loadImportantNotifications();
        loadIncomingOrders(); // Fetch orders periodically as well
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadLastReadTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    _lastReadNotificationTimestamp = prefs.getString(_lastReadTimestampKey);
  }

  /// الدالة الأساسية لجلب الطلبات وحساب عدد الطلبات الجديدة
  Future<void> loadIncomingOrders() async {
    if (_isDisposed) return;
    setLoading(true);
    setError(null);

    try {
      final pharmacyId = await _authViewModel.getPharmacyId();
      if (pharmacyId == null) {
        _incomingOrders = [];
        _newOrdersBadgeCount = 0;
        if (!_isDisposed) setLoading(false);
        return;
      }

      final newOrderList = await _orderRepository.getIncomingOrdersForSeller(pharmacyId: pharmacyId);

      // هنا منطق حساب عدد الطلبات الجديدة
      if (_lastViewedOrderTimestamp != null) {
        try {
          final lastViewedDate = DateTime.parse(_lastViewedOrderTimestamp!);
          _newOrdersBadgeCount = newOrderList.where((order) {
            try {
              if (order.createdAt == null) return false;
              final orderDate = DateTime.parse(order.createdAt!);
              return orderDate.isAfter(lastViewedDate);
            } catch (e) {
              return false; // Ignore orders with invalid date format
            }
          }).length;
        } catch (e) {
          // If parsing the saved timestamp fails, fall back to showing all as new
          _newOrdersBadgeCount = newOrderList.length;
        }
      } else {
        // لو مفيش تاريخ محفوظ (أول مرة)، يبقى كل الطلبات جديدة
        _newOrdersBadgeCount = newOrderList.length;
      }

      _incomingOrders = newOrderList;

      _incomingOrders.sort((a, b) {
        if (a.status == 'Pending' && b.status != 'Pending') return -1;
        if (a.status != 'Pending' && b.status == 'Pending') return 1;
        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      });

    } catch (e) {
      if (!_isDisposed) setError(e.toString());
    } finally {
      if (!_isDisposed) setLoading(false);
    }
  }

  // The rest of the functions (loadImportantNotifications, markNotificationsAsRead, updateOrderStatus) remain the same
  // ...
  Future<void> loadImportantNotifications() async {
    if (_isDisposed) return;
    setError(null);
    try {
      final pharmacyId = await _authViewModel.getPharmacyId();
      if (pharmacyId == null) {
        _importantNotifications = [];
        _unreadNotificationCount = 0;
        if (!_isDisposed) notifyListeners();
        return;
      }

      final newNotifications = await _orderRepository
          .getImportantNotifications(pharmacyId: pharmacyId);

      if (newNotifications.length != _importantNotifications.length ||
          !newNotifications
              .every((item) => _importantNotifications.contains(item))) {
        _importantNotifications = newNotifications;
        _importantNotifications
            .sort((a, b) => (b.createdAt).compareTo(a.createdAt));
      }

      if (_lastReadNotificationTimestamp != null) {
        try {
          final lastReadDate = DateTime.parse(_lastReadNotificationTimestamp!);
          _unreadNotificationCount = _importantNotifications.where((n) {
            try {
              final notificationDate = DateTime.parse(n.createdAt);
              return notificationDate.isAfter(lastReadDate);
            } catch (e) {
              return false;
            }
          }).length;
        } catch (e) {
          _unreadNotificationCount = _importantNotifications.length;
        }
      } else {
        _unreadNotificationCount = _importantNotifications.length;
      }
    } catch (e) {
      // تجاهل الخطأ بصمت
    } finally {
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> markNotificationsAsRead() async {
    if (_importantNotifications.isNotEmpty) {
      _lastReadNotificationTimestamp = _importantNotifications.first.createdAt;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastReadTimestampKey, _lastReadNotificationTimestamp!);
    }
    _unreadNotificationCount = 0;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
    if (_isDisposed) return;

    final int orderIndex =
    _incomingOrders.indexWhere((order) => order.id.toString() == orderId);
    if (orderIndex == -1) {
      final error = "Order not found locally.";
      setError(error);
      notifyListeners();
      throw Exception(error);
    }
    final OrderModel originalOrder = _incomingOrders[orderIndex];

    _incomingOrders[orderIndex] = originalOrder.copyWith(status: newStatus);
    _incomingOrders.sort((a, b) {
      if (a.status == 'Pending' && b.status != 'Pending') return -1;
      if (a.status != 'Pending' && b.status == 'Pending') return 1;
      return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
    });
    notifyListeners();

    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus);
      Provider.of<DashboardViewModel>(context, listen: false).fetchDashboardStats();
      await loadImportantNotifications();
    } catch (e) {
      if (!_isDisposed) {
        _incomingOrders[orderIndex] = originalOrder;
        _incomingOrders.sort((a, b) {
          if (a.status == 'Pending' && b.status != 'Pending') return -1;
          if (a.status != 'Pending' && b.status == 'Pending') return 1;
          return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
        });
        setError("Failed to update status: ${e.toString()}");
        notifyListeners();
      }
      throw e;
    }
  }
}