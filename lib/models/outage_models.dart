import 'dart:convert';

class RecordedOutage {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String location;
  final String notes;
  final bool isOngoing;

  RecordedOutage({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.location,
    this.notes = '',
    this.isOngoing = false,
  });

  RecordedOutage copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? location,
    String? notes,
    bool? isOngoing,
  }) {
    return RecordedOutage(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
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
      'notes': notes,
      'isOngoing': isOngoing,
    };
  }

  factory RecordedOutage.fromMap(Map<dynamic, dynamic> map) {
    return RecordedOutage(
      id: map['id']?.toString() ?? '',
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.tryParse(map['endTime'].toString()) : null,
      durationMinutes: map['durationMinutes'] is int
          ? map['durationMinutes'] as int
          : int.tryParse(map['durationMinutes']?.toString() ?? ''),
      location: map['location']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      isOngoing: map['isOngoing'] == true,
    );
  }

  String toJson() => json.encode(toMap());
  factory RecordedOutage.fromJson(String source) => RecordedOutage.fromMap(json.decode(source));
}

class PlannedOutage {
  final String id;
  final String area;
  final String county;
  final DateTime date;
  final String timeWindow; // e.g. "9:00 AM - 5:00 PM"
  final String locationsAffected;
  final String source; // e.g. "KPLC Weekly Notice"

  PlannedOutage({
    required this.id,
    required this.area,
    this.county = 'Nairobi',
    required this.date,
    required this.timeWindow,
    required this.locationsAffected,
    this.source = 'KPLC Notice',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'area': area,
      'county': county,
      'date': date.toIso8601String(),
      'timeWindow': timeWindow,
      'locationsAffected': locationsAffected,
      'source': source,
    };
  }

  factory PlannedOutage.fromMap(Map<dynamic, dynamic> map) {
    return PlannedOutage(
      id: map['id']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      county: map['county']?.toString() ?? 'Nairobi',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      timeWindow: map['timeWindow']?.toString() ?? '9:00 AM - 5:00 PM',
      locationsAffected: map['locationsAffected']?.toString() ?? '',
      source: map['source']?.toString() ?? 'KPLC Notice',
    );
  }

  String toJson() => json.encode(toMap());
  factory PlannedOutage.fromJson(String source) => PlannedOutage.fromMap(json.decode(source));
}
