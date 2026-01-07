import 'package:hive/hive.dart';
part 'scan_model.g.dart';

@HiveType(typeId: 0)
class ScanModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final Map<String, double> result;

  @HiveField(4)
  final Map<String, double>? rawAiResult; // This is the PURE AI score

  ScanModel({
    required this.id,
    required this.imagePath,
    required this.date,
    required this.result,
    this.rawAiResult,
  });
}