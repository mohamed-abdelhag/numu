# Folder Structure

This document describes the current folder structure for the numu habit tracking app. As we implement more features, this documentation will be expanded.

## Current Structure

lib/
│
├── app/                             # Global, app-level setup
│   ├── config/                      # Env config, app constants
│   ├── router/                      # GoRouter / AutoRoute setup
│   ├── theme/                       # App-wide colors, typography, themes
│   ├── localization/                # Translations, intl setup
│   ├── di/                          # Dependency injection (get_it, riverpod, etc.)
│   └── app.dart                     # Root widget
│
├── core/                            # Shared/core functionality (used by features)
│   ├── network/                     # API client, interceptors, Dio setup
│   ├── error/                       # Failure classes, error handling
│   ├── utils/                       # Helpers (date_format, validators, etc.)
│   ├── widgets/                     # Shared widgets (buttons, inputs, etc.)
│   ├── services/                    # Cross-cutting services (analytics, storage)
│   ├── usecases/                    # Reusable domain logic
│   └── constants/                   # App-wide constants
│
├── features/                        # Each feature is self-contained
│   ├── home/
│   │   └── presentation/
│   │
│   │   See [Home Feature Documentation](home/home_screen.md) for details.
│   │
│   └── profile/
│   │   └── presentation/
│   │
│   │   See [Profile Feature Documentation](profile/profile_screen.md) for details.
│   │
│   ├── settings/
│   │   └── presentation/
│   │
│   │   See [Settings Feature Documentation](settings/settings_screen.md) for details.
│   │
│   │
│   │
│   ├── habits/
│
└── main.dart                        # Entry point
