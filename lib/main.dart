import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'features/home/presentation/home_screen.dart';
import 'features/history/data/scan_model.dart';
import 'features/questions/data/question_service.dart'; // Import Model
Future<void> main() async {
// Initialize Flutter Bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register the Adapter
  Hive.registerAdapter(ScanModelAdapter());

  // Open db
  await Hive.openBox<ScanModel>('scans');
  QuestionService().initialize();
  runApp(const ProviderScope(child: SkinDetectApp()));
}

class SkinDetectApp extends ConsumerWidget {
  const SkinDetectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Skin Detect',
      debugShowCheckedModeBanner: false, // Removes the "Debug" banner
      theme: ThemeData(
        useMaterial3: true,
        // Using a Deep Purple seed
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      // This connects the entry point to the HomeScreen widget
      home: const HomeScreen(),
    );
  }
}