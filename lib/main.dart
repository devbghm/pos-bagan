import 'package:flutter/material.dart';
import 'data/pos_database.dart';
import 'screens/pos_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PosDatabase.instance.database;
  runApp(const PosBaganApp());
}

class PosBaganApp extends StatelessWidget {
  const PosBaganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Bagan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8A4B18)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const PosHomePage(),
    );
  }
}
