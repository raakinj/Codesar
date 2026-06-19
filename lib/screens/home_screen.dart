
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/action_card.dart';
import '../widgets/stat_card.dart';
import 'my_card_screen.dart';
import 'my_qr_screen.dart';
import 'qr_scanner_screen.dart';
import 'contacts_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          backgroundColor: Colors.white.withOpacity(0.08),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyCardScreen()),
                        ),
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('Edit My Card'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.15,
                children: [
                  ActionCard(
                    icon: Icons.badge_outlined,
                    title: 'My Card',
                    subtitle: 'Edit your profile',
                    color: AppColors.primaryBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCardScreen()),
                    ),
                  ),
                  ActionCard(
                    icon: Icons.qr_code_2,
                    title: 'My QR',
                    subtitle: 'Share instantly',
                    color: AppColors.primaryDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyQrScreen()),
                    ),
                  ),
                  ActionCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan QR',
                    subtitle: 'Add a connection',
                    color: AppColors.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                    ),
                  ),
                  ActionCard(
                    icon: Icons.people_outline,
                    title: 'Contacts',
                    subtitle: 'Your network',
                    color: AppColors.primaryBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Networking Overview',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              StreamBuilder<DocumentSnapshot>(
                stream: uid.isEmpty
                    ? null
                    : FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snapshot) {
                  final data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};

                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.visibility_outlined,
                          label: 'Profile Views',
                          value: data['profileViews'] ?? 0,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatCard(
                          icon: Icons.people_outline,
                          label: 'Contacts Saved',
                          value: data['contactsSaved'] ?? 0,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
