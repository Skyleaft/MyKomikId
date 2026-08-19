# Open Manga Reader

![Open Manga Reader Banner](https://placehold.co/1200x400/212121/white?text=Open+Manga+Reader)

Open Manga Reader is a modern, cross-platform manga reading application built with Flutter. Built using **Pure Vertical Slice Architecture (V-Slice)** and **Domain-Driven Design (DDD)** principles, it provides a performant, modular, and maintainable codebase for discovering, reading, and managing manga titles.

---

## ✨ Features

- **🚀 Multi-Platform**: Native performance on Android, iOS, Windows, macOS, Linux, and Web with Desktop window state persistence.
- **🔍 Advanced Discovery & Scraping**: Search across sources, scrape metadata and chapters on demand, and filter by genre, status, and type.
- **🤖 AI-Powered Recommendations**: Personalized manga recommendations driven by your reading history and preferences.
- **📚 Personal Library**: Organize manga into Reading, Completed, On-Hold, and Dropped statuses with offline caching.
- **📖 Immersive & Smart Reader**:
  - Continuous **Webtoon** vertical scrolling and **Paged** horizontal mode (with **LTR** and **RTL Manga** directions).
  - Fluid desktop window resizing and double-tap / pinch zooming (`InteractiveViewer`).
  - **Ahead-of-Time Page Pre-caching** for instant rendering and zero-stutter scrolling.
  - **Smart Image Retry & CDN Referrer Headers** support.
  - Live **Battery Level & Clock** status overlay.
  - **Auto-Scroll HUD** with adjustable speed multiplier.
  - **Keyboard & Hotkey Navigation** on Desktop & Web (`F`, `Space`, `Escape`, `[`/`]`, `W/A/S/D`, arrow keys).
- **☁️ Cloud Sync & Offline-First**: Local storage paired with seamless cloud synchronization, debounced updates, and queued offline mutations.
- **📈 Progression Tracking**: Real-time chapter reading time tracking, progress history, and statistics.
- **🔔 Push Notifications & Library Topic Sync**: Firebase Cloud Messaging (FCM) integration with automated backend device token registration (`/api/v1/users/fcm-token`), library-based topic subscription (`manga_{mangaId}`), and deep routing directly to manga details on new chapter releases.
- **🔐 Secure Authentication**: Firebase Auth with Google Sign-In support across Mobile, Web, and Desktop (PKCE OAuth with custom loopback).
- **🌘 Dynamic Themes**: Curated light and dark modes adhering to modern design aesthetics.
- **⚙️ Custom API Management**: Dynamically switch and configure backend API endpoints with connection testing.

---

## ⌨️ Desktop & Web Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`F`** | Toggle Fullscreen Mode |
| **`Space`** | Toggle Auto-Scrolling |
| **`Esc`** | Exit Fullscreen or Close Reader |
| **`[` / `]`** | Previous / Next Chapter |
| **`W` / `S`** or **`↑` / `↓`** | Smooth scroll up / down (Webtoon mode) |
| **`A` / `D`** or **`←` / `→`** | Turn page backward / forward (adapts to LTR / RTL mode) |
| **`PageUp` / `PageDown`** | Jump scroll / page by screen height |

---

## 🏗️ Architecture: Pure Vertical Slice (V-Slice)

The project follows a **Pure Vertical Slice Architecture**. Features are isolated, self-contained slices containing their own domain models, state controllers, services, and single-responsibility presentation widgets.

```text
lib/
├── core/                               # Cross-cutting infrastructure & shared kernel
│   ├── config/                         # App configuration (Base URL persistence)
│   ├── constants/                      # Theme colors and style constants
│   ├── di/                             # GetIt service locator setup
│   ├── models/                         # Shared DTOs (MangaSummary, PagedResponse)
│   ├── network/                        # Centralized Dio API client, ApiConfig, and SyncService
│   ├── services/                       # Cross-cutting services (NotificationService)
│   ├── theme/                          # Material light & dark themes
│   ├── utils/                          # Common formatters and helpers
│   └── widgets/                        # Shared reusable widgets (AppBottomNav, AlertBanner, DiscoverCard, MangaCard)
│
├── features/                           # Pure Vertical Feature Slices
│   ├── auth/                           # Authentication slice (Google Desktop PKCE, Firebase)
│   │   ├── services/
│   │   └── presentation/
│   │
│   ├── home/                           # Home dashboard slice
│   │   ├── models/
│   │   ├── controllers/
│   │   └── presentation/
│   │       ├── home_screen.dart        # Thin coordinator (~150 lines)
│   │       └── widgets/                # Single-responsibility section widgets
│   │
│   ├── manga_detail/                   # Manga details & chapter list slice
│   │   ├── models/
│   │   ├── services/
│   │   ├── controllers/
│   │   └── presentation/
│   │       ├── manga_detail_screen.dart # Thin coordinator (~250 lines)
│   │       └── widgets/                # Modular sub-widgets (AppBar, Info, Stats, Chapters, Recs)
│   │
│   ├── reader/                         # Manga reader & webtoon viewer slice
│   │   ├── models/                     # ReaderContent with copyWith & CDN header support
│   │   └── presentation/
│   │       ├── reader_screen.dart      # Main reader view with CancelToken management
│   │       └── widgets/                # Header, BottomBar, Content viewport, SettingsSheet, ChapterPickerSheet, StatusBarInfo, AppNetworkImage
│   │
│   ├── library/                        # User library slice
│   │   ├── models/
│   │   ├── services/
│   │   ├── controllers/
│   │   └── presentation/
│   │
│   ├── history/                        # Reading history & progression slice
│   │   ├── models/
│   │   ├── services/
│   │   ├── controllers/
│   │   └── presentation/
│   │
│   ├── discover/                       # Discover, search scrape, and AI recommendation slice
│   │   ├── models/
│   │   └── presentation/
│   │       ├── discover_screen.dart
│   │       ├── search_scrap_screen.dart
│   │       ├── advanced_recommendation_screen.dart
│   │       └── widgets/
│   │
│   ├── settings/                       # Settings, reading statistics, and API config slice
│   │   ├── services/
│   │   └── presentation/
│   │       ├── more_screen.dart
│   │       └── base_api_setting_screen.dart
│   │
│   └── main/                           # Root navigation container slice
│       └── presentation/
│           └── main_screen.dart
│
└── routes/
    └── app_pages.dart                  # Central route definitions and navigation arguments
```

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart 3+)
- **Architecture**: Vertical Slice Architecture (V-Slice) + DDD
- **State Management**: [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) + [Provider](https://pub.dev/packages/provider)
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it)
- **Networking**: [Dio](https://pub.dev/packages/dio) & [HTTP](https://pub.dev/packages/http) with `CancelToken` request lifecycle cancellation
- **Image Caching & Preloading**: [CachedNetworkImageCE](https://pub.dev/packages/cached_network_image_ce)
- **Desktop Window Management**: [window_manager](https://pub.dev/packages/window_manager)
- **Hardware Integration**: [battery_plus](https://pub.dev/packages/battery_plus)
- **Backend & Auth**: [Firebase Auth](https://firebase.google.com/), [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging), & [MangaScrapper API](https://github.com/Skyleaft/MangaScrapper)
- **Push & Local Notifications**: [firebase_messaging](https://pub.dev/packages/firebase_messaging) & [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Desktop OAuth**: Custom loopback authorization with PKCE (RFC 7636 / RFC 8252)
- **Deep Linking**: [app_links](https://pub.dev/packages/app_links) & [protocol_handler](https://pub.dev/packages/protocol_handler)
- **Typography**: [Google Fonts](https://fonts.google.com/)

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- Dart SDK
- IDE with Flutter extension (VS Code, Android Studio)
- Firebase CLI (for configuration)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Skyleaft/open-manga-reader.git
   cd open-manga-reader
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Environment Variables:**
   Create a `.env` file in the project root:
   ```env
   GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id
   GOOGLE_DESKTOP_CLIENT_SECRET=your_desktop_client_secret
   ```

4. **Configure Firebase:**
   ```bash
   flutterfire configure
   ```

5. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🧪 Code Quality & Verification

Run static analysis to ensure code conforms to linting and architectural boundaries:

```bash
flutter analyze
```

---

## 🤝 Contributing

Contributions are welcome! Please follow the vertical slice architecture pattern when introducing new features or modifying existing domains:
1. Place feature-specific models, services, controllers, and widgets inside `lib/features/<feature_name>/`.
2. Keep screen coordinators thin and split UI into single-responsibility widgets under `presentation/widgets/`.
3. Place cross-cutting infrastructure into `lib/core/`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
