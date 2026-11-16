import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/outage_models.dart';
import '../services/database_service.dart';

class OutageScreen extends StatefulWidget {
  final DatabaseService databaseService;

  const OutageScreen({super.key, required this.databaseService});

  @override
  State<OutageScreen> createState() => _OutageScreenState();
}

class _OutageScreenState extends State<OutageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RecordedOutage? _activeOutage;
  List<RecordedOutage> _historyOutages = [];
  List<PlannedOutage> _plannedOutages = [];
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeOutage != null && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_activeOutage!.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _activeOutage = widget.databaseService.getActiveOutage();
      _historyOutages = widget.databaseService
          .getRecordedOutages()
          .where((o) => !o.isOngoing)
          .toList();
      _plannedOutages = widget.databaseService.getPlannedOutages();

      if (_activeOutage != null) {
        _elapsed = DateTime.now().difference(_activeOutage!.startTime);
      } else {
        _elapsed = Duration.zero;
      }
    });
  }

  int get _totalDowntimeMinutes {
    return _historyOutages.fold<int>(0, (sum, o) => sum + (o.durationMinutes ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Outages', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Planned Outages (${_plannedOutages.length})'),
            Tab(text: 'Outage History (${_historyOutages.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Prominent Live Outage Recorder Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLiveRecorderCard(theme),
          ),

          // 2. Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlannedOutagesTab(theme),
                _buildHistoryTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Live Outage Recorder Widget
  Widget _buildLiveRecorderCard(ThemeData theme) {
    final bool isOut = _activeOutage != null;

    if (isOut) {
      final hours = _elapsed.inHours;
      final minutes = _elapsed.inMinutes % 60;
      final seconds = _elapsed.inSeconds % 60;
      final timerStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.red.shade400, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_off, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POWER OUTAGE ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Live downtime tracking in progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Timer Display
            Center(
              child: Column(
                children: [
                  Text(
                    timerStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Started at ${DateFormat('h:mm a').format(_activeOutage!.startTime)} • ${_activeOutage!.location}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Big "End Outage" Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.power, size: 24),
                label: const Text(
                  'End Outage (Power Restored)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _confirmEndOutage(_activeOutage!.id),
              ),
            ),
          ],
        ),
      );
    }

    // Grid Online state with "Start Outage" button
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
                  color: Colors.teal.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.teal, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Power Grid: Normal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'No active blackouts recorded',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Large "Start Outage" Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.flash_off_rounded, size: 22),
              label: const Text(
                'Start Outage (Lights Went Out)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _showStartOutageDialog,
            ),
          ),
        ],
      ),
    );
  }

  // Planned Outages Tab
  Widget _buildPlannedOutagesTab(ThemeData theme) {
    return Column(
      children: [
        // Official Notice Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade900.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade700.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note: Automatic fetching from official KPLC PDF notices will be added in a future version. You can manually record or add planned schedules below.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Planned Outages List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KPLC Maintenance Notices',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Notice'),
                onPressed: _showAddPlannedOutageDialog,
              ),
            ],
          ),
        ),

        Expanded(
          child: _plannedOutages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No planned outages scheduled', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _plannedOutages.length,
                  itemBuilder: (context, index) {
                    final item = _plannedOutages[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade800.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.area,
                                    style: TextStyle(
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('EEE, MMM d').format(item.date),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                  onPressed: () async {
                                    await widget.databaseService.deletePlannedOutage(item.id);
                                    _loadData();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Time Window: ${item.timeWindow}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (item.locationsAffected.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Affected: ${item.locationsAffected}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // History Tab
  Widget _buildHistoryTab(ThemeData theme) {
    final totalHours = (_totalDowntimeMinutes / 60).toStringAsFixed(1);

    return Column(
      children: [
        // Stats Summary Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    '${_historyOutages.length}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text('Recorded Outages', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.grey.shade400),
              Column(
                children: [
                  Text(
                    '${totalHours}h',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  const Text('Total Lost Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: _historyOutages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No recorded outage history yet', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _historyOutages.length,
                  itemBuilder: (context, index) {
                    final outage = _historyOutages[index];
                    final durationStr = outage.durationMinutes != null
                        ? '${outage.durationMinutes} mins'
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_off, color: Colors.red, size: 20),
                        ),
                        title: Text(
                          '${outage.location} • $durationStr',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${DateFormat('MMM d, h:mm a').format(outage.startTime)}${outage.endTime != null ? ' - ${DateFormat('h:mm a').format(outage.endTime!)}' : ''}${outage.notes.isNotEmpty ? "\nNote: ${outage.notes}" : ""}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                          onPressed: () async {
                            await widget.databaseService.deleteRecordedOutage(outage.id);
                            _loadData();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showStartOutageDialog() {
    final locationController = TextEditingController(text: 'Kilimani, Nairobi');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.flash_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Start Outage Recording'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mark power outage start time in your area:'),
              const SizedBox(height: 14),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Current Location *',
                  hintText: 'e.g. Kilimani, Westlands, Rongai',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Thunderstorm, transformer trip',
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () async {
                if (locationController.text.trim().isEmpty) return;
                await widget.databaseService.startOutage(
                  location: locationController.text.trim(),
                  notes: notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Start Recording'),
            ),
          ],
        );
      },
    );
  }

  void _confirmEndOutage(String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Power Restored?'),
          content: const Text(
            'This will stop the timer and automatically record the total duration and end time to your local outage history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.databaseService.endOutage(id);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Outage ended and saved to history!')),
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

  void _showAddPlannedOutageDialog() {
    final areaController = TextEditingController(text: 'Nairobi West / South C');
    final timeController = TextEditingController(text: '9:00 AM - 5:00 PM');
    final locationsController = TextEditingController();
    DateTime pickedDate = DateTime.now().add(const Duration(days: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Planned Outage Notice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: areaController,
                    decoration: const InputDecoration(labelText: 'Area / Neighborhood *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Time Window (e.g. 9:00 AM - 5:00 PM)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationsController,
                    decoration: const InputDecoration(labelText: 'Specific Streets / Buildings', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text('Date: ${DateFormat('EEE, MMM d, yyyy').format(pickedDate)}'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: pickedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) setModalState(() => pickedDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (areaController.text.trim().isEmpty) return;
                        final notice = PlannedOutage(
                          id: const Uuid().v4(),
                          area: areaController.text.trim(),
                          date: pickedDate,
                          timeWindow: timeController.text.trim(),
                          locationsAffected: locationsController.text.trim(),
                        );
                        await widget.databaseService.addPlannedOutage(notice);
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                        }
                      },
                      child: const Text('Save Notice'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
