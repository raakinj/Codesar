import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final nameController = TextEditingController();
  final designationController = TextEditingController();
  final companyController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final linkedinController = TextEditingController();
  final websiteController = TextEditingController();
  final bioController = TextEditingController();
  final slugController = TextEditingController();

  bool isLoading = false;
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await firestoreService.getUserProfile(uid);

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        nameController.text = data['name'] ?? '';
        designationController.text = data['designation'] ?? '';
        companyController.text = data['company'] ?? '';
        phoneController.text = data['phone'] ?? '';
        emailController.text = data['email'] ?? '';
        linkedinController.text = data['linkedin'] ?? '';
        websiteController.text = data['website'] ?? '';
        bioController.text = data['bio'] ?? '';
        slugController.text = data['slug'] ?? '';
      } else {
        emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
      }
    } catch (e) {
      debugPrint('Load Profile Error: $e');
    }

    if (mounted) setState(() => isInitializing = false);
  }

  String generateSlug(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> saveProfile() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      String slug = slugController.text.trim().toLowerCase();

      if (slug.isEmpty) {
        slug = generateSlug(nameController.text);
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

  Widget buildTextField({
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
      appBar: AppBar(title: const Text('My Digital Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
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
            ),

            const SizedBox(height: AppSpacing.xl),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Card Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            buildTextField(controller: nameController, label: 'Full Name', icon: Icons.person_outline),
            buildTextField(controller: designationController, label: 'Designation', icon: Icons.work_outline),
            buildTextField(controller: companyController, label: 'Company', icon: Icons.business_outlined),

            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: TextField(
                controller: slugController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Public username (e.g. pruthivi-ai)',
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

            buildTextField(controller: phoneController, label: 'Phone', icon: Icons.phone_outlined),
            buildTextField(controller: emailController, label: 'Email', icon: Icons.email_outlined),
            buildTextField(controller: linkedinController, label: 'LinkedIn', icon: Icons.link),
            buildTextField(controller: websiteController, label: 'Website', icon: Icons.language),
            buildTextField(controller: bioController, label: 'Bio', maxLines: 3, icon: Icons.info_outline),

            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
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
