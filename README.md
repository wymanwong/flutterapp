# Restaurant Availability Notification System

A comprehensive restaurant management system built with Flutter and Firebase, featuring real-time availability tracking, reservation management, and analytics dashboard.

## Features

- **Authentication System**
  - Secure login with Firebase Authentication
  - Role-based access control
  - Multi-factor authentication support

- **Dashboard**
  - Real-time analytics
  - Occupancy tracking
  - Revenue insights
  - Performance metrics

- **Reservation Management**
  - Real-time booking system
  - Waitlist management
  - Guest history tracking
  - Cancellation handling

- **Restaurant Management**
  - Restaurant profiles
  - Menu management
  - Pricing configuration
  - Availability settings

- **User Management**
  - Role-based permissions
  - Staff accounts
  - Activity logging
  - Access control

## Technical Stack

- **Frontend**: Flutter
- **Backend**: Firebase
- **State Management**: Riverpod
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Analytics**: Firebase Analytics
- **Notifications**: Firebase Cloud Messaging

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase CLI
- Firebase project
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/restaurant_availability_system.git
   cd restaurant_availability_system
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project
   - Enable Authentication, Firestore, and Storage
   - Download `google-services.json` and place it in `android/app/`
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - Update Firebase configuration in `lib/core/config/firebase_config.dart`

4. Run the app:
   ```bash
   flutter run
   ```

### Development Setup

1. Enable Firebase Emulators for local development:
   ```bash
   firebase init emulators
   firebase emulators:start
   ```

2. The app will automatically connect to emulators in debug mode.

## Project Structure

```
lib/
├── core/
│   ├── config/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── reservations/
│   ├── restaurants/
│   └── users/
└── shared/
    ├── models/
    ├── services/
    └── widgets/
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase team for the robust backend services
- All contributors who help improve this project
