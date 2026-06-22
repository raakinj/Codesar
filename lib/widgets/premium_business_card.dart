import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'contact_avatar.dart';

enum BusinessCardTheme { classic, corporate, dark, minimal, modern }

extension BusinessCardThemeX on BusinessCardTheme {
  String get key {
    switch (this) {
      case BusinessCardTheme.classic:    return 'classic';
      case BusinessCardTheme.corporate:  return 'corporate';
      case BusinessCardTheme.dark:       return 'dark';
      case BusinessCardTheme.minimal:    return 'minimal';
      case BusinessCardTheme.modern:     return 'modern';
    }
  }

  String get label {
    switch (this) {
      case BusinessCardTheme.classic:    return 'Classic';
      case BusinessCardTheme.corporate:  return 'Corporate';
      case BusinessCardTheme.dark:       return 'Dark';
      case BusinessCardTheme.minimal:    return 'Minimal';
      case BusinessCardTheme.modern:     return 'Modern';
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case BusinessCardTheme.classic:    return [const Color(0xFF0B1F3F), const Color(0xFF0A66C2)];
      case BusinessCardTheme.corporate:  return [const Color(0xFF0F172A), const Color(0xFF334155)];
      case BusinessCardTheme.dark:       return [const Color(0xFF09090B), const Color(0xFF18181B)];
      case BusinessCardTheme.minimal:    return [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)];
      case BusinessCardTheme.modern:     return [const Color(0xFF4F46E5), const Color(0xFF7C3AED)];
    }
  }

  Color get bannerFg {
    switch (this) {
      case BusinessCardTheme.minimal: return const Color(0xFF0F172A);
      default:                        return Colors.white;
    }
  }

  Color get chipColor {
    switch (this) {
      case BusinessCardTheme.minimal: return const Color(0xFF94A3B8);
      default:                        return Colors.white.withOpacity(0.35);
    }
  }

  Color get infoIconBg {
    switch (this) {
      case BusinessCardTheme.dark:    return const Color(0xFF27272A);
      case BusinessCardTheme.minimal: return const Color(0xFFF1F5F9);
      default:                        return AppColors.accent;
    }
  }

  Color get infoIconColor {
    switch (this) {
      case BusinessCardTheme.dark:    return const Color(0xFF818CF8);
      case BusinessCardTheme.minimal: return AppColors.textSecondary;
      default:                        return AppColors.primaryBlue;
    }
  }
}

BusinessCardTheme cardThemeFromKey(String? key) {
  switch (key) {
    case 'corporate': return BusinessCardTheme.corporate;
    case 'dark':      return BusinessCardTheme.dark;
    case 'minimal':   return BusinessCardTheme.minimal;
    case 'modern':    return BusinessCardTheme.modern;
    default:          return BusinessCardTheme.classic;
  }
}

class PremiumBusinessCard extends StatelessWidget {
  final String name;
  final String designation;
  final String company;
  final String phone;
  final String email;
  final String linkedin;
  final String website;
  final String bio;
  final BusinessCardTheme theme;

  const PremiumBusinessCard({
    super.key,
    required this.name,
    required this.designation,
    required this.company,
    required this.phone,
    required this.email,
    required this.linkedin,
    required this.website,
    required this.bio,
    this.theme = BusinessCardTheme.classic,
  });

  Widget _infoRow(IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.infoIconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 16, color: theme.infoIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [designation, company].where((e) => e.isNotEmpty).join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Subtle dot pattern
                Positioned.fill(
                  child: CustomPaint(painter: _DotPatternPainter(theme.bannerFg.withOpacity(0.06))),
                ),
                // NFC chip visual
                Positioned(
                  top: 18,
                  right: 20,
                  child: Column(
                    children: [
                      Icon(Icons.contactless, size: 26, color: theme.chipColor),
                      const SizedBox(height: 2),
                      Container(
                        width: 36,
                        height: 26,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.chipColor, width: 1.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.chipColor, width: 1.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar overlapping banner
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: ContactAvatar(name: name.isNotEmpty ? name : '?', radius: 36),
                  ),
                ),

                // Name + subtitle
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Your Name' : name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (bio.isNotEmpty)
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),

                const Divider(),
                const SizedBox(height: 4),
                _infoRow(Icons.phone_outlined, phone),
                _infoRow(Icons.email_outlined, email),
                _infoRow(Icons.link, linkedin),
                _infoRow(Icons.language, website),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;
  _DotPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 20.0;
    const radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}
