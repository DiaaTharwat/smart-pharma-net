import 'dart:async';

import 'package:flutter/material.dart';

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

  final DashboardViewModel _dashboardViewModel; // الاعتمادية الجديدة



  List<OrderModel> _incomingOrders = [];

  List<ImportantNotificationModel> _importantNotifications = [];

  int _unreadNotificationCount = 0;

  String? _lastReadNotificationTimestamp;



  bool _isDisposed = false;

  Timer? _notificationTimer;



  static const String _lastReadTimestampKey = 'lastReadNotificationTimestamp';



// تحديث الـ Constructor لاستقبال الاعتمادية الجديدة

  OrderViewModel(

      this._orderRepository, this._authViewModel, this._dashboardViewModel) {

    _loadLastReadTimestamp();

    _startPollingForNotifications();

  }



  List<OrderModel> get incomingOrders => _incomingOrders;

  List<ImportantNotificationModel> get importantNotifications =>

      _importantNotifications;



  int get pendingOrdersCount =>

      _incomingOrders.where((order) => order.status == 'Pending').length;

  int get importantNotificationsCount => _unreadNotificationCount;



  void _startPollingForNotifications() {

    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {

      print("Polling for new notifications...");

      if (!_isDisposed) {

        loadImportantNotifications();

      } else {

        timer.cancel();

      }

    });

  }



  @override

  void dispose() {

    _isDisposed = true;

    _notificationTimer?.cancel();

    super.dispose();

  }



  Future<void> _loadLastReadTimestamp() async {

    final prefs = await SharedPreferences.getInstance();

    _lastReadNotificationTimestamp = prefs.getString(_lastReadTimestampKey);

  }



  Future<void> loadIncomingOrders() async {

    if (_isDisposed) return;

    setLoading(true);

    setError(null);



    try {

      final pharmacyId = await _authViewModel.getPharmacyId();

      if (pharmacyId == null) {

        _incomingOrders = [];

        if (!_isDisposed) setLoading(false);

        return;

      }



      _incomingOrders =

      await _orderRepository.getIncomingOrdersForSeller(pharmacyId: pharmacyId);



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



  Future<void> loadImportantNotifications() async {

    if (_isDisposed) return;

    setLoading(true);

    setError(null);

    try {

      final pharmacyId = await _authViewModel.getPharmacyId();

      if (pharmacyId == null) {

        _importantNotifications = [];

        _unreadNotificationCount = 0;

        if (!_isDisposed) setLoading(false);

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

      if (!_isDisposed) setError(e.toString());

    } finally {

      if (!_isDisposed) setLoading(false);

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



  Future<bool> updateOrderStatus(String orderId, String newStatus) async {

    setError(null);

    final int orderIndex =

    _incomingOrders.indexWhere((order) => order.id.toString() == orderId);

    if (orderIndex == -1) {

      setError("Order not found locally.");

      return false;

    }

    final OrderModel originalOrder = _incomingOrders[orderIndex];



    try {

      await _orderRepository.updateOrderStatus(orderId, newStatus);

      _incomingOrders[orderIndex] = originalOrder.copyWith(status: newStatus);

      _incomingOrders.sort((a, b) {

        if (a.status == 'Pending' && b.status != 'Pending') return -1;

        if (a.status != 'Pending' && b.status == 'Pending') return 1;

        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');

      });



// ✨ جوهر الإصلاح: إعلام الـ Dashboard بالتحديث ✨

      await _dashboardViewModel.fetchDashboardStats();



      await loadImportantNotifications();



      if (!_isDisposed) notifyListeners();

      return true;

    } catch (e) {

      _incomingOrders[orderIndex] = originalOrder;

      if (!_isDisposed) {

        setError("Failed to update status: ${e.toString()}");

        notifyListeners();

      }

      return false;

    }

  }

}