# DanyAI Ollama Client

Flutter client for Ollama API.

## Features

- 💬 Chat with local LLM models
- 🎨 Modern Material 3 design
- 📱 Cross-platform (Android, Windows, Linux, macOS, iOS, Web)
- 🔧 Model manager
- 💾 Chat history persistence
- ⚙️ Flexible connection settings

## Requirements

- Flutter SDK ≥ 3.0
- Ollama server (local or remote)

## Installation

```bash
flutter pub get
flutter run
```

## Release Build

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# All platforms
python menu.py  # select option 8
```

## Using menu.py

```bash
python menu.py
```

Menu allows you to:
- Generate project dumps
- Build APK and Windows versions
- Run `flutter clean`, `pub get`, `pub upgrade`
- Execute `flutter doctor`

## Project Structure

```
lib/
├── main.dart           # Entry point
├── models/             # Data models
├── services/           # Services (Ollama API, settings)
└── widgets/            # UI components
```

## License

MIT
