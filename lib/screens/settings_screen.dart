import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';

class SettingsScreen extends StatefulWidget {
  final DatabaseService databaseService;
  final WeatherService weatherService;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const SettingsScreen({
    super.key,
    required this.databaseService,
    required this.weatherService,
    required this.themeModeNotifier,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _cityName;
  late bool _isFahrenheit;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _cityName = widget.databaseService.getCityName();
    _isFahrenheit = widget.databaseService.isFahrenheit();
  }

  Future<void> _searchCities(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await widget.weatherService.searchCities(q);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeModeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Weather & Location
          const Text('Location & Weather', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Text('Current Location: $_cityName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search city (e.g. Nairobi, Mombasa, Kisumu)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => _searchCities(_searchController.text),
                            ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: _searchCities,
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._searchResults.map((city) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.pin_drop, size: 18),
                        title: Text('${city['name']}, ${city['country']}'),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () async {
                          await widget.databaseService.setLocation(
                            name: '${city['name']}, ${city['country']}',
                            lat: city['latitude'],
                            lon: city['longitude'],
                          );
                          setState(() {
                            _cityName = '${city['name']}, ${city['country']}';
                            _searchResults = [];
                            _searchController.clear();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Location updated to ${city['name']}')),
                            );
                          }
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Preferences (Theme & Temperature Unit)
          const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Dark Mode'),
                  subtitle: Text(isDark ? 'Dark theme enabled' : 'Light theme enabled'),
                  value: isDark,
                  onChanged: (val) {
                    widget.themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    widget.databaseService.setDarkMode(val);
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.thermostat_rounded),
                  title: const Text('Fahrenheit (°F)'),
                  subtitle: Text(_isFahrenheit ? 'Displaying °F' : 'Displaying Celsius (°C)'),
                  value: _isFahrenheit,
                  onChanged: (val) async {
                    await widget.databaseService.setFahrenheit(val);
                    setState(() {
                      _isFahrenheit = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. About
          const Text('About DayPulse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('DayPulse for Kenya Remote Workers'),
                  subtitle: Text('Version 1.0.0 (Release APK Ready)'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.flash_on),
                  title: Text('Power Outage System'),
                  subtitle: Text('Live outage logger & KPLC maintenance notices (Automatic PDF scraping planned for next update)'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('Weather Provider'),
                  subtitle: Text('Open-Meteo Global Forecasting (Offline-capable)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
