import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = (snapshot.data!.data() as Map<String, dynamic>?) ?? {};

          return RefreshIndicator(
            onRefresh: () => Future.delayed(const Duration(milliseconds: 400)),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text(
                  'Performance Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      icon: Icons.visibility_outlined,
                      label: 'Profile Views',
                      value: data['profileViews'] ?? 0,
                      color: AppColors.primaryBlue,
                    ),
                    StatCard(
                      icon: Icons.qr_code_scanner,
                      label: 'QR Scans',
                      value: data['qrScans'] ?? 0,
                      color: AppColors.primaryDark,
                    ),
                    StatCard(
                      icon: Icons.people_outline,
                      label: 'Contacts Saved',
                      value: data['contactsSaved'] ?? 0,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
