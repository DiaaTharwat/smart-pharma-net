// lib/view/Screens/dashboard_screen.dart

import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/models/dashboard_model.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedIndex = -1;
  late final DashboardViewModel _dashboardViewModel;

  @override
  void initState() {
    super.initState();
    _dashboardViewModel = Provider.of<DashboardViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dashboardViewModel.startPolling();
    });
  }

  @override
  void dispose() {
    _dashboardViewModel.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final dashboardTitle = authViewModel.activePharmacyName != null
        ? 'Dashboard: ${authViewModel.activePharmacyName}'
        : 'Overall Dashboard';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveParticleBackground(
              child: Consumer<DashboardViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.stats == null) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (viewModel.errorMessage != null && viewModel.stats == null) {
                    return _buildErrorWidget(context, viewModel.errorMessage!, () => viewModel.refreshData());
                  }
                  if (viewModel.stats == null) {
                    return _buildErrorWidget(context, "No data available.", () => viewModel.refreshData());
                  }

                  final stats = viewModel.stats!;
                  final isPharmacyView = authViewModel.activePharmacyId != null;

                  return RefreshIndicator(
                    onRefresh: () => viewModel.refreshData(),
                    backgroundColor: const Color(0xFF0F0F1A),
                    color: Colors.white,
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 10)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildDashboardContent(stats, isPharmacyView),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _buildCustomAppBar(dashboardTitle),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(DashboardStats stats, bool isPharmacyView) {
    // ✨✨✨ تم إضافة هذا المتغير للتحقق من وجود طلبات ✨✨✨
    final int totalOrders = stats.hasOrderStats ? (stats.pendingOrders + stats.completedOrders + stats.cancelledOrders) : 0;

    return Column(
      children: [
        if (!isPharmacyView)
          FadeInUp(delay: const Duration(milliseconds: 100), child: _buildMetricCard('Total Pharmacies', stats.totalPharmacies.toString(), Icons.business_center_outlined, Colors.cyan)),

        if (isPharmacyView && stats.hasMedicineStats)
          FadeInUp(delay: const Duration(milliseconds: 200), child: _buildMetricCard('Medicines in Stock', stats.totalMedicines.toString(), Icons.inventory_2_outlined, Colors.lightGreenAccent)),

        Row(
          children: [
            Expanded(child: FadeInLeft(delay: const Duration(milliseconds: 300), child: _buildMetricCard('Total Sells', stats.totalSells.toString(), Icons.arrow_upward_rounded, Colors.purpleAccent, isHalfWidth: true))),
            const SizedBox(width: 16),
            Expanded(child: FadeInRight(delay: const Duration(milliseconds: 300), child: _buildMetricCard('Total Buys', stats.totalBuys.toString(), Icons.arrow_downward_rounded, Colors.tealAccent, isHalfWidth: true))),
          ],
        ),

        if (isPharmacyView && stats.hasOrderStats)
          Column(
            children: [
              const SizedBox(height: 4),
              FadeInUp(delay: const Duration(milliseconds: 400), child: _buildMetricCard('Pending Orders', stats.pendingOrders.toString(), Icons.hourglass_top_rounded, Colors.orangeAccent)),
              Row(
                children: [
                  Expanded(child: FadeInLeft(delay: const Duration(milliseconds: 500), child: _buildMetricCard('Completed Orders', stats.completedOrders.toString(), Icons.check_circle_outline_rounded, Colors.greenAccent, isHalfWidth: true))),
                  const SizedBox(width: 16),
                  Expanded(child: FadeInRight(delay: const Duration(milliseconds: 500), child: _buildMetricCard('Cancelled Orders', stats.cancelledOrders.toString(), Icons.cancel_outlined, Colors.redAccent, isHalfWidth: true))),
                ],
              ),
            ],
          ),

        const SizedBox(height: 16),
        _buildSectionDivider("Analytics"),

        FadeInUp(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 500), child: _buildTransactionsBarChart(stats)),

        // ✨✨✨ تم إضافة شرط التحقق هنا ✨✨✨
        if (isPharmacyView && stats.hasOrderStats) ...[
          const SizedBox(height: 24),
          _buildSectionDivider("Order Status"),
          if (totalOrders > 0)
            FadeInUp(duration: const Duration(milliseconds: 500), delay: const Duration(milliseconds: 600), child: _buildOrderStatusPieChart(stats, totalOrders))
          else
            _buildNoDataPlaceholder("No Order Data to Display"),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCustomAppBar(String title) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0F0F1A).withOpacity(0.5), const Color(0xFF0F0F1A).withOpacity(0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 5, color: Colors.black54)]))),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => _dashboardViewModel.refreshData(), tooltip: 'Refresh Data'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✨ ويدجت جديد لعرض رسالة عند عدم وجود بيانات للرسم
  Widget _buildNoDataPlaceholder(String message) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: FadeIn(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
              const SizedBox(height: 16),
              Text(
                "An Error Occurred",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {bool isHalfWidth = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: isHalfWidth
          ? Column(
        children: [
          CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.25), child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      )
          : Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.25), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title) {
    return FadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(children: [
          Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        ]),
      ),
    );
  }

  Widget _buildTransactionsBarChart(DashboardStats stats) {
    // ✨ حساب القيمة القصوى مع التأكد من أنها ليست صفرًا
    final double maxY = (stats.totalSells + stats.totalBuys) > 0 ? (stats.totalSells + stats.totalBuys) * 1.2 : 1;

    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A2E).withOpacity(0.8), const Color(0xFF0F0F1A).withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  getTitlesWidget: (value, meta) {
                    String text = '';
                    if (value.toInt() == 0) text = 'Sells';
                    if (value.toInt() == 1) text = 'Buys';
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 16,
                      child: Text(text, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
            ),
            barGroups: [
              _generateBarGroup(0, stats.totalSells.toDouble(), const [Color(0xfff869d5), Color(0xff5650de)]),
              _generateBarGroup(1, stats.totalBuys.toDouble(), const [Color(0xff43e794), Color(0xff29a0b1)]),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _generateBarGroup(int x, double value, List<Color> gradientColors) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.bottomCenter, end: Alignment.topCenter),
          width: 35,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
        ),
      ],
    );
  }

  Widget _buildOrderStatusPieChart(DashboardStats stats, int totalOrders) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A2E).withOpacity(0.8), const Color(0xFF0F0F1A).withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: [
                        _generatePieSection(0, stats.pendingOrders.toDouble(), Colors.orangeAccent),
                        _generatePieSection(1, stats.completedOrders.toDouble(), Colors.greenAccent),
                        _generatePieSection(2, stats.cancelledOrders.toDouble(), Colors.redAccent),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(totalOrders.toString(), style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                      const Text("Total Orders", style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Indicator(color: Colors.orangeAccent, text: 'Pending', value: stats.pendingOrders),
                  const SizedBox(height: 12),
                  _Indicator(color: Colors.greenAccent, text: 'Completed', value: stats.completedOrders),
                  const SizedBox(height: 12),
                  _Indicator(color: Colors.redAccent, text: 'Cancelled', value: stats.cancelledOrders),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _generatePieSection(int index, double value, Color color) {
    final isTouched = index == _touchedIndex;
    final double radius = isTouched ? 65.0 : 55.0;
    final double fontSize = isTouched ? 18.0 : 14.0;
    final shadow = [const Shadow(color: Colors.black, blurRadius: 3)];

    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toInt()}',
      radius: radius,
      titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadow),
      borderSide: isTouched ? BorderSide(color: color.withOpacity(0.8), width: 4) : BorderSide.none,
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final int value;

  const _Indicator({required this.color, required this.text, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5, spreadRadius: 1)]
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const Spacer(),
        Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}