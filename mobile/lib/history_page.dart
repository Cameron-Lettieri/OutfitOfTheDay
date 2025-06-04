import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'outfit_record.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit History')),
      body: FutureBuilder<List<OutfitRecord>>( 
        future: StorageService.loadHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data!;
          if (history.isEmpty) {
            return const Center(child: Text('No history yet'));
          }
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final rec = history[history.length - 1 - index];
              final dateStr = DateFormat.yMMMEd().format(rec.date);
              return ListTile(
                title: Text(dateStr),
                subtitle: Text(rec.items.join(', ')),
              );
            },
          );
        },
      ),
    );
  }
}
