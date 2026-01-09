import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:flutter/services.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/history/data/scan_model.dart';
import 'features/questions/data/question_service.dart'; // Import Model
Future<void> main() async {
// Initialize Flutter Bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Keep status bar visible; hide navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    // Leave status bar as-is
  ));

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
      builder: (context, child) => _ImmersiveWrapper(child: child),
      // This connects the entry point to the HomeScreen widget
      home: const HomeScreen(),
    );
  }
}

class _ImmersiveWrapper extends StatefulWidget {
  final Widget? child;
  const _ImmersiveWrapper({required this.child});

  @override
  State<_ImmersiveWrapper> createState() => _ImmersiveWrapperState();
}

class _ImmersiveWrapperState extends State<_ImmersiveWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applySystemUi();
  }

  void _applySystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applySystemUi();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
