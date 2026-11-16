import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/traffic_jam_record.dart';
import '../services/database_service.dart';

class RecordTrafficScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const RecordTrafficScreen({super.key, required this.databaseService});

  @override
  State<RecordTrafficScreen> createState() => _RecordTrafficScreenState();
}

class _RecordTrafficScreenState extends State<RecordTrafficScreen> {
  TrafficJamRecord? _activeJam;
  List<TrafficJamRecord> _historyJams = [];
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeJam != null && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_activeJam!.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _activeJam = widget.databaseService.getActiveTrafficJam();
      _historyJams = widget.databaseService
          .getTrafficJams()
          .where((j) => !j.isOngoing)
          .toList();

      if (_activeJam != null) {
        _elapsed = DateTime.now().difference(_activeJam!.startTime);
      } else {
        _elapsed = Duration.zero;
      }
    });
  }

  int get _totalJamMinutes {
    return _historyJams.fold<int>(0, (sum, j) => sum + (j.durationMinutes ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHoursStuck = (_totalJamMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Traffic Jam', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Traffic Jam Recording Card
            _buildLiveJamRecorderCard(theme),
            const SizedBox(height: 24),

            // 2. Summary Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_historyJams.length}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text('Jams Logged', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade400),
                  Column(
                    children: [
                      Text(
                        '${totalHoursStuck}h',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                      const Text('Total Delay Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 3. History List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recorded Jams History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_historyJams.length} records',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4. History List
            if (_historyJams.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.traffic_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text('No traffic jams recorded yet', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Whenever you are stuck in a gridlock, tap "Start Recording" above.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ..._historyJams.map((jam) {
                final severityColor = _getSeverityColor(jam.severity);
                final durationText = jam.durationMinutes != null
                    ? '${jam.durationMinutes} mins delay'
                    : 'Duration not calculated';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.traffic_rounded, color: severityColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      jam.location,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: severityColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      jam.severity,
                                      style: TextStyle(
                                        color: severityColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    durationText,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('MMM d, h:mm a').format(jam.startTime)}${jam.endTime != null ? ' - ${DateFormat('h:mm a').format(jam.endTime!)}' : ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              if (jam.notes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  jam.notes,
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () async {
                            await widget.databaseService.deleteTrafficJam(jam.id);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Live Jam Recorder Card
  Widget _buildLiveJamRecorderCard(ThemeData theme) {
    final bool isJamming = _activeJam != null;

    if (isJamming) {
      final hours = _elapsed.inHours;
      final minutes = _elapsed.inMinutes % 60;
      final seconds = _elapsed.inSeconds % 60;
      final timerStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade900.withOpacity(0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.deepOrange.shade400, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.traffic, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECORDING TRAFFIC JAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Location: ${_activeJam!.location} (${_activeJam!.severity})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Timer
            Text(
              timerStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Started at ${DateFormat('h:mm a').format(_activeJam!.startTime)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Big "End Recording" Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepOrange.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: const Text(
                  'End Recording (Traffic Cleared)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _confirmEndJam(_activeJam!.id),
              ),
            ),
          ],
        ),
      );
    }

    // Normal State with "Start Recording" Button
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.traffic_rounded, color: Colors.deepOrange, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-Time Jam Logger',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Hit the button as soon as you hit gridlock',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Large "Start Recording" Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text(
                'Start Recording Traffic Jam',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _showStartJamDialog,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'standstill':
        return Colors.red.shade900;
      case 'heavy':
        return Colors.deepOrange;
      case 'crawling':
        return Colors.amber.shade800;
      default:
        return Colors.orange;
    }
  }

  void _showStartJamDialog() {
    final locationController = TextEditingController(text: 'Waiyaki Way near ABC Place');
    final notesController = TextEditingController();
    String severity = 'Heavy';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.traffic, color: Colors.deepOrange),
                  SizedBox(width: 8),
                  Text('Start Traffic Jam Log'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mark location and jam severity:'),
                  const SizedBox(height: 14),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Road *',
                      hintText: 'e.g. Thika Superhighway near Roysambu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: severity,
                    decoration: const InputDecoration(
                      labelText: 'Jam Severity',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Standstill', child: Text('Standstill (Complete stop)')),
                      DropdownMenuItem(value: 'Heavy', child: Text('Heavy (Stop & Go)')),
                      DropdownMenuItem(value: 'Crawling', child: Text('Crawling (Slow moving)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => severity = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'e.g. stalled bus, road work, rain',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                  onPressed: () async {
                    if (locationController.text.trim().isEmpty) return;
                    await widget.databaseService.startTrafficJam(
                      location: locationController.text.trim(),
                      severity: severity,
                      notes: notesController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadData();
                    }
                  },
                  child: const Text('Start Timer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmEndJam(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Traffic Cleared?'),
          content: const Text(
            'This will stop the timer and automatically record your total delay duration and location to your history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.databaseService.endTrafficJam(id);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Traffic jam saved to history!')),
                  );
                }
              },
              child: const Text('Confirm End'),
            ),
          ],
        );
      },
    );
  }
}
