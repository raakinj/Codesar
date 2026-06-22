import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'view_card_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final FirestoreService _svc = FirestoreService();
  bool scanned = false;

  // Returns slug (from URL QR) or raw value (legacy uid QR)
  // Never returns the full URL
  String? _extractSlug(String raw) {
    // Detect URL format
    final uri = Uri.tryParse(raw);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final segments = uri.pathSegments;
      // Expected: /card/{slug}
      if (segments.length >= 2 && segments[0] == 'card' && segments[1].isNotEmpty) {
        return segments[1];
      }
      // Unrecognised URL — don't pass to Firestore
      return null;
    }
    // Not a URL — treat as legacy uid
    return raw;
  }

  Future<void> _loadProfile(String raw) async {
    try {
      final slug = _extractSlug(raw);

      if (slug == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unrecognised QR code')),
          );
          setState(() => scanned = false);
        }
        return;
      }

      Map<String, dynamic>? userData;

      // Determine lookup strategy
      final uri = Uri.tryParse(raw);
      final isUrl = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

      if (isUrl) {
        // Slug-based lookup
        userData = await _svc.getUserBySlug(slug);
      } else {
        // Legacy uid-based lookup
        final doc = await _svc.getUserProfile(slug);
        if (doc.exists) {
          userData = doc.data() as Map<String, dynamic>?;
        }
      }

      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
          setState(() => scanned = false);
        }
        return;
      }

      final uid = userData['uid'] as String?;
      if (uid != null && uid.isNotEmpty) {
        await _svc.incrementQrScans(uid);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ViewCardScreen(userData: userData!)),
      );
    } catch (e) {
      debugPrint('QR load error: $e');
      if (mounted) setState(() => scanned = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (scanned) return;
              final raw = capture.barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              setState(() => scanned = true);
              _loadProfile(raw);
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'Align the QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
