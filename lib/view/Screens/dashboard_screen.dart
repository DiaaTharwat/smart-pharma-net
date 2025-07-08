// lib/view/Screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_pharma_net/view/Widgets/common_ui_elements.dart'; // <-- تمت الإضافة
import 'package:smart_pharma_net/viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // للسماح للخلفية بالظهور خلف شريط العنوان
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // جعل شريط العنوان شفافاً
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveParticleBackground( // استخدام نفس الخلفية التفاعلية
        child: SafeArea(
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading && viewModel.stats == null) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (viewModel.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF636AE8).withOpacity(0.8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          onPressed: () => viewModel.fetchDashboardStats(),
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text("Retry", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                );
              }

              if (viewModel.stats == null) {
                return const Center(child: Text("No data available.", style: TextStyle(color: Colors.white70)));
              }

              final stats = viewModel.stats!;

              return RefreshIndicator(
                onRefresh: () => viewModel.fetchDashboardStats(pharmacyId: viewModel.selectedPharmacyId),
                backgroundColor: const Color(0xFF0F0F1A),
                color: Colors.white,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  children: [
                    if (stats.totalPharmacies > 0) ...[
                      _buildSectionTitle(context, 'Network Overview'),
                      _buildStatCard(
                        title: 'Total Pharmacies',
                        value: stats.totalPharmacies.toString(),
                        icon: Icons.local_hospital_outlined,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildStatCard(
                      title: 'Total Medicines Stock',
                      value: stats.totalMedicines.toString(),
                      icon: Icons.medical_services_outlined,
                      color: Colors.lightGreenAccent,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Order Statistics'),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildSmallStatCard(
                          title: 'Pending',
                          value: stats.pendingOrders.toString(),
                          icon: Icons.hourglass_top_rounded,
                          color: Colors.orangeAccent,
                        ),
                        _buildSmallStatCard(
                          title: 'Completed',
                          value: stats.completedOrders.toString(),
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.greenAccent,
                        ),
                        _buildSmallStatCard(
                          title: 'Cancelled',
                          value: stats.cancelledOrders.toString(),
                          icon: Icons.cancel_outlined,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Transaction Summary'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSmallStatCard(
                            title: 'Total Sells',
                            value: stats.totalSells.toString(),
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSmallStatCard(
                            title: 'Total Buys',
                            value: stats.totalBuys.toString(),
                            icon: Icons.arrow_downward_rounded,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF636AE8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF636AE8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF636AE8).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}