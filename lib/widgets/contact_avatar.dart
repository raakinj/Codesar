import 'package:flutter/material.dart';

class ContactAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const ContactAvatar({super.key, required this.name, this.radius = 22});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color get _color {
    const palette = [
      Color(0xFF0A66C2), Color(0xFF4F46E5), Color(0xFF059669),
      Color(0xFFDC2626), Color(0xFFD97706), Color(0xFF7C3AED),
      Color(0xFF0891B2), Color(0xFFDB2777), Color(0xFF16A34A),
      Color(0xFFEA580C),
    ];
    int hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _color,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
