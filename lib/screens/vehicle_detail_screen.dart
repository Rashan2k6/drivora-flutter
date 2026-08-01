import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/mock_data_provider.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final documents = MockDataProvider.getDocuments()
        .where((d) => d.vehicleId == vehicle.id)
        .toList();
    final services = MockDataProvider.getServiceRecords()
        .where((s) => s.vehicleId == vehicle.id)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: Text('${vehicle.make} ${vehicle.model}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Documents'),
              Tab(text: 'Service History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: documents.map((doc) {
                return ListTile(
                  title: Text(doc.type.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Expires: ${doc.expiryDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: services.map((s) {
                return ListTile(
                  title: Text(s.description,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${s.date.toLocal()}'.split(' ')[0] +
                        ' • ${s.mileage}km • Rs.${s.cost}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}