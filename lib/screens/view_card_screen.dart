import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_business_card.dart';

class ViewCardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ViewCardScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ViewCardScreen> createState() => _ViewCardScreenState();
}

class _ViewCardScreenState extends State<ViewCardScreen> {
  final FirestoreService firestoreService = FirestoreService();

  bool _viewRecorded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _incrementProfileViews();
  }

  Future<void> _incrementProfileViews() async {
    try {
      if (_viewRecorded) return;

      final profileUid = widget.userData['uid'];
      if (profileUid == null) return;

      await firestoreService.incrementProfileViews(profileUid);
      _viewRecorded = true;
    } catch (e) {
      debugPrint('Profile View Error: $e');
    }
  }

  Future<void> saveContact() async {
    if (_isSaving) return;

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final contactUid = widget.userData['uid'];

    if (contactUid == null) return;

    if (contactUid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't save your own card")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isNew = await firestoreService.saveContact(
        ownerUid: currentUid,
        contactUid: contactUid,
        contactData: widget.userData,
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

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            PremiumBusinessCard(
              name: userData['name'] ?? '',
              designation: userData['designation'] ?? '',
              company: userData['company'] ?? '',
              phone: userData['phone'] ?? '',
              email: userData['email'] ?? '',
              linkedin: userData['linkedin'] ?? '',
              website: userData['website'] ?? '',
              bio: userData['bio'] ?? '',
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : saveContact,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
