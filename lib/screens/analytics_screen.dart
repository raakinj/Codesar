import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService _svc = FirestoreService();
  late final String uid;
  List<Map<String, dynamic>>? weeklyData;
  bool loadingChart = true;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    _loadWeekly();
  }

  Future<void> _loadWeekly() async {
    setState(() => loadingChart = true);
    try {
      final data = await _svc.getWeeklyAnalytics(uid);
      if (mounted) setState(() { weeklyData = data; loadingChart = false; });
    } catch (_) {
      if (mounted) setState(() => loadingChart = false);
    }
  }

  Widget _kpiCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chart(List<Map<String, dynamic>> data, String key, Color color) {
    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), (data[i][key] as double)),
    );
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY < 1 ? 5 : maxY * 1.3,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data[i]['day'] as String,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: color,
              isCurved: true,
              curveSmoothness: 0.35,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.18), color.withOpacity(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartSection(
    String title,
    String key,
    Color color,
    List<Map<String, dynamic>> data,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _chart(data, key, color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

          return RefreshIndicator(
            onRefresh: _loadWeekly,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // KPI row — 3 cards side by side, no GridView
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _kpiCard(
                        icon: Icons.visibility_outlined,
                        label: 'Profile Views',
                        value: (data['profileViews'] ?? 0) as int,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _kpiCard(
                        icon: Icons.qr_code_scanner,
                        label: 'QR Scans',
                        value: (data['qrScans'] ?? 0) as int,
                        color: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _kpiCard(
                        icon: Icons.people_outline,
                        label: 'Contacts Saved',
                        value: (data['contactsSaved'] ?? 0) as int,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                const Text(
                  '7-Day Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (loadingChart)
                  const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (weeklyData != null) ...[
                  _chartSection('Profile Views', 'profileViews', AppColors.primaryBlue, weeklyData!),
                  _chartSection('QR Scans', 'qrScans', const Color(0xFF4F46E5), weeklyData!),
                  _chartSection('Contacts Saved', 'contactsSaved', AppColors.success, weeklyData!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
