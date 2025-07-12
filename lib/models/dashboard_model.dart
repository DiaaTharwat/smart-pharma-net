// lib/models/dashboard_model.dart

class DashboardStats {
  final int totalPharmacies;
  final int totalSells;
  final int totalBuys;
  final int totalMedicines;
  // ✨ الحقول الجديدة لإحصائيات الطلبات
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;

  final bool hasMedicineStats;
  final bool hasOrderStats;

  DashboardStats({
    required this.totalPharmacies,
    required this.totalSells,
    required this.totalBuys,
    required this.totalMedicines,
    // ✨ تمت إضافتها للـ constructor
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    this.hasMedicineStats = false,
    this.hasOrderStats = false,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('owner') && json.containsKey('pharmacies')) {
      final List<dynamic> pharmaciesList = json['pharmacies'] ?? [];

      int aggregatedSells = 0;
      int aggregatedBuys = 0;

      for (var pharmacyJson in pharmaciesList) {
        aggregatedSells += (pharmacyJson['number_sells'] as int? ?? 0);
        aggregatedBuys += (pharmacyJson['number_buys'] as int? ?? 0);
      }

      return DashboardStats(
        totalPharmacies: json['owner']['numberOfpharmacies'] as int? ?? 0,
        totalSells: aggregatedSells,
        totalBuys: aggregatedBuys,
        totalMedicines: 0,
        pendingOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        hasMedicineStats: false,
        hasOrderStats: false,
      );
    } else {
      final orderStats = json['order_stats'] ?? {};
      return DashboardStats(
        totalPharmacies: 0,
        totalSells: json['total_sells'] ?? 0,
        totalBuys: json['total_buys'] ?? 0,
        totalMedicines: json['total_medicines'] ?? 0,
        pendingOrders: orderStats['pending'] ?? 0,
        completedOrders: orderStats['completed'] ?? 0,
        cancelledOrders: orderStats['cancelled'] ?? 0,
        hasMedicineStats: json.containsKey('total_medicines'),
        hasOrderStats: json.containsKey('order_stats'),
      );
    }
  }
}