# trs-core

Chromium fork — основа браузера Thereross (TRS).

## Структура

```
trs-core/
├── scripts/
│   ├── setup.sh          ← СТАРТ ЗВІДСИ: клонує Chromium, налаштовує depot_tools
│   ├── build.sh          ← збирає браузер (debug / release)
│   ├── update.sh         ← синхронізує з upstream Chromium
│   └── brand.sh          ← замінює назви Chrome → TRS у коді
│
├── src/                  ← власний код TRS (не Chromium)
│   ├── browser/
│   │   ├── trs_browser_main.cc     ← точка входу TRS
│   │   ├── trs_content_client.cc   ← кастомний контент-клієнт
│   │   └── trs_content_client.h
│   ├── ai_engine/
│   │   ├── ai_sidebar.cc           ← AI-панель у браузері
│   │   ├── ai_sidebar.h
│   │   ├── page_analyzer.cc        ← аналіз відкритої сторінки
│   │   └── page_analyzer.h
│   ├── shield/
│   │   ├── ua_shield.cc            ← UA Shield: блокування RU/трекерів
│   │   ├── ua_shield.h
│   │   └── blocklists/
│   │       ├── ru_domains.txt      ← список RU-доменів
│   │       └── trackers.txt        ← трекери
│   └── edu/
│       ├── workspace.cc            ← Edu Workspace
│       └── workspace.h
│
├── config/
│   ├── trs_branding.gni            ← назва, версія, іконки для білду
│   └── trs_features.gni            ← feature flags (що вмикати)
│
├── resources/
│   └── icons/
│       ├── trs_logo_16.png
│       ├── trs_logo_32.png
│       ├── trs_logo_128.png
│       └── trs_logo_256.png
│
├── docs/
│   ├── BUILD.md                    ← як зібрати браузер
│   ├── ARCHITECTURE.md             ← як влаштований trs-core
│   └── CONTRIBUTING.md             ← як долучитись
│
├── .github/
│   └── workflows/
│       ├── build-linux.yml         ← CI: автоматичний білд Linux
│       ├── build-windows.yml       ← CI: автоматичний білд Windows
│       └── build-mac.yml           ← CI: автоматичний білд macOS
│
├── .gitignore
├── LICENSE
└── README.md
```

## Залежності

- Python 3.8+
- Git 2.28+
- ~100 ГБ вільного місця (Chromium великий)
- Linux: `build-essential`, `clang`, `ninja-build`
- macOS: Xcode Command Line Tools
- Windows: Visual Studio 2022 з C++ компонентами

## Починаємо

```bash
./scripts/setup.sh        # перший раз — займає 1-2 год
./scripts/build.sh debug  # debug-білд (~1-2 год на першому білді)
./scripts/build.sh release # release-білд (повільніше, менший файл)
```
