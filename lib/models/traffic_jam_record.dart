import 'dart:convert';

class TrafficJamRecord {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String location;
  final String severity; // 'Standstill', 'Heavy', 'Crawling'
  final String notes;
  final bool isOngoing;

  TrafficJamRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.location,
    this.severity = 'Heavy',
    this.notes = '',
    this.isOngoing = false,
  });

  TrafficJamRecord copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? location,
    String? severity,
    String? notes,
    bool? isOngoing,
  }) {
    return TrafficJamRecord(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      isOngoing: isOngoing ?? this.isOngoing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'location': location,
      'severity': severity,
      'notes': notes,
      'isOngoing': isOngoing,
    };
  }

  factory TrafficJamRecord.fromMap(Map<dynamic, dynamic> map) {
    return TrafficJamRecord(
      id: map['id']?.toString() ?? '',
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.tryParse(map['endTime'].toString()) : null,
      durationMinutes: map['durationMinutes'] is int
          ? map['durationMinutes'] as int
          : int.tryParse(map['durationMinutes']?.toString() ?? ''),
      location: map['location']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'Heavy',
      notes: map['notes']?.toString() ?? '',
      isOngoing: map['isOngoing'] == true,
    );
  }

  String toJson() => json.encode(toMap());
  factory TrafficJamRecord.fromJson(String source) => TrafficJamRecord.fromMap(json.decode(source));
}
