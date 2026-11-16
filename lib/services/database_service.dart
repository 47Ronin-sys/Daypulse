import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../models/outage_models.dart';
import '../models/traffic_jam_record.dart';
import '../models/traffic_status.dart';

class DatabaseService {
  static const String _boxTodos = 'daypulse_todos';
  static const String _boxRecordedOutages = 'daypulse_recorded_outages';
  static const String _boxPlannedOutages = 'daypulse_planned_outages';
  static const String _boxTrafficJams = 'daypulse_traffic_jams';
  static const String _boxSettings = 'daypulse_settings';

  late Box _todosBox;
  late Box _recordedOutagesBox;
  late Box _plannedOutagesBox;
  late Box _trafficJamsBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    _todosBox = await Hive.openBox(_boxTodos);
    _recordedOutagesBox = await Hive.openBox(_boxRecordedOutages);
    _plannedOutagesBox = await Hive.openBox(_boxPlannedOutages);
    _trafficJamsBox = await Hive.openBox(_boxTrafficJams);
    _settingsBox = await Hive.openBox(_boxSettings);

    final isSeeded = _settingsBox.get('is_seeded', defaultValue: false);
    if (!isSeeded) {
      await _seedInitialData();
      await _settingsBox.put('is_seeded', true);
    }
  }

  Future<void> _seedInitialData() async {
    final now = DateTime.now();

    // 1. Initial Todos tailored for Kenyan remote workers
    final initialTodos = [
      TodoItem(
        id: const Uuid().v4(),
        title: 'Review Pull Request & Deploy',
        description: 'Complete code review before afternoon team standup',
        priority: 'High',
        category: 'Work',
        dueDate: now.add(const Duration(hours: 4)),
        isCompleted: false,
      ),
      TodoItem(
        id: const Uuid().v4(),
        title: 'Top up backup power & test UPS',
        description: 'Ensure internet router UPS and laptop power bank are at 100%',
        priority: 'High',
        category: 'Urgent',
        dueDate: now.add(const Duration(hours: 2)),
        isCompleted: true,
      ),
      TodoItem(
        id: const Uuid().v4(),
        title: 'Client Sprint Retrospective call',
        description: 'Zoom call with distributed engineering team',
        priority: 'Medium',
        category: 'Work',
        dueDate: now.add(const Duration(hours: 6)),
        isCompleted: false,
      ),
      TodoItem(
        id: const Uuid().v4(),
        title: 'Grocery shopping after traffic clears',
        description: 'Pick up groceries along Waiyaki Way',
        priority: 'Low',
        category: 'Personal',
        dueDate: now.add(const Duration(hours: 10)),
        isCompleted: false,
      ),
    ];
    for (final todo in initialTodos) {
      await saveTodo(todo);
    }

    // 2. Initial Planned Outages (KPLC context for Kenya)
    final initialPlannedOutages = [
      PlannedOutage(
        id: const Uuid().v4(),
        area: 'Westlands & Parklands',
        county: 'Nairobi',
        date: now.add(const Duration(days: 1)),
        timeWindow: '9:00 AM - 5:00 PM',
        locationsAffected: 'Sarit Centre, Mpaka Road, Woodvale Grove, Parklands Road, part of Lower Kabete',
        source: 'KPLC Scheduled Maintenance Notice',
      ),
      PlannedOutage(
        id: const Uuid().v4(),
        area: 'Kilimani & Kileleshwa',
        county: 'Nairobi',
        date: now.add(const Duration(days: 3)),
        timeWindow: '9:00 AM - 4:30 PM',
        locationsAffected: 'Argwings Kodhek Rd, Denis Pritt Rd, Kasuku Centre, Cotton Ave',
        source: 'KPLC Scheduled Maintenance Notice',
      ),
    ];
    for (final outage in initialPlannedOutages) {
      await addPlannedOutage(outage);
    }

    // 3. Initial Past Outage History
    final initialRecorded = RecordedOutage(
      id: const Uuid().v4(),
      startTime: now.subtract(const Duration(days: 2, hours: 3)),
      endTime: now.subtract(const Duration(days: 2)),
      durationMinutes: 180,
      location: 'Kilimani, Nairobi',
      notes: 'Unscheduled feeder trip during thunderstorm. Restored by KPLC.',
      isOngoing: false,
    );
    await _recordedOutagesBox.put(initialRecorded.id, initialRecorded.toMap());

    // 4. Initial Office Location
    final defaultOffice = OfficeLocation(
      name: 'Westlands Tech Hub',
      address: 'Delta Towers, Waiyaki Way, Nairobi',
      typicalMinutes: 25,
    );
    await setOfficeLocation(defaultOffice);

    // 5. Initial Past Traffic Jam Record
    final initialJam = TrafficJamRecord(
      id: const Uuid().v4(),
      startTime: now.subtract(const Duration(days: 1, hours: 2)),
      endTime: now.subtract(const Duration(days: 1, hours: 1, minutes: 20)),
      durationMinutes: 40,
      location: 'Waiyaki Way near ABC Place',
      severity: 'Standstill',
      notes: 'Evening peak hour gridlock heading towards Kangemi.',
      isOngoing: false,
    );
    await _trafficJamsBox.put(initialJam.id, initialJam.toMap());

    // 6. Settings defaults
    await _settingsBox.put('is_fahrenheit', false);
    await _settingsBox.put('city_name', 'Nairobi, Kenya');
    await _settingsBox.put('latitude', -1.286389);
    await _settingsBox.put('longitude', 36.817223);
  }

  // -------------------------
  // TODOS CRUD
  // -------------------------
  List<TodoItem> getTodos() {
    final list = <TodoItem>[];
    for (final key in _todosBox.keys) {
      final val = _todosBox.get(key);
      if (val is Map) {
        list.add(TodoItem.fromMap(val));
      }
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveTodo(TodoItem item) async {
    await _todosBox.put(item.id, item.toMap());
  }

  Future<void> deleteTodo(String id) async {
    await _todosBox.delete(id);
  }

  Future<void> toggleTodoComplete(String id) async {
    final val = _todosBox.get(id);
    if (val is Map) {
      final todo = TodoItem.fromMap(val);
      final updated = todo.copyWith(isCompleted: !todo.isCompleted);
      await _todosBox.put(id, updated.toMap());
    }
  }

  // -------------------------
  // RECORDED OUTAGES CRUD
  // -------------------------
  List<RecordedOutage> getRecordedOutages() {
    final list = <RecordedOutage>[];
    for (final key in _recordedOutagesBox.keys) {
      final val = _recordedOutagesBox.get(key);
      if (val is Map) {
        list.add(RecordedOutage.fromMap(val));
      }
    }
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  RecordedOutage? getActiveOutage() {
    for (final key in _recordedOutagesBox.keys) {
      final val = _recordedOutagesBox.get(key);
      if (val is Map) {
        final outage = RecordedOutage.fromMap(val);
        if (outage.isOngoing) {
          return outage;
        }
      }
    }
    return null;
  }

  Future<RecordedOutage> startOutage({
    required String location,
    String notes = '',
  }) async {
    final id = const Uuid().v4();
    final newOutage = RecordedOutage(
      id: id,
      startTime: DateTime.now(),
      location: location,
      notes: notes,
      isOngoing: true,
    );
    await _recordedOutagesBox.put(id, newOutage.toMap());
    return newOutage;
  }

  Future<RecordedOutage?> endOutage(String id) async {
    final val = _recordedOutagesBox.get(id);
    if (val is Map) {
      final current = RecordedOutage.fromMap(val);
      final now = DateTime.now();
      final duration = now.difference(current.startTime).inMinutes;

      final updated = current.copyWith(
        endTime: now,
        durationMinutes: duration > 0 ? duration : 1,
        isOngoing: false,
      );
      await _recordedOutagesBox.put(id, updated.toMap());
      return updated;
    }
    return null;
  }

  Future<void> deleteRecordedOutage(String id) async {
    await _recordedOutagesBox.delete(id);
  }

  // -------------------------
  // PLANNED OUTAGES CRUD
  // -------------------------
  List<PlannedOutage> getPlannedOutages() {
    final list = <PlannedOutage>[];
    for (final key in _plannedOutagesBox.keys) {
      final val = _plannedOutagesBox.get(key);
      if (val is Map) {
        list.add(PlannedOutage.fromMap(val));
      }
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> addPlannedOutage(PlannedOutage outage) async {
    await _plannedOutagesBox.put(outage.id, outage.toMap());
  }

  Future<void> deletePlannedOutage(String id) async {
    await _plannedOutagesBox.delete(id);
  }

  // -------------------------
  // TRAFFIC JAMS RECORD CRUD
  // -------------------------
  List<TrafficJamRecord> getTrafficJams() {
    final list = <TrafficJamRecord>[];
    for (final key in _trafficJamsBox.keys) {
      final val = _trafficJamsBox.get(key);
      if (val is Map) {
        list.add(TrafficJamRecord.fromMap(val));
      }
    }
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  TrafficJamRecord? getActiveTrafficJam() {
    for (final key in _trafficJamsBox.keys) {
      final val = _trafficJamsBox.get(key);
      if (val is Map) {
        final jam = TrafficJamRecord.fromMap(val);
        if (jam.isOngoing) {
          return jam;
        }
      }
    }
    return null;
  }

  Future<TrafficJamRecord> startTrafficJam({
    required String location,
    String severity = 'Heavy',
    String notes = '',
  }) async {
    final id = const Uuid().v4();
    final newJam = TrafficJamRecord(
      id: id,
      startTime: DateTime.now(),
      location: location,
      severity: severity,
      notes: notes,
      isOngoing: true,
    );
    await _trafficJamsBox.put(id, newJam.toMap());
    return newJam;
  }

  Future<TrafficJamRecord?> endTrafficJam(String id) async {
    final val = _trafficJamsBox.get(id);
    if (val is Map) {
      final current = TrafficJamRecord.fromMap(val);
      final now = DateTime.now();
      final duration = now.difference(current.startTime).inMinutes;

      final updated = current.copyWith(
        endTime: now,
        durationMinutes: duration > 0 ? duration : 1,
        isOngoing: false,
      );
      await _trafficJamsBox.put(id, updated.toMap());
      return updated;
    }
    return null;
  }

  Future<void> deleteTrafficJam(String id) async {
    await _trafficJamsBox.delete(id);
  }

  // -------------------------
  // OFFICE LOCATION & SETTINGS
  // -------------------------
  OfficeLocation getOfficeLocation() {
    final val = _settingsBox.get('office_location');
    if (val is Map) {
      return OfficeLocation.fromMap(val);
    }
    return OfficeLocation(
      name: 'Westlands Tech Hub',
      address: 'Delta Towers, Waiyaki Way, Nairobi',
      typicalMinutes: 25,
    );
  }

  Future<void> setOfficeLocation(OfficeLocation office) async {
    await _settingsBox.put('office_location', office.toMap());
  }

  bool isFahrenheit() {
    return _settingsBox.get('is_fahrenheit', defaultValue: false) == true;
  }

  Future<void> setFahrenheit(bool val) async {
    await _settingsBox.put('is_fahrenheit', val);
  }

  String getCityName() {
    return _settingsBox.get('city_name', defaultValue: 'Nairobi, Kenya');
  }

  double getLatitude() {
    return (_settingsBox.get('latitude', defaultValue: -1.286389) as num).toDouble();
  }

  double getLongitude() {
    return (_settingsBox.get('longitude', defaultValue: 36.817223) as num).toDouble();
  }

  Future<void> setLocation({
    required String name,
    required double lat,
    required double lon,
  }) async {
    await _settingsBox.put('city_name', name);
    await _settingsBox.put('latitude', lat);
    await _settingsBox.put('longitude', lon);
  }

  bool isDarkMode() {
    return _settingsBox.get('is_dark_mode', defaultValue: false) == true;
  }

  Future<void> setDarkMode(bool val) async {
    await _settingsBox.put('is_dark_mode', val);
  }
}
