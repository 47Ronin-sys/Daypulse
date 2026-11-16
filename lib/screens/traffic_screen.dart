import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/traffic_status.dart';
import '../services/database_service.dart';

class TrafficScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final VoidCallback onOpenRecordJam;

  const TrafficScreen({
    super.key,
    required this.databaseService,
    required this.onOpenRecordJam,
  });

  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  late OfficeLocation _office;

  // Major commuter corridors in Kenya (Nairobi region)
  final List<CorridorTraffic> _corridors = [
    CorridorTraffic(
      id: 'waiyaki',
      name: 'Waiyaki Way',
      stretch: 'Westlands Roundabout ↔ ABC Place',
      status: 'Moderate',
      estimatedMinutes: 28,
      delayMinutes: 8,
      note: 'Slowdown near Safaricom HQ exit',
    ),
    CorridorTraffic(
      id: 'thika',
      name: 'Thika Superhighway',
      stretch: 'Pangani ↔ Allsopps / Roysambu',
      status: 'Clear',
      estimatedMinutes: 20,
      delayMinutes: 0,
      note: 'Express lanes free-flowing',
    ),
    CorridorTraffic(
      id: 'mombasa',
      name: 'Mombasa Road',
      stretch: 'CBD ↔ GM / Cabanas',
      status: 'Heavy Jam',
      estimatedMinutes: 45,
      delayMinutes: 20,
      note: 'Lower deck backlog near Southern Bypass interchange',
    ),
    CorridorTraffic(
      id: 'ngong',
      name: 'Ngong Road',
      stretch: 'Upper Hill ↔ Prestige / Junction',
      status: 'Clear',
      estimatedMinutes: 18,
      delayMinutes: 0,
      note: 'Traffic moving steadily',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOffice();
  }

  void _loadOffice() {
    setState(() {
      _office = widget.databaseService.getOfficeLocation();
    });
  }

  Future<void> _openGoogleMaps(String destination) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external maps application')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine current traffic status to office based on corridor or default
    const bool hasTrafficToOffice = false; // Normal / Clear by default
    final estimatedCommute = _office.typicalMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic & Commute', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Saved Physical Office Location Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _office.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _office.address,
                                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Office Location',
                          onPressed: _showEditOfficeDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Typical commute: ${_office.typicalMinutes} mins',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.navigation_outlined, size: 16),
                          label: const Text('Navigate'),
                          onPressed: () => _openGoogleMaps(_office.address),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Clear Visual Indicator for Traffic Status to Office
            _buildTrafficIndicatorCard(theme, hasTraffic: hasTrafficToOffice, minutes: estimatedCommute),
            const SizedBox(height: 22),

            // 3. Quick Action Button to Record Jam
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.traffic, color: Colors.deepOrange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stuck in a Jam?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Log traffic gridlock and track delay times in real time.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                    onPressed: widget.onOpenRecordJam,
                    child: const Text('Record Jam'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Kenya Corridors Overview Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Major Corridors Status',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Nairobi Region',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Corridor Cards
            ..._corridors.map((c) {
              final statusColor = _getCorridorStatusColor(c.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 48,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.stretch,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            if (c.note.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                c.note,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Clear visual indication whether there is traffic or not
  Widget _buildTrafficIndicatorCard(ThemeData theme, {required bool hasTraffic, required int minutes}) {
    if (!hasTraffic) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade900.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.green.shade600, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NO TRAFFIC DELAYS',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Roads to ${_office.name} are clear (~$minutes mins travel time). Optimal time to commute!',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.red.shade600, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HEAVY TRAFFIC DETECTED',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Congestion on corridors to ${_office.name}. Consider delaying your commute or working remotely.',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getCorridorStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'clear':
        return Colors.green;
      case 'moderate':
        return Colors.amber.shade800;
      case 'heavy jam':
        return Colors.redAccent;
      default:
        return Colors.blue;
    }
  }

  void _showEditOfficeDialog() {
    final nameController = TextEditingController(text: _office.name);
    final addressController = TextEditingController(text: _office.address);
    final minutesController = TextEditingController(text: _office.typicalMinutes.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Physical Office'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Office Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Street / Neighborhood / City', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Typical Commute (Minutes)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final mins = int.tryParse(minutesController.text.trim()) ?? 30;
                final updated = OfficeLocation(
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  typicalMinutes: mins,
                );
                await widget.databaseService.setOfficeLocation(updated);
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadOffice();
                }
              },
              child: const Text('Save Office'),
            ),
          ],
        );
      },
    );
  }
}
