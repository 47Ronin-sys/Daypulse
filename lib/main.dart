import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/weather_service.dart';
import 'screens/home_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/outage_screen.dart';
import 'screens/traffic_screen.dart';
import 'screens/record_traffic_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(DayPulseApp(databaseService: databaseService));
}

class DayPulseApp extends StatelessWidget {
  final DatabaseService databaseService;

  DayPulseApp({super.key, required this.databaseService});

  final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier(ThemeMode.system);

  @override
  Widget build(BuildContext context) {
    if (databaseService.isDarkMode()) {
      _themeModeNotifier.value = ThemeMode.dark;
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'DayPulse',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF0F766E), // Teal-cyan for Kenya pulse
            brightness: Brightness.light,
            cardTheme: const CardThemeData(
              elevation: 0.5,
              margin: EdgeInsets.zero,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF14B8A6),
            brightness: Brightness.dark,
            cardTheme: const CardThemeData(
              elevation: 0.5,
              margin: EdgeInsets.zero,
            ),
          ),
          home: MainNavigationContainer(
            databaseService: databaseService,
            themeModeNotifier: _themeModeNotifier,
          ),
        );
      },
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  final DatabaseService databaseService;
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const MainNavigationContainer({
    super.key,
    required this.databaseService,
    required this.themeModeNotifier,
  });

  @override
  State<MainNavigationContainer> createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;
  final WeatherService _weatherService = WeatherService();

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openRecordTrafficScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RecordTrafficScreen(
          databaseService: widget.databaseService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        databaseService: widget.databaseService,
        weatherService: _weatherService,
        onNavigateTab: _navigateToTab,
        onOpenRecordJam: _openRecordTrafficScreen,
      ),
      TodoScreen(databaseService: widget.databaseService),
      OutageScreen(databaseService: widget.databaseService),
      TrafficScreen(
        databaseService: widget.databaseService,
        onOpenRecordJam: _openRecordTrafficScreen,
      ),
      SettingsScreen(
        databaseService: widget.databaseService,
        weatherService: _weatherService,
        themeModeNotifier: widget.themeModeNotifier,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'To-Do',
          ),
          NavigationDestination(
            icon: Icon(Icons.flash_on_outlined),
            selectedIcon: Icon(Icons.flash_on_rounded),
            label: 'Outages',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Traffic',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
