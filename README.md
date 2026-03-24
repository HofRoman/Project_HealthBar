# HealthBar - Cross-Platform Gesundheits-App

Eine vollständige Gesundheits-App geschrieben in **Flutter/Dart**.
Ein einziger Code läuft **nativ** auf allen Plattformen:

| Plattform | Status |
|-----------|--------|
| Android   | ✅ Nativ |
| iOS       | ✅ Nativ |
| Windows   | ✅ Nativ |
| macOS     | ✅ Nativ |
| Linux     | ✅ Nativ |
| Web       | ✅ Browser |

---

## Features

| Modul | Beschreibung |
|-------|-------------|
| **BMI Rechner** | Gewicht & Größe eingeben, BMI berechnen, Verlauf anzeigen |
| **Wassertracker** | Tagesaufnahme tracken, Schnell-Buttons (150/200/300/500ml), Fortschrittsbalken |
| **Aktivitäts-Tracker** | Sportarten eintragen, Kalorien & Schritte automatisch schätzen |
| **Schlaftracker** | Schlafzeit, Weckzeit und Qualität (1–5) erfassen |
| **Ernährung** | Mahlzeiten mit Kalorien, Protein, Kohlenhydraten und Fett tracken |
| **Dashboard** | Alle Tageswerte auf einen Blick mit Fortschrittsanzeigen |

---

## Installation

### 1. Flutter installieren

**Windows:**
```powershell
winget install Google.Flutter
```

**macOS:**
```bash
brew install --cask flutter
```

**Linux:**
```bash
sudo snap install flutter --classic
```

Oder manuell: https://flutter.dev/docs/get-started/install

### 2. Flutter prüfen
```bash
flutter doctor
```
Alle grünen Haken = bereit!

### 3. Projekt starten
```bash
cd health_app
flutter pub get
flutter run
```

---

## Für welche Plattform bauen?

```bash
# Android APK
flutter build apk --release

# iOS (nur auf macOS mit Xcode)
flutter build ios --release

# Windows .exe
flutter build windows --release

# macOS App
flutter build macos --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

---

## Projektstruktur

```
health_app/
├── lib/
│   ├── main.dart              # Einstiegspunkt (cross-platform init)
│   ├── app.dart               # MaterialApp mit Lokalisierung & Theme
│   ├── database/
│   │   └── database_helper.dart   # SQLite für alle Plattformen
│   ├── models/
│   │   ├── bmi_entry.dart
│   │   ├── water_entry.dart
│   │   ├── activity_entry.dart
│   │   ├── sleep_entry.dart
│   │   └── nutrition_entry.dart
│   └── screens/
│       ├── home_screen.dart       # Dashboard
│       ├── bmi_screen.dart
│       ├── water_screen.dart
│       ├── activity_screen.dart
│       ├── sleep_screen.dart
│       └── nutrition_screen.dart
├── pubspec.yaml               # Dependencies
└── assets/
    └── images/
```

---

## Warum Flutter?

- **Eine Codebasis** → alle Plattformen
- **Nativ kompiliert** → keine Performance-Einbußen
- **Material Design 3** → modernes UI
- **SQLite** → lokale Datenspeicherung, kein Server nötig
- **Dart** → einfach zu lernen, stark typisiert

---

## Abhängigkeiten (pubspec.yaml)

| Package | Zweck |
|---------|-------|
| `sqflite` | SQLite Datenbank (Android/iOS) |
| `sqflite_common_ffi` | SQLite für Desktop & Tests |
| `path` | Dateipfade plattformunabhängig |
| `fl_chart` | Diagramme & Charts |
| `provider` | State Management |
| `intl` | Datum/Zeit Formatierung |
| `shared_preferences` | Einfache Einstellungen speichern |
| `flutter_localizations` | Deutsch/Englisch Lokalisierung |
