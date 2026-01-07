import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:skindetect/features/history/data/history_repository.dart';
import 'package:skindetect/features/history/data/scan_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('skindetect_test');
    Hive.init(tempDir.path);
    Hive.registerAdapter(ScanModelAdapter());
    await Hive.openBox<ScanModel>('scans');

    // Override app documents dir to temp for repository file IO
    HistoryRepository.setTestAppDir(tempDir);
  });

  tearDownAll(() async {
    await Hive.box<ScanModel>('scans').clear();
    await Hive.box<ScanModel>('scans').close();
    await tempDir.delete(recursive: true);
  });

  test('addScan stores a record and copies image into app dir', () async {
    final repo = HistoryRepository();
    final srcImage = File(p.join(tempDir.path, 'temp.jpg'));
    await srcImage.writeAsBytes([1,2,3]);

    final id = await repo.addScan(
      imagePath: srcImage.path,
      results: const {'Acne': 0.8},
      rawAiResults: const {'Acne': 0.8},
    );

    final scans = repo.getAllScans();
    expect(scans.length, 1);
    expect(scans.first.id, id);
    expect(File(scans.first.imagePath).existsSync(), true);
  });

  test('update and delete scan work as expected', () async {
    final repo = HistoryRepository();
    final srcImage = File(p.join(tempDir.path, 'temp2.jpg'));
    await srcImage.writeAsBytes([4,5,6]);

    final id = await repo.addScan(
      imagePath: srcImage.path,
      results: const {'Eczema': 0.6},
      rawAiResults: const {'Eczema': 0.6},
    );

    await repo.updateScanResult(id, const {'Eczema': 0.9});
    expect(repo.getAllScans().first.result['Eczema'], 0.9);

    await repo.deleteScan(id);
    expect(repo.getAllScans().where((s) => s.id == id).isEmpty, true);
  });
}
