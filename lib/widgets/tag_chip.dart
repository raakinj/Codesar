import 'package:flutter/material.dart';

const kContactTags = ['Conference', 'Client', 'Recruiter', 'Student', 'Investor'];

const _kTagColors = {
  'Conference': Color(0xFF4F46E5),
  'Client':     Color(0xFF059669),
  'Recruiter':  Color(0xFF0A66C2),
  'Student':    Color(0xFFD97706),
  'Investor':   Color(0xFFDC2626),
};

Color tagColor(String tag) => _kTagColors[tag] ?? const Color(0xFF64748B);

class TagChip extends StatelessWidget {
  final String tag;
  final bool small;

  const TagChip({super.key, required this.tag, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = tagColor(tag);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: small ? 10 : 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
