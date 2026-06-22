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

class MyCardScreen extends StatefulWidget {
  const MyCardScreen({super.key});

  @override
  State<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends State<MyCardScreen> {
  final FirestoreService firestoreService = FirestoreService();

  final nameController         = TextEditingController();
  final designationController  = TextEditingController();
  final companyController      = TextEditingController();
  final phoneController        = TextEditingController();
  final emailController        = TextEditingController();
  final linkedinController     = TextEditingController();
  final websiteController      = TextEditingController();
  final bioController          = TextEditingController();
  final slugController         = TextEditingController();

  BusinessCardTheme _cardTheme = BusinessCardTheme.classic;
  bool isLoading      = false;
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await firestoreService.getUserProfile(uid);
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        nameController.text        = d['name'] ?? '';
        designationController.text = d['designation'] ?? '';
        companyController.text     = d['company'] ?? '';
        phoneController.text       = d['phone'] ?? '';
        emailController.text       = d['email'] ?? '';
        linkedinController.text    = d['linkedin'] ?? '';
        websiteController.text     = d['website'] ?? '';
        bioController.text         = d['bio'] ?? '';
        slugController.text        = d['slug'] ?? '';
        _cardTheme = cardThemeFromKey(d['cardTheme'] as String?);
      } else {
        emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
      }
    } catch (e) {
      debugPrint('Load Profile Error: $e');
    }
    if (mounted) setState(() => isInitializing = false);
  }

  String _toSlug(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-');

  Future<void> _save() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String slug = slugController.text.trim().toLowerCase();
      if (slug.isEmpty) {
        slug = _toSlug(nameController.text);
        slugController.text = slug;
      }

      final taken = await firestoreService.isSlugTaken(slug, user.uid);
      if (taken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username already taken')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      await firestoreService.saveUserProfile(
        uid: user.uid,
        data: {
          'uid': user.uid,
          'slug': slug,
          'cardTheme': _cardTheme.key,
          'name': nameController.text.trim(),
          'designation': designationController.text.trim(),
          'company': companyController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'linkedin': linkedinController.text.trim(),
          'website': websiteController.text.trim(),
          'bio': bioController.text.trim(),
          'profileImage': '',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
      setState(() {});
    } catch (e) {
      debugPrint('Save Profile Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile')),
        );
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _share() async {
    final slug = slugController.text.trim();
    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save your profile first to get a share link')),
      );
      return;
    }
    final url = 'https://digital-business-card-ea8cf.web.app/card/$slug';
    await Share.share('Check out my digital business card: $url', subject: 'My Digital Card');
  }

  Future<void> _downloadVcf() async {
    final content = _vcf();
    final slug = slugController.text.trim().isNotEmpty
        ? slugController.text.trim()
        : 'contact';

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
          subject: '${nameController.text} - Contact Card',
        );
      } catch (e) {
        debugPrint('VCF error: $e');
      }
    }
  }

  String _vcf() => [
        'BEGIN:VCARD',
        'VERSION:3.0',
        'FN:${nameController.text.trim()}',
        'ORG:${companyController.text.trim()}',
        'TITLE:${designationController.text.trim()}',
        'TEL;TYPE=CELL:${phoneController.text.trim()}',
        'EMAIL:${emailController.text.trim()}',
        'URL:${websiteController.text.trim()}',
        'X-SOCIALPROFILE;TYPE=linkedin:${linkedinController.text.trim()}',
        'NOTE:${bioController.text.trim()}',
        'END:VCARD',
      ].join('\n');

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        ),
      ),
    );
  }

  Widget _themePicker() {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: BusinessCardTheme.values.map((t) {
          final active = t == _cardTheme;
          return GestureDetector(
            onTap: () => setState(() => _cardTheme = t),
            child: Container(
              width: 88,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: t.gradientColors),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: active ? AppColors.primaryBlue : Colors.transparent,
                  width: 3,
                ),
                boxShadow: active
                    ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8)]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                t.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.bannerFg,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final slug = slugController.text.trim().toLowerCase();
    final publicUrl = slug.isEmpty
        ? ''
        : 'https://digital-business-card-ea8cf.web.app/card/$slug';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Card',
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download VCF',
            onPressed: _downloadVcf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumBusinessCard(
              name: nameController.text,
              designation: designationController.text,
              company: companyController.text,
              phone: phoneController.text,
              email: emailController.text,
              linkedin: linkedinController.text,
              website: websiteController.text,
              bio: bioController.text,
              theme: _cardTheme,
            ),

            const SizedBox(height: AppSpacing.xl),

            const Text(
              'Card Theme',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            _themePicker(),

            const SizedBox(height: AppSpacing.xl),

            const Text(
              'Card Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildField(controller: nameController, label: 'Full Name', icon: Icons.person_outline),
            _buildField(controller: designationController, label: 'Designation', icon: Icons.work_outline),
            _buildField(controller: companyController, label: 'Company', icon: Icons.business_outlined),

            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TextField(
                controller: slugController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Public username (e.g. ai)',
                  prefixIcon: Icon(Icons.public, size: 20),
                ),
              ),
            ),

            if (publicUrl.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        publicUrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: AppSpacing.md),

            _buildField(controller: phoneController, label: 'Phone', icon: Icons.phone_outlined),
            _buildField(controller: emailController, label: 'Email', icon: Icons.email_outlined),
            _buildField(controller: linkedinController, label: 'LinkedIn', icon: Icons.link),
            _buildField(controller: websiteController, label: 'Website', icon: Icons.language),
            _buildField(controller: bioController, label: 'Bio', maxLines: 3, icon: Icons.info_outline),

            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _save,
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    designationController.dispose();
    companyController.dispose();
    phoneController.dispose();
    emailController.dispose();
    linkedinController.dispose();
    websiteController.dispose();
    bioController.dispose();
    slugController.dispose();
    super.dispose();
  }
}
