# Як зібрати TRS Browser

## Системні вимоги

| | Linux | macOS | Windows |
|---|---|---|---|
| ОС | Ubuntu 20.04+ | 12.0+ | 10 / 11 |
| RAM | 16 ГБ+ | 16 ГБ+ | 16 ГБ+ |
| Диск | 100 ГБ+ SSD | 100 ГБ+ SSD | 100 ГБ+ SSD |
| CPU | 8 ядер+ | 8 ядер+ | 8 ядер+ |

Перший білд Chromium — це серйозно. На слабкій машині може займати 4–6 годин.

---

## Крок 1 — Клонуй trs-core

```bash
git clone https://github.com/thereross-browser/trs-core
cd trs-core
```

## Крок 2 — Запусти setup.sh

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

Скрипт:
1. Встановить `depot_tools` (інструменти Google для роботи з Chromium)
2. Клонує Chromium потрібної версії (~15 ГБ)
3. Синхронізує всі залежності Chromium (~80 ГБ в сумі)
4. Підключить наш код (`trs-core/src/`) у дерево Chromium
5. Згенерує конфіг білду

> Перший запуск: 1–3 години. Потрібен стабільний інтернет.

## Крок 3 — Збери браузер

```bash
./scripts/build.sh debug
```

Перший білд: 1–3 год (залежить від CPU).  
Повторний: 2–10 хв (тільки змінені файли).

## Крок 4 — Запусти

```bash
# Linux / macOS
../chromium/src/out/TRS_Debug/chrome

# або з прапорами для розробки
../chromium/src/out/TRS_Debug/chrome --no-sandbox --disable-gpu
```

---

## Корисні команди

```bash
# Тільки наш код (швидко)
autoninja -C ../chromium/src/out/TRS_Debug trs_browser

# Оновити Chromium до нової версії
./scripts/update.sh 125.0.6422.60

# Release-білд (повільніше, але оптимізований)
./scripts/build.sh release
```

---

## Де що шукати

```
trs-core/src/
├── browser/    ← точка входу, головне вікно
├── ai_engine/  ← AI-функції (починай тут для AI фіч)
├── shield/     ← блокування (починай тут для Shield)
└── edu/        ← Edu Workspace
```

## Виникли проблеми?

Дивись [Issues](https://github.com/thereross-browser/trs-core/issues) або пиши в Discussions.
