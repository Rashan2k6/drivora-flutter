import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/mock_data_provider.dart';
import 'services/database_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await dotenv.load(fileName: ".env");
    await NotificationService.init();
    final allVehicles = await DatabaseHelper.instance.getVehicles();
    for (final v in allVehicles) {
      final docs = await DatabaseHelper.instance.getAllDocuments(v.id);
      for (final doc in docs) {
        await NotificationService.scheduleForDocument(doc, v.displayName);
      }
    }
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  final vehicles = await DatabaseHelper.instance.getVehicles();
  if (vehicles.isEmpty) {
    await MockDataProvider.seedDatabase();
  }

  runApp(const DrivoraApp());
}

class DrivoraApp extends StatelessWidget {
  const DrivoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drivora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 72,
          titleSpacing: 20,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
