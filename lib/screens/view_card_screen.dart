import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_business_card.dart';

class ViewCardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ViewCardScreen({super.key, required this.userData});

  @override
  State<ViewCardScreen> createState() => _ViewCardScreenState();
}

class _ViewCardScreenState extends State<ViewCardScreen> {
  final FirestoreService _svc = FirestoreService();
  bool _viewRecorded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _recordView();
  }

  Future<void> _recordView() async {
    if (_viewRecorded) return;
    final uid = widget.userData['uid'] as String?;
    if (uid == null) return;
    _viewRecorded = true;
    try { await _svc.incrementProfileViews(uid); } catch (_) {}
  }

  Future<void> _saveContact() async {
    if (_isSaving) return;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final contactUid = widget.userData['uid'] as String?;
    if (contactUid == null) return;

    if (contactUid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't save your own card")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final isNew = await _svc.saveContact(
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

  Future<void> _share() async {
    final slug = widget.userData['slug'] as String?;
    final name = widget.userData['name'] ?? '';
    if (slug != null && slug.isNotEmpty) {
      final url = 'https://digital-business-card-ea8cf.web.app/card/$slug';
      await Share.share('Check out $name\'s digital card: $url', subject: '$name - Business Card');
    } else {
      await Share.share('Check out $name\'s digital business card!', subject: '$name - Business Card');
    }
  }

  Future<void> _downloadVcf() async {
    final d = widget.userData;
    final content = [
      'BEGIN:VCARD', 'VERSION:3.0',
      'FN:${d['name'] ?? ''}',
      'ORG:${d['company'] ?? ''}',
      'TITLE:${d['designation'] ?? ''}',
      'TEL;TYPE=CELL:${d['phone'] ?? ''}',
      'EMAIL:${d['email'] ?? ''}',
      'URL:${d['website'] ?? ''}',
      'X-SOCIALPROFILE;TYPE=linkedin:${d['linkedin'] ?? ''}',
      'NOTE:${d['bio'] ?? ''}',
      'END:VCARD',
    ].join('\n');

    final slug = (d['slug'] as String?)?.isNotEmpty == true ? d['slug'] : 'contact';

    if (kIsWeb) {
      try {
        final encoded = Uri.encodeComponent(content);
        await launchUrl(Uri.parse('data:text/vcard;charset=utf-8,$encoded'));
      } catch (_) {}
    } else {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$slug.vcf');
        await file.writeAsString(content);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/vcard')],
          subject: '${d['name'] ?? ''} - Contact Card',
        );
      } catch (e) {
        debugPrint('VCF error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.userData;
    final theme = cardThemeFromKey(d['cardTheme'] as String?);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            PremiumBusinessCard(
              name: d['name'] ?? '',
              designation: d['designation'] ?? '',
              company: d['company'] ?? '',
              phone: d['phone'] ?? '',
              email: d['email'] ?? '',
              linkedin: d['linkedin'] ?? '',
              website: d['website'] ?? '',
              bio: d['bio'] ?? '',
              theme: theme,
            ),

            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveContact,
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
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _downloadVcf,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(52, 52),
                    ),
                    child: const Icon(Icons.download_outlined, size: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _share,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(52, 52),
                    ),
                    child: const Icon(Icons.share_outlined, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
