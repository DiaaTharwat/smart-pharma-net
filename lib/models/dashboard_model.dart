import 'package:flutter/foundation.dart';

class DashboardStats {
  final int totalPharmacies;
  final int? totalMedicines;
  final int? pendingOrders;
  final int? completedOrders;
  final int? cancelledOrders;
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

  // دالة مساعدة لتحويل أي قيمة إلى عدد صحيح بأمان
  static int _parseSafeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Getters للتحقق من وجود البيانات قبل عرضها في الواجهة
  bool get hasOrderStats =>
      pendingOrders != null && completedOrders != null && cancelledOrders != null && (pendingOrders! + completedOrders! + cancelledOrders! > 0);
  bool get hasMedicineStats => totalMedicines != null;

  /// ✨ Factory Constructor الجديد والمُحسَّن ✨
  /// هذا الـ Constructor أكثر ذكاءً ومرونة.
  /// سيقوم بقراءة أي بيانات متاحة في الـ JSON القادم من السيرفر.
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('[DashboardStats] Parsing JSON: $json');
    }

    int calculatedSells = 0;
    int calculatedBuys = 0;

    // أولاً، تحقق إذا كانت هذه بيانات المالك العام (تحتوي على قائمة صيدليات)
    if (json.containsKey('pharmacies') && json['pharmacies'] is List) {
      final List pharmacies = json['pharmacies'];
      for (var pharmacyData in pharmacies) {
        calculatedSells += _parseSafeInt(pharmacyData['number_sells']);
        calculatedBuys += _parseSafeInt(pharmacyData['number_buys']);
      }
    } else {
      // إذا لم تكن بيانات المالك، فهي بيانات صيدلية واحدة.
      // اقرأ المبيعات والمشتريات مباشرة.
      calculatedSells = _parseSafeInt(json['total_sells'] ?? json['number_sells']);
      calculatedBuys = _parseSafeInt(json['total_buys'] ?? json['number_buys']);
    }

    // الآن، قم ببناء الكائن مع قراءة كل الحقول المتاحة
    return DashboardStats(
      // حقل خاص بالمالك فقط
      totalPharmacies: _parseSafeInt(json['owner']?['numberOfpharmacies']),

      // حقول خاصة بالصيدلية (ستكون null إذا لم تكن موجودة)
      totalMedicines: json.containsKey('total_medicines')
          ? _parseSafeInt(json['total_medicines'])
          : null,
      pendingOrders: json.containsKey('pending_orders')
          ? _parseSafeInt(json['pending_orders'])
          : null,
      completedOrders: json.containsKey('completed_orders')
          ? _parseSafeInt(json['completed_orders'])
          : null,
      cancelledOrders: json.containsKey('cancelled_orders')
          ? _parseSafeInt(json['cancelled_orders'])
          : null,

      // حقول مشتركة
      totalSells: calculatedSells,
      totalBuys: calculatedBuys,
    );
  }

  /// هذا الـ factory مخصص فقط لحالة تقمص الأدمن لصيدلية
  /// لأنه يعتمد على بيانات محدودة من قائمة الصيدليات
  factory DashboardStats.fromSinglePharmacyImpersonation(
      Map<String, dynamic> pharmacyJson) {
    return DashboardStats(
      totalSells: _parseSafeInt(pharmacyJson['number_sells']),
      totalBuys: _parseSafeInt(pharmacyJson['number_buys']),
      // في هذه الحالة، لا يمكننا جلب تفاصيل الأدوية والطلبات من قائمة الأدمن العامة
      // لذا ستبقى null، وهذا سلوك صحيح.
    );
  }
}
