import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/vcf_downloader.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_business_card.dart';

class PublicCardScreen extends StatefulWidget {
  final String slug;

  const PublicCardScreen({super.key, required this.slug});

  @override
  State<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends State<PublicCardScreen> {
  final FirestoreService _svc = FirestoreService();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool viewRecorded = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final data = await _svc.getUserBySlug(widget.slug);
      setState(() {
        userData = data;
        isLoading = false;
      });
      if (data != null) _recordView(data['uid'] as String?);
    } catch (e) {
      debugPrint('Public card load error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _recordView(String? uid) async {
    if (viewRecorded || uid == null) return;
    viewRecorded = true;
    try {
      await _svc.incrementProfileViews(uid);
    } catch (_) {}
  }

  String _buildVcf() {
    final d = userData ?? {};
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${d['name'] ?? ''}',
      'ORG:${d['company'] ?? ''}',
      'TITLE:${d['designation'] ?? ''}',
    ];
    final phone = (d['phone'] as String? ?? '').trim();
    if (phone.isNotEmpty) lines.add('TEL;TYPE=CELL:$phone');
    final email = (d['email'] as String? ?? '').trim();
    if (email.isNotEmpty) lines.add('EMAIL:$email');
    final website = (d['website'] as String? ?? '').trim();
    if (website.isNotEmpty) lines.add('URL:$website');
    final linkedin = (d['linkedin'] as String? ?? '').trim();
    if (linkedin.isNotEmpty) lines.add('X-SOCIALPROFILE;TYPE=linkedin:$linkedin');
    final bio = (d['bio'] as String? ?? '').trim();
    if (bio.isNotEmpty) lines.add('NOTE:$bio');
    lines.add('END:VCARD');
    return lines.join('\r\n');
  }

  Future<void> _downloadContact() async {
    if (userData == null) return;
    setState(() => isDownloading = true);
    try {
      final content = _buildVcf();
      final rawName = (userData!['name'] as String? ?? 'contact')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-');
      await downloadVcf(
        content: content,
        filename: '$rawName.vcf',
        contactName: userData!['name'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('VCF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download contact')),
        );
      }
    }
    if (mounted) setState(() => isDownloading = false);
  }

  Future<void> _shareProfile() async {
    final url =
        'https://digital-business-card-ea8cf.web.app/card/${widget.slug}';
    final name = (userData?['name'] as String? ?? '').trim();
    final shareText =
        name.isNotEmpty ? 'Check out $name\'s digital card: $url' : url;

    if (kIsWeb) {
      // On web: Share.share() silently does nothing when Web Share API
      // is unavailable (Chrome Desktop, Edge Desktop, Firefox).
      // Copy to clipboard — works reliably on all browsers with a user gesture.
      try {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link copied to clipboard')),
          );
        }
      } catch (e) {
        debugPrint('Clipboard error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectableText(url)),
          );
        }
      }
    } else {
      // On mobile app: use native share sheet
      try {
        await Share.share(
          shareText,
          subject: name.isNotEmpty ? '$name - Digital Business Card' : 'Digital Business Card',
        );
      } catch (e) {
        debugPrint('Share error: $e');
      }
    }
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
          subtitle: 'This link is invalid or has been removed.',
        ),
      );
    }

    final theme = cardThemeFromKey(userData!['cardTheme'] as String?);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _shareProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              theme: theme,
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isDownloading ? null : _downloadContact,
                icon: isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 22),
                label: Text(
                  isDownloading ? 'Downloading...' : 'Download Contact',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _shareProfile,
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  'Share Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(
                      color: AppColors.primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Center(
              child: Text(
                'Digital Business Card',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
