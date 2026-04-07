import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace with your project credentials from Supabase Settings > API
  await Supabase.initialize(
    url: 'https://qwibhtwpwspxzejopbtn.supabase.co',
    anonKey: 'sb_publishable_h-c5Pqa5hONQbhAy_3hjSQ_OfT46jTM',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// THIS IS THE PART YOU WERE MISSING:
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskHive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'TaskHive: Ready to Build!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}