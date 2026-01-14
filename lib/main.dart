import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/robot_provider.dart';
import 'providers/logs_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => RobotProvider()),
        ChangeNotifierProvider(create: (_) => LogsProvider()),
      ],
      child: const HumoSafeApp(),
    ),
  );
}

class HumoSafeApp extends StatelessWidget {
  const HumoSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUMOSAFE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
        ),
      ),
      home: Consumer<app_auth.AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated
              ? const MainScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
