# DanyAI Ollama Client

Flutter клиент для работы с Ollama API.

## Особенности

- 💬 Чат с локальными LLM моделями
- 🎨 Современный Material 3 дизайн
- 📱 Кроссплатформенность (Android, Windows, Linux, macOS, iOS, Web)
- 🔧 Менеджер моделей
- 💾 Сохранение истории чатов
- ⚙️ Гибкие настройки подключения

## Требования

- Flutter SDK ≥ 3.0
- Ollama сервер (локальный или удалённый)

## Установка

```bash
flutter pub get
flutter run
```

## Сборка релиза

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# Все платформы
python menu.py  # выбери пункт 8
```

## Использование menu.py

```bash
python menu.py
```

Меню позволяет:
- Генерировать дампы проекта
- Собирать APK и Windows версии
- Выполнять `flutter clean`, `pub get`, `pub upgrade`
- Запускать `flutter doctor`

## Структура проекта

```
lib/
├── main.dart           # Точка входа
├── models/             # Модели данных
├── services/           # Сервисы (Ollama API, настройки)
└── widgets/            # UI компоненты
```

## Лицензия

MIT
