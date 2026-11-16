import 'dart:convert';

class OfficeLocation {
  final String name;
  final String address;
  final int typicalMinutes;
  final DateTime updatedAt;

  OfficeLocation({
    required this.name,
    required this.address,
    this.typicalMinutes = 30,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'typicalMinutes': typicalMinutes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OfficeLocation.fromMap(Map<dynamic, dynamic> map) {
    return OfficeLocation(
      name: map['name']?.toString() ?? 'Nairobi Office',
      address: map['address']?.toString() ?? 'Upper Hill, Nairobi',
      typicalMinutes: map['typicalMinutes'] is int
          ? map['typicalMinutes'] as int
          : int.tryParse(map['typicalMinutes']?.toString() ?? '') ?? 30,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory OfficeLocation.fromJson(String source) => OfficeLocation.fromMap(json.decode(source));
}

class CorridorTraffic {
  final String id;
  final String name;
  final String stretch;
  final String status; // 'Clear', 'Moderate', 'Heavy Jam'
  final int estimatedMinutes;
  final int delayMinutes;
  final String note;

  CorridorTraffic({
    required this.id,
    required this.name,
    required this.stretch,
    required this.status,
    required this.estimatedMinutes,
    this.delayMinutes = 0,
    this.note = '',
  });

  bool get hasTraffic => status != 'Clear';
}
