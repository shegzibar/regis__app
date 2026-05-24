# GamingHub - Egypt's Gaming Center Reservation Platform

GamingHub is a Flutter mobile application that serves as a reservation marketplace for gaming centers (cyber cafes) in Egypt. Think of it as the **Talabat of gaming centers**: users discover, book and pay for gaming station sessions at any registered cyber cafe.

## 🏗️ Architecture Overview

```
GamingHub Flutter App
├── Role: user      → User App (discovery + booking)
├── Role: owner     → Owner Dashboard (manage stations + bookings)
├── Role: manager   → Manager Dashboard (review 5 EGP booking fees)
└── Role: admin     → Admin Panel (platform-wide oversight)

Backend: Supabase
├── PostgreSQL database
├── Supabase Auth (phone/OTP login)
├── Supabase Storage (receipt screenshots)
└── Supabase Realtime (live booking status updates)
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Supabase account
- Firebase account (for push notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd gaming_hub
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase**
   - Create a new project in Supabase
   - Run the `database_schema.sql` file in the Supabase SQL editor
   - Enable phone authentication in Supabase Auth settings
   - Update `lib/core/constants/app_constants.dart` with your Supabase URL and anon key

4. **Set up Firebase**
   - Create a new Firebase project
   - Add Android and iOS apps
   - Download the configuration files and place them in the appropriate directories
   - Enable Cloud Messaging

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Features

### User App
- **Explore**: Discover gaming centers with filters and search
- **Map View**: Find nearby gaming centers on a map
- **Booking**: Reserve gaming stations with date/time selection
- **Payment**: Upload receipts for 5 EGP booking fee
- **My Bookings**: View and manage booking history
- **Profile**: User settings and preferences

### Owner Dashboard
- **Home**: Revenue and booking statistics
- **Schedule**: View and manage daily schedule
- **Requests**: Approve/reject booking requests
- **Stations**: Manage gaming stations and rooms

### Manager Dashboard
- **Fee Queue**: Review 5 EGP booking fee receipts
- **History**: Track all payment decisions
- **Overview**: Analytics and insights

### Admin Panel
- **Home**: Platform-wide oversight
- **User Management**: Manage user roles and permissions
- **Cyber Management**: Oversee all gaming centers

## 🗄️ Database Schema

The app uses PostgreSQL with the following main tables:

- **users**: User profiles and roles
- **cybers**: Gaming center information
- **rooms**: Different gaming room types (PS5, PC, VIP)
- **stations**: Individual gaming stations
- **bookings**: Booking records and status
- **payments**: Payment receipts and reviews
- **reviews**: User ratings and feedback
- **notifications**: In-app notifications

## 🔐 Business Rules

1. **5 EGP booking fee** — flat, every reservation, all room types
2. **15-minute slot lock** — auto-cancelled if no payment uploaded
3. **Manager reviews every receipt** — no automatic approval in MVP
4. **No booking overlaps** — one confirmed booking per station per time slot
5. **Only completed bookings** can leave reviews
6. **Rejected bookings** release the slot immediately
7. **Realtime** — status changes reflect instantly without refresh
8. **Phone/OTP auth only** — no email login

## 🎨 Design System

### Colors
- **Primary**: Purple (#534AB7) for user app
- **Secondary**: Teal (#0F6E56) for owner/manager app
- **Status**: Amber (pending), Green (confirmed), Red (rejected)

### Themes
- **User App**: Dark theme with purple accent
- **Owner/Manager**: Light theme with teal + purple accents
- **Both**: Arabic RTL + English LTR support

## 📦 Key Dependencies

- `flutter_riverpod`: State management
- `go_router`: Navigation and routing
- `supabase_flutter`: Backend integration
- `google_maps_flutter`: Map functionality
- `image_picker`: Receipt upload
- `firebase_messaging`: Push notifications
- `google_fonts`: Typography

## 🧪 Testing

```bash
flutter test
```

## 📱 Build & Deploy

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔧 Configuration

### Environment Variables

Update `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### Firebase Configuration

Place the following files:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Email: support@gaminghub.eg
- Website: www.gaminghub.eg

---

*GamingHub — Egypt's Gaming Center Reservation Platform*
*Flutter + Supabase | Cairo, Egypt*
