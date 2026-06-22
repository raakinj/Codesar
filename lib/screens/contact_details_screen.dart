import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_business_card.dart';
import '../widgets/tag_chip.dart';

class ContactDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ContactDetailsScreen({super.key, required this.userData});

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final FirestoreService _svc = FirestoreService();
  late List<String> selectedTags;
  bool savingTags = false;

  @override
  void initState() {
    super.initState();
    selectedTags = (widget.userData['tags'] as List<dynamic>? ?? [])
        .map((t) => t.toString())
        .toList();
  }

  Future<void> _saveTags() async {
    setState(() => savingTags = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final contactUid = widget.userData['uid'] as String?;
      if (contactUid != null) {
        await _svc.updateContactTags(
          ownerUid: uid,
          contactUid: contactUid,
          tags: selectedTags,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tags updated')),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => savingTags = false);
  }

  Future<void> _delete() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final contactUid = widget.userData['uid'];
      await _svc.removeContact(ownerUid: currentUid, contactUid: contactUid);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted')),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = cardThemeFromKey(widget.userData['cardTheme'] as String?);

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumBusinessCard(
              name: widget.userData['name'] ?? '',
              designation: widget.userData['designation'] ?? '',
              company: widget.userData['company'] ?? '',
              phone: widget.userData['phone'] ?? '',
              email: widget.userData['email'] ?? '',
              linkedin: widget.userData['linkedin'] ?? '',
              website: widget.userData['website'] ?? '',
              bio: widget.userData['bio'] ?? '',
              theme: theme,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Tags section
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kContactTags.map((tag) {
                final selected = selectedTags.contains(tag);
                final color = tagColor(tag);
                return GestureDetector(
                  onTap: () => _toggleTag(tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? color : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: selected ? color : AppColors.border, width: 1.5),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: savingTags ? null : _saveTags,
                child: savingTags
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Tags'),
              ),
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
                onPressed: () => _delete(),
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
