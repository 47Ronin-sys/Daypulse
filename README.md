# DayPulse ⚡📅

**DayPulse** is a daily planner designed for **remote workers in Kenya** who balance high-focus professional deliverables with unpredictable real-world conditions like power blackouts, erratic Nairobi traffic, and changing weather.

Built with **Flutter (Dart)** and powered by **Hive** for an offline-first local database experience.

---

## 🌟 Core Features

### 1. Home Screen
- **Dynamic Greeting**: Time-aware greeting (*"Good morning"*, *"Good afternoon"*, *"Good evening"*) with a live date & time clock.
- **Current Weather Card**:
  - Real-time temperature & weather condition icons powered by Open-Meteo.
  - Precipitation risk, humidity, and wind speed.
  - **°C / °F Unit Switch**: Instant toggle switch between Celsius and Fahrenheit that persists in your preferences.
  - Quick location updater (defaulting to Nairobi, Kenya).
- **Active Alerts**: Real-time status badges for ongoing power blackouts or active traffic jams.
- **Large Tappable Cards**:
  1. **To-Do List**: Pending task count & direct navigation.
  2. **Power Outages**: Live grid status & KPLC maintenance notices.
  3. **Traffic**: Current commute condition to your saved office.
  4. **Record Traffic Jam**: Prominent 1-tap shortcut to log road gridlocks.

### 2. To-Do List
- Add, edit, filter, and delete tasks.
- Interactive checkboxes with instant strike-through visual feedback.
- Priorities: **High** (Red), **Medium** (Amber), and **Low** (Green).
- Filter tabs: **All**, **Pending**, and **Done**.
- Stored 100% offline in a local Hive database.

### 3. Power Outages (KPLC & Live Recorder)
- **Live Outage Recorder**:
  - Large **"Start Outage"** button when the lights go out.
  - Live duration stopwatch calculating downtime in real-time.
  - Large **"End Outage"** button when power is restored.
  - Automatically records start time, end time, duration in minutes, location, and notes into local history.
- **Planned Outages**:
  - View scheduled maintenance windows (e.g. Westlands, Parklands, Kilimani).
  - Add custom planned outage slots with date, time window, and affected streets.
  - *Note: Automatic scraping from official KPLC PDF notices will be added in a future update.*
- **Outage History**:
  - Summary metrics: Total recorded outages and cumulative downtime hours lost.

### 4. Traffic & Commute
- **Saved Physical Office**: Set your office name, street address (e.g., Delta Towers, Westlands), and typical travel minutes.
- **Clear Visual Indication**:
  - 🟢 **No Traffic Delays**: Free-flowing roads, optimal time to commute.
  - 🔴 **Heavy Traffic Detected**: High congestion warning.
- **One-Tap Google Maps Launch**: Instantly routes your commute in Google Maps.
- **Nairobi Corridors Overview**: Live status for Waiyaki Way, Thika Superhighway, Mombasa Road, and Ngong Road.

### 5. Record a Traffic Jam
- Large **"Start Recording Traffic Jam"** button as soon as you hit gridlock.
- Live elapsed stopwatch counting time spent stationary.
- Severity levels: **Standstill**, **Heavy**, and **Crawling**.
- Large **"End Recording"** button when traffic clears.
- Automatically saves start time, end time, duration, and road location into your history.
- History metrics showing total hours lost to traffic delays.

---

## 🚀 How to Build the Android APK

### Option 1: Automated Cloud Build via GitHub (Recommended — No Local Android SDK Needed)
The project includes a pre-configured GitHub Actions workflow in [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml).

1. Push this directory to your GitHub repository:
   ```bash
   cd /home/ronin/.gemini/antigravity/scratch/daypulse
   git init
   git add .
   git commit -m "feat: complete DayPulse app for Kenya remote workers"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo-name>.git
   git push -u origin main
   ```
2. Navigate to the **Actions** tab on your GitHub repo.
3. The **Build Android APK** workflow will compile the release APK automatically.
4. Download the **`DayPulse-Release-APK`** artifact and install it directly onto your Android phone!

---

### Option 2: Build Locally with Flutter CLI

```bash
cd /home/ronin/.gemini/antigravity/scratch/daypulse
flutter pub get
flutter build apk --release
```
The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📂 Project Architecture

```
daypulse/
├── .github/workflows/
│   └── build-apk.yml             # Automated GitHub Actions APK builder
├── android/                      # Native Android wrapper & Gradle config
├── lib/
│   ├── main.dart                 # App entry point, Material 3 theme & navigation
│   ├── models/
│   │   ├── todo_item.dart        # Task data model (Hive serialization)
│   │   ├── outage_models.dart    # RecordedOutage & PlannedOutage models
│   │   ├── traffic_jam_record.dart # TrafficJamRecord live model
│   │   ├── traffic_status.dart   # OfficeLocation & CorridorTraffic models
│   │   └── weather_models.dart   # Open-Meteo weather & °C/°F conversion
│   ├── services/
│   │   ├── database_service.dart # Local Hive database (CRUD & Kenya seed data)
│   │   └── weather_service.dart  # Offline-resilient weather API service
│   └── screens/
│       ├── home_screen.dart      # Greeting, clock, weather + °C/°F toggle, 4 cards
│       ├── todo_screen.dart      # Task manager with priorities & completion
│       ├── outage_screen.dart    # Live outage recorder & KPLC notices
│       ├── traffic_screen.dart   # Office commute & corridor status
│       ├── record_traffic_screen.dart # Real-time traffic jam logger & history
│       └── settings_screen.dart  # Dark mode, temperature unit, city search
└── pubspec.yaml                  # Flutter dependencies (Hive, Intl, Http, etc.)
```
