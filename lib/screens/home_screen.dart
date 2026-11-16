import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_models.dart';
import '../models/todo_item.dart';
import '../models/outage_models.dart';
import '../models/traffic_jam_record.dart';
import '../models/traffic_status.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final WeatherService weatherService;
  final Function(int) onNavigateTab;
  final VoidCallback onOpenRecordJam;

  const HomeScreen({
    super.key,
    required this.databaseService,
    required this.weatherService,
    required this.onNavigateTab,
    required this.onOpenRecordJam,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  bool _isLoadingWeather = false;
  bool _isFahrenheit = false;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  List<TodoItem> _todos = [];
  RecordedOutage? _activeOutage;
  List<PlannedOutage> _plannedOutages = [];
  TrafficJamRecord? _activeTrafficJam;
  late OfficeLocation _officeLocation;

  @override
  void initState() {
    super.initState();
    _isFahrenheit = widget.databaseService.isFahrenheit();
    _loadLocalData();
    _fetchWeather();

    // Live clock update every 30 seconds
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _loadLocalData() {
    setState(() {
      _todos = widget.databaseService.getTodos();
      _activeOutage = widget.databaseService.getActiveOutage();
      _plannedOutages = widget.databaseService.getPlannedOutages();
      _activeTrafficJam = widget.databaseService.getActiveTrafficJam();
      _officeLocation = widget.databaseService.getOfficeLocation();
      _isFahrenheit = widget.databaseService.isFahrenheit();
    });
  }

  Future<void> _fetchWeather() async {
    setState(() => _isLoadingWeather = true);
    final cityName = widget.databaseService.getCityName();
    final lat = widget.databaseService.getLatitude();
    final lon = widget.databaseService.getLongitude();

    final data = await widget.weatherService.fetchWeather(
      cityName: cityName,
      latitude: lat,
      longitude: lon,
    );

    if (mounted) {
      setState(() {
        _weather = data;
        _isLoadingWeather = false;
      });
    }
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Future<void> _toggleTemperatureUnit(bool toFahrenheit) async {
    await widget.databaseService.setFahrenheit(toFahrenheit);
    setState(() {
      _isFahrenheit = toFahrenheit;
    });
  }

  int get _pendingTodosCount => _todos.where((t) => !t.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();
    final timeStr = DateFormat('EEEE, d MMM • h:mm a').format(_currentTime);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'DayPulse',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => widget.onNavigateTab(4), // Navigate to settings
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadLocalData();
          await _fetchWeather();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Greeting & Current Time
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting 👋',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          timeStr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Weather Card with °C / °F Toggle
              _buildWeatherCard(theme),
              const SizedBox(height: 16),

              // 3. Live Alert Banners (Active Outage or Active Traffic Jam)
              if (_activeOutage != null) ...[
                _buildActiveOutageBanner(theme),
                const SizedBox(height: 12),
              ],
              if (_activeTrafficJam != null) ...[
                _buildActiveTrafficJamBanner(theme),
                const SizedBox(height: 12),
              ],

              // 4. Section Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Daily Planner & Controls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 5. Large Tappable Navigation Cards
              _buildLargeCard(
                context: context,
                icon: Icons.checklist_rounded,
                iconColor: Colors.blueAccent,
                title: 'To-Do List',
                subtitle: _pendingTodosCount == 0
                    ? 'All tasks completed! Great job.'
                    : '$_pendingTodosCount tasks pending for today',
                badgeText: '$_pendingTodosCount Pending',
                badgeColor: _pendingTodosCount > 0 ? Colors.blueAccent : Colors.green,
                onTap: () => widget.onNavigateTab(1),
              ),
              const SizedBox(height: 12),

              _buildLargeCard(
                context: context,
                icon: Icons.flash_on_rounded,
                iconColor: _activeOutage != null ? Colors.redAccent : Colors.amber.shade800,
                title: 'Power Outages',
                subtitle: _activeOutage != null
                    ? 'LIVE BLACKOUT recorded in ${_activeOutage!.location}'
                    : '${_plannedOutages.length} planned KPLC maintenance notices',
                badgeText: _activeOutage != null ? 'Blackout Active' : 'Grid Online',
                badgeColor: _activeOutage != null ? Colors.redAccent : Colors.teal,
                onTap: () => widget.onNavigateTab(2),
              ),
              const SizedBox(height: 12),

              _buildLargeCard(
                context: context,
                icon: Icons.directions_car_rounded,
                iconColor: Colors.indigoAccent,
                title: 'Traffic & Office Route',
                subtitle: 'To ${_officeLocation.name} (~${_officeLocation.typicalMinutes} mins)',
                badgeText: 'Clear / Normal',
                badgeColor: Colors.green,
                onTap: () => widget.onNavigateTab(3),
              ),
              const SizedBox(height: 12),

              _buildLargeCard(
                context: context,
                icon: Icons.traffic_rounded,
                iconColor: Colors.deepOrangeAccent,
                title: 'Record Traffic Jam',
                subtitle: _activeTrafficJam != null
                    ? 'Recording jam in ${_activeTrafficJam!.location}...'
                    : 'One-tap logger: mark gridlocks & measure downtime',
                badgeText: _activeTrafficJam != null ? 'Recording' : 'Quick Log',
                badgeColor: _activeTrafficJam != null ? Colors.redAccent : Colors.deepOrangeAccent,
                isHighlighted: _activeTrafficJam != null,
                onTap: widget.onOpenRecordJam,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Weather Card Widget
  Widget _buildWeatherCard(ThemeData theme) {
    final weather = _weather ?? WeatherData.nairobiDefault();
    final tempStr = WeatherData.formatTemp(weather.temperatureC, _isFahrenheit);
    final apparentStr = WeatherData.formatTemp(weather.apparentTemperatureC, _isFahrenheit);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceVariant,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Row 1: City + Unit Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    weather.cityName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (_isLoadingWeather) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              // Segmented Toggle for °C vs °F
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnitTab(
                      label: '°C',
                      isSelected: !_isFahrenheit,
                      onTap: () => _toggleTemperatureUnit(false),
                      theme: theme,
                    ),
                    _buildUnitTab(
                      label: '°F',
                      isSelected: _isFahrenheit,
                      onTap: () => _toggleTemperatureUnit(true),
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: Big Temperature + Condition Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: weather.conditionColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  weather.conditionIcon,
                  color: weather.conditionColor,
                  size: 38,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tempStr,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      '${weather.conditionText} • Feels like $apparentStr',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 3: Quick metrics (Rain probability, Wind, Humidity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMiniMetric(
                  icon: Icons.water_drop_rounded,
                  label: '${weather.precipitationProbability}% Rain',
                  color: Colors.blueAccent,
                ),
                _buildWeatherMiniMetric(
                  icon: Icons.air_rounded,
                  label: '${weather.windSpeedKmh.round()} km/h',
                  color: Colors.teal,
                ),
                _buildWeatherMiniMetric(
                  icon: Icons.opacity_rounded,
                  label: '${weather.humidity}% Hum',
                  color: Colors.indigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMiniMetric({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Active Outage Banner
  Widget _buildActiveOutageBanner(ThemeData theme) {
    final diff = DateTime.now().difference(_activeOutage!.startTime);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final elapsedStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return InkWell(
      onTap: () => widget.onNavigateTab(2),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade400, width: 1.5),
        ),
        child: Row(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE POWER OUTAGE IN PROGRESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Location: ${_activeOutage!.location} • Running for $elapsedStr',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () => widget.onNavigateTab(2),
              child: const Text('End Outage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // Active Traffic Jam Banner
  Widget _buildActiveTrafficJamBanner(ThemeData theme) {
    final diff = DateTime.now().difference(_activeTrafficJam!.startTime);
    final mins = diff.inMinutes;

    return InkWell(
      onTap: widget.onOpenRecordJam,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade900.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepOrange.shade400, width: 1.5),
        ),
        child: Row(
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
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_activeTrafficJam!.location} • $mins mins recorded',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // Large Tappable Navigation Card
  Widget _buildLargeCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? Colors.deepOrangeAccent
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: isHighlighted ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
