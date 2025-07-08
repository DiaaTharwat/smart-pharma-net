// lib/models/dashboard_model.dart

import 'package:flutter/foundation.dart';

class DashboardStats {
  final int totalPharmacies;
  final int? totalMedicines; // Can be null
  final int? pendingOrders;   // Can be null
  final int? completedOrders; // Can be null
  final int? cancelledOrders; // Can be null
  final int totalSells;
  final int totalBuys;

  DashboardStats({
    this.totalPharmacies = 0,
    this.totalMedicines,
    this.pendingOrders,
    this.completedOrders,
    this.cancelledOrders,
    this.totalSells = 0,
    this.totalBuys = 0,
  });

  static int _parseSafeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // هل هذه الإحصائية لديها بيانات للطلبات؟
  bool get hasOrderStats => pendingOrders != null && completedOrders != null && cancelledOrders != null;
  // هل هذه الإحصائية لديها بيانات للأدوية؟
  bool get hasMedicineStats => totalMedicines != null;


  factory DashboardStats.fromJson(Map<String, dynamic> json, {bool isFromSinglePharmacy = false}) {
    if (kDebugMode) {
      print('[DashboardStats] Parsing JSON. Is single pharmacy: $isFromSinglePharmacy. Data: $json');
    }

    // A. This is the main admin dashboard response
    if (json.containsKey('owner') && json.containsKey('pharmacies')) {
      final List pharmacies = json['pharmacies'] as List? ?? [];
      int totalSells = 0;
      int totalBuys = 0;

      for (var pharmacyData in pharmacies) {
        totalSells += _parseSafeInt(pharmacyData['number_sells']);
        totalBuys += _parseSafeInt(pharmacyData['number_buys']);
      }

      return DashboardStats(
        totalPharmacies: _parseSafeInt(json['owner']?['numberOfpharmacies']),
        totalSells: totalSells,
        totalBuys: totalBuys,
        // The other values are NOT available in this response, so we leave them null.
      );
    }
    // B. This is the data for a single pharmacy that is logged in
    else if (isFromSinglePharmacy) {
      return DashboardStats(
        totalMedicines: _parseSafeInt(json['total_medicines']),
        pendingOrders: _parseSafeInt(json['pending_orders']),
        completedOrders: _parseSafeInt(json['completed_orders']),
        cancelledOrders: _parseSafeInt(json['cancelled_orders']),
        totalSells: _parseSafeInt(json['total_sells']),
        totalBuys: _parseSafeInt(json['total_buys']),
      );
    }
    // C. Fallback for unexpected data
    return DashboardStats();
  }

  factory DashboardStats.fromSinglePharmacyImpersonation(Map<String, dynamic> pharmacyJson) {
    return DashboardStats(
      totalSells: _parseSafeInt(pharmacyJson['number_sells']),
      totalBuys: _parseSafeInt(pharmacyJson['number_buys']),
      // The other stats are not available in the admin's list view for impersonation
    );
  }
}