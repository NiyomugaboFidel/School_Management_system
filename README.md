# School Attendance Management System

A comprehensive Flutter-based school attendance management application with offline-first architecture, SQLite local storage, and Firebase synchronization capabilities.

## 🚀 Features

### Core Functionality
- **Fast Gate Attendance**: Quick student check-in via NFC/QR scanning without class selection
- **Offline-First**: All data stored locally with automatic Firebase sync when online
- **Multi-Authentication**: Username/password, phone/PIN, and biometric login
- **Role-Based Access**: Admin, Teacher, and User roles with different permissions
- **Calendar Management**: Holiday settings, attendance time thresholds
- **Attendance History**: Calendar-based view with Firebase data fetching

### Technical Features
- **Cross-Platform**: Flutter app supporting Android, iOS, Web, and Desktop
- **Local Database**: SQLite for offline data storage
- **Cloud Sync**: Firebase integration for data backup and sharing (no authentication required)
- **NFC Support**: Near Field Communication for student cards
- **QR Code Generation**: Student ID cards with barcodes
- **Biometric Authentication**: Fingerprint/Face ID support

## 📱 Default User Credentials

### Web Platform
The following users are available for testing on web platform:

| Username | Password | Role | Full Name | Email |
|----------|----------|------|-----------|-------|
| `admin` | `admin123` | Admin | System Administrator | admin@school.com |
| `teacher` | `teacher123` | Teacher | John Teacher | teacher@school.com |
| `user` | `user123` | User | Regular User | user@school.com |
| `fidele` | `1234678` | Admin | Fidele Niyomugabo | fidele@example.com |

### Mobile/Desktop Platform (SQLite)
The same users are seeded in the local SQLite database:

| Username | Password | Role | Full Name | Email |
|----------|----------|------|-----------|-------|
| `admin` | `admin123` | Admin | System Administrator | admin@school.com |
| `teacher` | `teacher123` | Teacher | John Teacher | teacher@school.com |
| `user` | `user123` | User | Regular User | user@school.com |
| `fidele` | `1234678` | Admin | Fidele Niyomugabo | fidele@example.com |

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- Firebase project (for cloud sync)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sqlite_crud_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (optional, for cloud sync)
   - Create a Firebase project
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration in `lib/firebase_options.dart`

4. **Run the application**
   ```bash
   # For development
   flutter run
   
   # For web
   flutter run -d chrome
   
   # Build APK
   flutter build apk --release --split-per-abi
   ```

## 🧪 Testing

### Quick Start Testing
1. Launch the app
2. Use any of the default credentials above to log in
3. Test different user roles and permissions

### Feature Testing Checklist

#### Authentication
- [ ] Username/password login
- [ ] Phone/PIN login (mobile only)
- [ ] Biometric authentication (mobile only)
- [ ] Role-based access control

#### Attendance Management
- [ ] Fast gate attendance scanning
- [ ] NFC card reading/writing
- [ ] QR code generation and scanning
- [ ] Offline attendance recording
- [ ] Automatic sync when online

#### Student Management
- [ ] Add new students
- [ ] Generate student cards
- [ ] View student lists
- [ ] Student profile management

#### Settings & Configuration
- [ ] Holiday calendar management
- [ ] Attendance time thresholds
- [ ] Biometric settings
- [ ] Dark mode toggle
- [ ] Manual sync controls

#### Data Management
- [ ] Calendar-based attendance history
- [ ] Firebase data fetching
- [ ] Local data management
- [ ] Export/import functionality

## 📊 Database Schema

### Core Tables
- **users**: User authentication and roles
- **students**: Student information and cards
- **classes**: Class and level management
- **attendance_logs**: Daily attendance records
- **payments**: Student payment tracking
- **discipline**: Student behavior records
- **holidays**: School holiday calendar
- **statistics**: Attendance analytics
- **sync_queue**: Firebase sync management

## 🔧 Configuration

### Attendance Settings
- **Start Time**: Default school start time
- **Late Threshold**: Minutes after start time for late marking
- **Absence Threshold**: Minutes after start time for absence marking
- **Holidays**: Calendar-based holiday management

### Sync Settings
- **Auto Sync**: Automatic Firebase synchronization (no login required)
- **Manual Sync**: On-demand data synchronization
- **Sync Frequency**: Configurable sync intervals
- **School-Based Sync**: All data synced under school identifier

## 📱 Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| Android | ✅ Full | All features including NFC |
| iOS | ✅ Full | All features including NFC |
| Web | ✅ Limited | No NFC, limited biometric |
| Windows | ✅ Full | All features except NFC |
| macOS | ✅ Full | All features except NFC |
| Linux | ✅ Full | All features except NFC |

## 🚀 Deployment

### Android APK
```bash
flutter build apk --release --split-per-abi
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Version History

- **v1.0.0**: Initial release with core attendance features
- **v1.1.0**: Added Firebase sync and calendar features
- **v1.2.0**: Enhanced UI/UX and biometric authentication
- **v1.3.0**: Multi-platform support and offline-first architecture