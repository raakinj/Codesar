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
  final FirestoreService firestoreService = FirestoreService();
  bool scanned = false;

  Future<void> loadProfile(String uid) async {
    try {
      final doc = await firestoreService.getUserProfile(uid);

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found'),
            ),
          );

          setState(() => scanned = false);
        }
        return;
      }

      await firestoreService.incrementQrScans(uid);

      if (!mounted) return;

      final userData = doc.data() as Map<String, dynamic>;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ViewCardScreen(
            userData: userData,
          ),
        ),
      );
    } catch (e) {
      debugPrint('QR Scanner Error: $e');

      if (mounted) {
        setState(() => scanned = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
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

              final barcode = capture.barcodes.first;
              final uid = barcode.rawValue;

              if (uid == null || uid.isEmpty) {
                return;
              }

              setState(() => scanned = true);
              loadProfile(uid);
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(
                  AppRadius.lg,
                ),
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
                color: Colors.white.withValues(alpha: 0.9),
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