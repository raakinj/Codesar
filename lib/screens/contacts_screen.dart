import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'contact_details_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Contacts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase().trim());
              },
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

                final contacts = snapshot.data!.docs;

                final filteredContacts = contacts.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (filteredContacts.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => Future.delayed(const Duration(milliseconds: 400)),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: EmptyState(
                            icon: Icons.people_outline,
                            title: contacts.isEmpty ? 'No contacts yet' : 'No matches found',
                            subtitle: contacts.isEmpty
                                ? 'Scan a QR code to save your first connection.'
                                : 'Try a different search term.',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => Future.delayed(const Duration(milliseconds: 400)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final data = filteredContacts[index].data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accent,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [data['designation'], data['company']]
                                .where((e) => e != null && e.toString().isNotEmpty)
                                .join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ContactDetailsScreen(userData: data)),
                            );
                          },
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
}
