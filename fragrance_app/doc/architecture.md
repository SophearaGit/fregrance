# Architecture

```bash
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── routes.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── providers/
│   │   └── app_providers.dart
│   └── screens/
│       ├── splash_screen.dart
│       ├── onboarding_screen.dart
│       ├── not_found_screen.dart
│       ├── error_screen.dart
│       └── main_screen.dart
│
├── core/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   └── api_exception.dart
│   ├── storage/
│   │   └── secure_storage.dart
│   ├── constants/
│   ├── extensions/
│   └── utils/
│
├── shared/
│   ├── widgets/
│   ├── dialogs/
│   └── components/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasource/
│   │   │   ├── model/
│   │   │   └── repository/             # Implementation
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repository/             # Abstraction
│   │   └── presentation/
│   │       ├── provider/
│   │       ├── screens/
│   │       ├── helpers/                # (Optional)
│   │       └── widgets/             # Private Widgets
│   ├── home/
│   ├── brand/
│   ├── discovery/
│   ├── favorite/
│
└── main.dart
```
