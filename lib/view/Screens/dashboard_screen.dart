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
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false)
          .fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final dashboardTitle = authViewModel.isImpersonating
        ? 'Dashboard: ${authViewModel.activePharmacyName}'
        : (authViewModel.isPharmacy ? 'My Dashboard' : 'Overall Dashboard');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(dashboardTitle,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 5, color: Colors.black54)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                Provider.of<DashboardViewModel>(context, listen: false)
                    .fetchDashboardStats(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: InteractiveParticleBackground(
        child: SafeArea(
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.stats == null) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              if (viewModel.errorMessage != null && viewModel.stats == null) {
                return _buildErrorWidget(context, viewModel.errorMessage!, () {
                  viewModel.fetchDashboardStats();
                });
              }

              if (viewModel.stats == null) {
                return const Center(
                    child: Text("No data available.",
                        style: TextStyle(color: Colors.white70, fontSize: 16)));
              }

              final stats = viewModel.stats!;
              final isPharmacyView =
                  authViewModel.isPharmacy || authViewModel.isImpersonating;

              return RefreshIndicator(
                onRefresh: () => viewModel.fetchDashboardStats(),
                backgroundColor: const Color(0xFF0F0F1A),
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    const SizedBox(height: 10),

                    // --- Stat Cards ---
                    if (authViewModel.isAdmin && !authViewModel.isImpersonating)
                      FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildMetricCard(
                              'Total Pharmacies',
                              stats.totalPharmacies.toString(),
                              Icons.business_center_outlined,
                              Colors.cyan)),

                    // ✨ الشرط الآن سيعمل بشكل صحيح لأن `hasMedicineStats` ستكون صحيحة
                    if (stats.hasMedicineStats)
                      FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildMetricCard(
                              'Medicines Stock',
                              stats.totalMedicines.toString(),
                              Icons.inventory_2_outlined,
                              Colors.lightGreenAccent)),

                    Row(
                      children: [
                        Expanded(
                            child: FadeInLeft(
                                delay: const Duration(milliseconds: 300),
                                child: _buildMetricCard(
                                    'Total Sells',
                                    stats.totalSells.toString(),
                                    Icons.arrow_upward_rounded,
                                    Colors.purpleAccent,
                                    isHalfWidth: true))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: FadeInRight(
                                delay: const Duration(milliseconds: 300),
                                child: _buildMetricCard(
                                    'Total Buys',
                                    stats.totalBuys.toString(),
                                    Icons.arrow_downward_rounded,
                                    Colors.tealAccent,
                                    isHalfWidth: true))),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildSectionDivider("Analytics"),

                    FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 500),
                      child: _buildTransactionsBarChart(stats),
                    ),

                    // ✨ الشرط الآن سيعمل بشكل صحيح لأن `hasOrderStats` ستكون صحيحة
                    if (stats.hasOrderStats) ...[
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 600),
                        child: _buildOrderStatusPieChart(stats),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, String message, VoidCallback onRetry) {
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
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 50),
              const SizedBox(height: 16),
              Text(
                "An Error Occurred",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color,
      {bool isHalfWidth = false}) {
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
          CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.25),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
        ],
      )
          : Row(
        children: [
          CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.25),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
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
            child: Text(title,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        ]),
      ),
    );
  }

  Widget _buildTransactionsBarChart(DashboardStats stats) {
    return AspectRatio(
      aspectRatio: 2.5,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(enabled: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            barGroups: [
              _generateBarGroup(stats, 0, stats.totalSells.toDouble(),
                  const [Color(0xfff869d5), Color(0xff5650de)], "Sells"),
              _generateBarGroup(stats, 1, stats.totalBuys.toDouble(),
                  const [Color(0xff43e794), Color(0xff29a0b1)], "Buys"),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _generateBarGroup(DashboardStats stats, int x, double value,
      List<Color> gradientColors, String title) {
    final double maxValue =
    (stats.totalSells + stats.totalBuys > 0) ? (stats.totalSells + stats.totalBuys) * 1.3 : 1;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter),
          width: 50,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: maxValue, color: Colors.white.withOpacity(0.1)),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }

  Widget _buildOrderStatusPieChart(DashboardStats stats) {
    return AspectRatio(
      aspectRatio: 2.5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 25,
                  sections: [
                    _generatePieSection(
                        0, stats.pendingOrders?.toDouble() ?? 0, Colors.orangeAccent),
                    _generatePieSection(1,
                        stats.completedOrders?.toDouble() ?? 0, Colors.greenAccent),
                    _generatePieSection(2,
                        stats.cancelledOrders?.toDouble() ?? 0, Colors.redAccent),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Indicator(
                      color: Colors.orangeAccent,
                      text: 'Pending',
                      value: stats.pendingOrders ?? 0),
                  const SizedBox(height: 8),
                  _Indicator(
                      color: Colors.greenAccent,
                      text: 'Completed',
                      value: stats.completedOrders ?? 0),
                  const SizedBox(height: 8),
                  _Indicator(
                      color: Colors.redAccent,
                      text: 'Cancelled',
                      value: stats.cancelledOrders ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _generatePieSection(int index, double value, Color color) {
    final isTouched = index == touchedIndex;
    final radius = isTouched ? 35.0 : 30.0;
    final fontSize = isTouched ? 16.0 : 12.0;
    return PieChartSectionData(
        color: color,
        value: value,
        title: '${value.toInt()}',
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 3)]));
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final int value;

  const _Indicator(
      {required this.color, required this.text, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
                color: color)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const Spacer(),
        Text('$value',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
