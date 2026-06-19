import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/main_nav_screen.dart';
import 'screens/login_screen.dart';
import 'screens/public_card_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String? _slugFromUrl() {
    if (!kIsWeb) return null;
    final uri = Uri.base;
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'card') {
      return segments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final slug = _slugFromUrl();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Business Card',
      theme: AppTheme.light,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final match = RegExp(r'^/card/(.+)$').firstMatch(name);
        if (match != null) {
          return MaterialPageRoute(
            builder: (_) => PublicCardScreen(slug: match.group(1)!),
          );
        }
        return null;
      },
      home: slug != null
          ? PublicCardScreen(slug: slug)
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData) {
                  return const MainNavScreen();
                }

                return const LoginScreen();
              },
            ),
    );
  }
}
