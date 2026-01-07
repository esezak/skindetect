import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart'; // Need this for permanent paths
import 'package:path/path.dart' as p;             // Need this for joining paths
import 'scan_model.dart';

class HistoryRepository {
  static final HistoryRepository _instance = HistoryRepository._internal();
  factory HistoryRepository() => _instance;
  HistoryRepository._internal();

  final Box<ScanModel> _box = Hive.box<ScanModel>('scans');

  // Test-only: allow overriding the application documents directory
  static Directory? _testAppDir;
  static void setTestAppDir(Directory? dir) { _testAppDir = dir; }

  /// GET ALL SCANS
  List<ScanModel> getAllScans() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// ADD SCAN TO DB
  Future<String> addScan({
    required String imagePath,
    required Map<String, double> results,
    required Map<String, double> rawAiResults,
    String? id,
    DateTime? date,
  }) async {
    final newId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final newDate = date ?? DateTime.now();

    // Get the App Document Directory (use test override when provided)
    final appDir = _testAppDir ?? await getApplicationDocumentsDirectory();

    // Create a 'scans' subfolder if it doesn't exist
    final scansDir = Directory(p.join(appDir.path, 'scans'));
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    // Define the new permanent path
    final fileExtension = p.extension(imagePath);
    final imgPath = p.join(scansDir.path, 'scan_$newId$fileExtension');

    // Copy the file from Cache to Permanent
    final sourceFile = File(imagePath);
    if (await sourceFile.exists()) {
      await sourceFile.copy(imgPath);
    }

    // 5. Save the path to Hive
    final scan = ScanModel(
      id: newId,
      imagePath: imgPath,
      date: newDate,
      result: results,
      rawAiResult: rawAiResults,
    );

    await _box.put(scan.id, scan);
    return newId;
  }

  /// UPDATE SCAN RESULT
  Future<void> updateScanResult(String id, Map<String, double> newFinalResults) async {
    final scan = _box.get(id);
    if (scan != null) {
      final updatedScan = ScanModel(
        id: scan.id,
        imagePath: scan.imagePath, // Path is already permanent
        date: scan.date,
        result: newFinalResults,
        rawAiResult: scan.rawAiResult,
      );
      await _box.put(id, updatedScan);
    }
  }

  /// DELETE SCAN
  Future<void> deleteScan(String id) async {
    final scan = _box.get(id);
    if (scan != null) {
      // Delete the physical image file to free up space
      final file = File(scan.imagePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          // Ignore error if file is already gone
        }
      }

      // Remove entry from Database
      await scan.delete();
    }
  }
}