import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/auth_screen.dart'; 
import 'screens/home/dashboard_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load the environment variables
  await dotenv.load(fileName: ".env");

  // 2. Initialize Supabase using the loaded keys
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskHive',
      // The StreamBuilder listens to Supabase Auth changes
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;

          if (session != null) {
            // User is logged in -> Show Dashboard
            return const DashboardScreen();
          } else {
            // No user -> Show Login/Signup Screen
            return const AuthScreen();
          }
        },
      ),
    );
  }
}
