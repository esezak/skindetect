import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/utils.dart';
import '../../history/data/scan_model.dart';
import '../../history/data/history_repository.dart';
import '../../results/presentation/results_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previous Scans')),
      // ValueListenableBuilder makes the list update automatically when new data is added
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ScanModel>('scans').listenable(),
        builder: (context, Box<ScanModel> box, _) {
          final scans = HistoryRepository().getAllScans();
          if (scans.isEmpty) {
            return const Center(child: Text('No scans recorded yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              return _HistoryCard(scan: scan);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanModel scan;

  const _HistoryCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    // Sort results by confidence (Highest to Lowest)
    final sortedEntries = scan.result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 for the preview
    final previewEntries = sortedEntries.take(3).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                imagePath: scan.imagePath,
                results: scan.result,           // The FINAL saved score
                rawAiResult: scan.rawAiResult,  // The RAW AI score
                fromHistory: true,
                scanId: scan.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- THUMBNAIL ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(scan.imagePath),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(
                      width: 80, height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported)
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // --- DATA LIST ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Scan Number/Date
                    Text(
                      'Scan ${DateFormat('MM/dd HH:mm').format(scan.date)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // List of Diseases (Disease 1, Disease 2...)
                    ...previewEntries.map((entry) {
                      final percentage = (entry.value * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cleanKey(entry.key), // Clean name
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Arrow Icon
              const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 30),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}