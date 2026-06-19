import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/premium_business_card.dart';

class ContactDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ContactDetailsScreen({
    super.key,
    required this.userData,
  });

  Future<void> deleteContact(BuildContext context) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final contactUid = userData['uid'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('contacts')
          .doc(contactUid)
          .delete();

      if (contactUid != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(contactUid).update({
            'contactsSaved': FieldValue.increment(-1),
          });
        } catch (_) {}
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Details')),
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
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () => deleteContact(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
