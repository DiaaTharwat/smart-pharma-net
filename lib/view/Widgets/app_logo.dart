// lib/view/Widgets/app_logo.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

// Widget اللوجو الجديد اللي معمول بالكود
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LogoPainter(),
      ),
    );
  }
}

// الـ Painter النهائي الذي يرسم اللوجو بدقة هندسية
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    final legThickness = size.width * 0.3; // سُمك موحد وثابت لكل السيقان

    // تعريف الألوان والفرشاة بحدود دائرية
    final bluePaint = Paint()
      ..color = const Color(0xFF636AE8) // اللون الأساسي الأزرق
      ..style = PaintingStyle.stroke // استخدام وضع الخط
      ..strokeWidth = legThickness // تحديد سمك الخط
      ..strokeCap = StrokeCap.round // نهايات دائرية
      ..strokeJoin = StrokeJoin.round; // زوايا دائرية

    final redPaint = Paint()
      ..color = const Color(0xFFE94560) // لون أحمر/وردي مكمل وجذاب
      ..style = PaintingStyle.stroke
      ..strokeWidth = legThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = legThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); // ظل ضبابي

    // --- رسم السيقان ---

    // نقطة التقاء الساقين لتكوين حرف V
    final vPoint = Offset(size.width * 0.5, size.height);

    // 1. الظل أولاً
    final shadowPath = Path();
    // إزاحة بسيطة للظل
    final shadowVPoint = vPoint + Offset(size.width * 0.03, size.height * 0.03);
    shadowPath.moveTo(shadowVPoint.dx, shadowVPoint.dy);
    shadowPath.lineTo(size.width + (size.width * 0.03), - (size.height * 0.03));
    canvas.drawPath(shadowPath, shadowPaint);

    // 2. الساق اليمنى (الحمراء)
    final redPath = Path();
    redPath.moveTo(vPoint.dx, vPoint.dy);
    redPath.lineTo(size.width, 0);
    canvas.drawPath(redPath, redPaint);

    // 3. الساق اليسرى (الزرقاء)
    final leftBluePath = Path();
    leftBluePath.moveTo(vPoint.dx, vPoint.dy);
    leftBluePath.lineTo(0, 0);
    canvas.drawPath(leftBluePath, bluePaint);

    // 4. الساق الحرة (الزرقاء) - تم زيادة طولها من الأعلى
    final freeBluePath = Path();
    // زيادة الطول من الأعلى بتعديل y لتكون سالبة
    final p1_free = Offset(size.width * 0.75, -size.height * 0.1);
    final p2_free = (vPoint + Offset(size.width * 0.5, -size.height * 0.45));
    freeBluePath.moveTo(p1_free.dx, p1_free.dy);
    freeBluePath.lineTo(p2_free.dx, p2_free.dy);
    canvas.drawPath(freeBluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) {
    return false;
  }
}
