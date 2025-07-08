class DashboardStats {
  final int totalPharmacies;
  final int totalMedicines;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int totalSells;
  final int totalBuys;

  DashboardStats({
    this.totalPharmacies = 0,
    this.totalMedicines = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.totalSells = 0,
    this.totalBuys = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalPharmacies: json['total_pharmacies'] ?? 0,
      totalMedicines: json['total_medicines'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      totalSells: json['total_sells'] ?? 0,
      totalBuys: json['total_buys'] ?? 0,
    );
  }
}