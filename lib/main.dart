import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/mock_data_provider.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORARY: seed mock data once. Remove this call once you have
  // real data entry screens (Step 6+).
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
      ),
      home: const DashboardScreen(),
    );
  }
}