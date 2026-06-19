import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_business_card.dart';

class PublicCardScreen extends StatefulWidget {
  final String slug;

  const PublicCardScreen({super.key, required this.slug});

  @override
  State<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends State<PublicCardScreen> {
  final FirestoreService firestoreService = FirestoreService();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool viewRecorded = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadCard();
  }

  Future<void> loadCard() async {
    try {
      final data = await firestoreService.getUserBySlug(widget.slug);
      setState(() {
        userData = data;
        isLoading = false;
      });

      if (data != null) {
        _recordView(data['uid'] as String?);
      }
    } catch (e) {
      debugPrint('Public card load error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _recordView(String? uid) async {
    if (viewRecorded || uid == null) return;
    viewRecorded = true;
    try {
      await firestoreService.incrementProfileViews(uid);
    } catch (_) {}
  }

  Future<void> saveContact() async {
    if (isSaving) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save contacts')),
      );
      return;
    }

    final contactUid = userData?['uid'] as String?;
    if (contactUid == null) return;

    if (contactUid == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't save your own card")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final isNew = await firestoreService.saveContact(
        ownerUid: currentUser.uid,
        contactUid: contactUid,
        contactData: userData!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNew ? 'Contact saved' : 'Contact already saved')),
        );
      }
    } catch (e) {
      debugPrint('Save Contact Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save contact')),
        );
      }
    }

    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Business Card')),
        body: const EmptyState(
          icon: Icons.person_search,
          title: 'Card not found',
          subtitle: 'This business card link is invalid or has been removed.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Business Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            PremiumBusinessCard(
              name: userData!['name'] ?? '',
              designation: userData!['designation'] ?? '',
              company: userData!['company'] ?? '',
              phone: userData!['phone'] ?? '',
              email: userData!['email'] ?? '',
              linkedin: userData!['linkedin'] ?? '',
              website: userData!['website'] ?? '',
              bio: userData!['bio'] ?? '',
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveContact,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_outlined),
                label: Text(isSaving ? 'Saving...' : 'Save Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
