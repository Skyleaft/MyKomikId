# Open Manga Reader

![Open Manga Reader Banner](https://placehold.co/1200x400/212121/white?text=Open+Manga+Reader)

Open Manga Reader is a modern, feature-rich manga reading application built with Flutter. It provides a seamless experience for discovering, reading, and managing your favorite manga titles across multiple platforms.

## ✨ Features

- **🚀 Multi-Platform**: Native performance on Android, iOS, Windows, macOS, Linux, and Web.
- **🔍 Advanced Discovery**: Search and explore a vast collection of manga from various sources.
- **📚 Personal Library**: Organize your favorite titles and track your reading progress.
- **☁️ Cloud Sync**: Sync your library and progress across all your devices using Firebase.
- **📖 Immersive Reader**: A customizable reading experience with support for horizontal and vertical scrolling.
- **🌘 Dynamic Themes**: Beautiful light and dark modes that adapt to your system settings.
- **🔐 Secure Auth**: Built-in authentication using Firebase to keep your data safe.
- **💾 Offline Support**: Cache your favorite manga for reading anytime, anywhere.
- **📈 Progress Tracking**: Automatically track which chapters you've read and resume where you left off.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Backend & Auth**: [Firebase](https://firebase.google.com/)
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it) & [Injectable](https://pub.dev/packages/injectable)
- **Networking**: [Dio](https://pub.dev/packages/dio) / [HTTP](https://pub.dev/packages/http)
- **Typography**: [Google Fonts](https://fonts.google.com/)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extension
- Firebase CLI (for configuration)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/open_manga_reader.git
    cd open_manga_reader
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run build runner (if applicable):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Configure Firebase:**
    Ensure you have your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the appropriate directories. You can also use the FlutterFire CLI to reconfigure:
    ```bash
    flutterfire configure
    ```

5.  **Run the app:**
    ```bash
    flutter run
    ```

## 🏗️ Project Structure

```text
lib/
├── core/           # Constants, themes, dependency injection, and utilities
├── data/           # Models, services, and API configurations
├── presentation/   # UI screens, widgets, and state management logic
├── routes/         # App routing and navigation definitions
└── slicing/        # UI design mockups and HTML slicing
```

## 📱 Screenshots

| Home | Discover | Reader |
|:---:|:---:|:---:|
| ![Home](https://placehold.co/300x600/212121/white?text=Home+Screen) | ![Discover](https://placehold.co/300x600/212121/white?text=Discover+Screen) | ![Reader](https://placehold.co/300x600/212121/white?text=Reader+Screen) |

## 🤝 Contributing

Contributions are welcome! If you'd like to improve the app, feel free to fork the repository and submit a pull request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Built with ❤️ by the Open Manga Reader Team.
