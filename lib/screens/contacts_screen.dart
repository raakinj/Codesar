import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/tag_chip.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String searchQuery = '';
  String? activeTagFilter;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Contacts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or tag...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase().trim()),
            ),
          ),

          // Tag filter row
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All', null),
                ...kContactTags.map((t) => _filterChip(t, t)),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('contacts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    subtitle: 'Unable to load contacts right now.',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!.docs;

                final filtered = all.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name = (d['name'] ?? '').toString().toLowerCase();
                  final tags = (d['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList();

                  final matchesSearch = searchQuery.isEmpty ||
                      name.contains(searchQuery) ||
                      tags.any((t) => t.toLowerCase().contains(searchQuery));

                  final matchesTag = activeTagFilter == null || tags.contains(activeTagFilter);

                  return matchesSearch && matchesTag;
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => Future.delayed(const Duration(milliseconds: 300)),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: EmptyState(
                            icon: Icons.people_outline,
                            title: all.isEmpty ? 'No contacts yet' : 'No matches found',
                            subtitle: all.isEmpty
                                ? 'Scan someone\'s QR code to save your first connection.'
                                : 'Try a different search or filter.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => Future.delayed(const Duration(milliseconds: 300)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString();
                      final tags = (data['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList();
                      final subParts = [data['designation'], data['company']]
                          .where((e) => e != null && e.toString().isNotEmpty)
                          .toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactDetailsScreen(userData: data),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                            child: Row(
                              children: [
                                ContactAvatar(name: name, radius: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (subParts.isNotEmpty)
                                        Text(
                                          subParts.join(' · '),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (tags.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 5),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: tags.map((t) => TagChip(tag: t, small: true)).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? tagValue) {
    final active = activeTagFilter == tagValue;
    final color = tagValue != null ? tagColor(tagValue) : AppColors.primaryBlue;
    return GestureDetector(
      onTap: () => setState(() => activeTagFilter = tagValue),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
