import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skindetect/core/utils/utils.dart';
import '../../history/data/history_repository.dart';
import '../../questions/presentation/questionnaire_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, double> results;
  final Map<String, double>? rawAiResult;
  final bool fromHistory;
  final String? scanId;

  const ResultsScreen({
    super.key,
    required this.imagePath,
    required this.results,
    this.rawAiResult,
    this.fromHistory = false,
    this.scanId,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late String? _currentScanId;

  // State variables to allow UI updates
  late Map<String, double> _rawAiResults;

  @override
  void initState() {
    super.initState();
    _currentScanId = widget.scanId;

    // If raw data isn't passed, assume current results are raw
    _rawAiResults = widget.rawAiResult ?? widget.results;

    if (!widget.fromHistory) {
      _saveNewScan();
    }
  }

  Future<void> _saveNewScan() async {
    // Save and capture the generated ID
    final id = await HistoryRepository().addScan(
      imagePath: widget.imagePath,
      results: widget.results,
      rawAiResults: _rawAiResults,
    );
    if (mounted) {
      setState(() {
        _currentScanId = id;
      });
    }
  }

  Future<void> _confirmDelete() async {
    if (_currentScanId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text('Are you sure you want to delete this scan result? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Delete from db
      await HistoryRepository().deleteScan(_currentScanId!);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan deleted successfully')),
        );

        // Navigate back
        // If from History, go back to list. If fresh, go Home.
        if (widget.fromHistory) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }
  // Logic to open Questionnaire
  Future<void> _openQuestionnaire() async {
    // Navigate and wait for result
    final newScores = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireScreen(
          aiResults: _rawAiResults, // pass the RAW AI results
          imagePath: widget.imagePath,
        ),
      ),
    );

    // If we got data back (User clicked Finish)
    if (newScores != null && mounted) {
      setState(() {
      // Update UI immediately
      });

      // Update Database Entry (if it exists)
      if (_currentScanId != null) {
        await HistoryRepository().updateScanResult(
            _currentScanId!,
            newScores
        );
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Results updated with questionnaire data')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort results for display
    final sortedEntries = widget.results.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topResult = sortedEntries.isNotEmpty ? sortedEntries.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.fromHistory) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        // DELETE BUTTON ACTION
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
            tooltip: 'Delete Scan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE HEADER
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(color: Colors.grey),
                  ),
                ),
                Positioned(
                  bottom: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.fromHistory ? 'Previous Scan' : 'Current Scan',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // RESULT CONTENT
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (topResult != null) ...[
                    Text('Primary Detection:', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      cleanKey(topResult.key),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // LIST OF CONFIDENCE BARS
                  ...sortedEntries.map((entry) => _ResultRow(
                    label: cleanKey(entry.key),
                    confidence: entry.value,
                    isHighlight: entry == topResult,
                  )),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // QUESTIONNAIRE BUTTON
                  OutlinedButton.icon(
                    onPressed: _openQuestionnaire,
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Answer Questions to Improve Accuracy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

class _ResultRow extends StatelessWidget {
  final String label;
  final double confidence;
  final bool isHighlight;

  const _ResultRow({required this.label, required this.confidence, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: TextStyle(fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: isHighlight ? Theme.of(context).primaryColor : Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: isHighlight ? Theme.of(context).primaryColor : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}