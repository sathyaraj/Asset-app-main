import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:assets_app/features/auth/presentation/screens/login_screen.dart';
import 'package:assets_app/features/dashboard/presentation/screens/main_navigation_screen.dart';
import 'package:assets_app/core/utils/app_colors.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Management ERP',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          background: AppColors.background,
        ),

        useMaterial3: true,

        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // ---------------------------------------------------------
      // CHECK LOGIN STATUS BEFORE SHOWING FIRST SCREEN
      // ---------------------------------------------------------
      home: const AuthCheck(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainNavigationScreen(),
      },
    );
  }
}

// =============================================================
// AUTH CHECK
// =============================================================

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // ===========================================================
  // CHECK SAVED JWT TOKEN
  // ===========================================================

  Future<void> _checkLogin() async {
    try {
      final token = await _storage.read(
        key: 'jwt_token',
      );

      if (!mounted) return;

      setState(() {
        _isLoggedIn =
            token != null && token.trim().isNotEmpty;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggedIn = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------------
    // SHOW LOADING WHILE CHECKING TOKEN
    // ---------------------------------------------------------

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ---------------------------------------------------------
    // TOKEN EXISTS → DASHBOARD
    // TOKEN NOT EXISTS → LOGIN
    // ---------------------------------------------------------

    if (_isLoggedIn) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}