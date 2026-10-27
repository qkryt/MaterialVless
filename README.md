# MaterialVless

<p align="center">
  <b>Современный полнофункциональный десктопный клиент VLESS / Reality / gRPC / Hysteria на базе ядра Xray-core в дизайне Material Design 3 (Material You).</b>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/qkryt/MaterialVless?style=for-the-badge&color=6750A4" alt="Release" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Xray--core-v24.11-red?style=for-the-badge" alt="Xray" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 🚀 Особенности и возможности

### 🎨 Дизайн и интерфейс (Material Design 3 / Material You)
- **Стильный двухпанельный интерфейс**: слева список подписок и серверов с флагами стран, справа — минималистичная панель управления со светящейся кнопкой подключения без лишних элементов.
- **Векторный логотип**: фирменный логотип MaterialVless в стиле Material You.
- **Шрифт по умолчанию**: Google Sans.
- **Флаги стран**: автоматическое распознавание кодов стран (FI, DE, NL, US, RU, AT, PL и др.) и отображение официальных эмодзи флагов без мусорных значков.
- **Темы оформления**: Светлая, Тёмная и глубокая **AMOLED Black** с поддержкой Dynamic Color.

### 🛡️ Протоколы и ядро Xray-core
- **VLESS**: поддержка Reality, XTLS Vision, gRPC, WebSocket, xhttp / splithttp.
- **VMess, Trojan, Shadowsocks**: полная поддержка всех стандартных шифров.
- **Hysteria & Hysteria 2 (`hy2://`)**: высокоскоростной UDP туннель.
- **Единый режим защиты**: объединённый виртуальный TUN-адаптер (Wintun) и системный прокси.

### 💾 Сохранение данных в отдельный файл проекта
- Все подписки, серверы, время обновлений и настройки сохраняются в локальный структурированный файл `material_vless_data.json`.
- Полное восстановление состояния клиента при повторном запуске.

### 📋 Менеджер подписок и автообновление
- **Автообновление**: выбор периодичности (1ч, 2ч, 6ч, 12ч, 24ч или выключено).
- **История обновлений**: запись точного времени последнего обновления в файл и отображение в карточке подписки.
- **Сворачиваемые вкладки**: каждая подписка — это отдельная сущность, которую можно свернуть или развернуть.
- **Импорт любого формата**: URL подписок, Base64, ссылки `vless://`, `ss://`, `hy2://`, а также файлы `.txt`.

### ⚡ Точный пинг и тест скорости
- **Реальный TLS-пинг**: исключены ложные значения в 2 мс. Проверка задержки до `http://cp.cloudflare.com/` отражает реальный маршрут.
- **Безопасное тестирование**: автоматическое отключение VPN перед началом замера пинга всех узлов.

### 🌐 Маршрутизация (Routing)
- **None (по умолчанию)** — весь трафик направляется через защищённый туннель.
- **Russia** — автоматический обход сайтов РФ и локальных IP (`geosite:ru`, `geoip:ru`, `geoip:private`).
- Прямая загрузка актуальных баз `geoip.dat` и `geosite.dat`.

---

## 📥 Загрузки (Десктопные платформы)

Готовые релизы компилируются автоматически через GitHub Actions в разделе **[Releases](https://github.com/qkryt/MaterialVless/releases/latest)**:

| Платформа | Файл релиза | Описание |
| :--- | :--- | :--- |
| **Windows x64** | `MaterialVless-Windows-x64.zip` | 64-битная версия с ядром Xray и драйвером Wintun x64 |
| **Windows x86** | `MaterialVless-Windows-x86.zip` | 32-битная версия с ядром Xray и драйвером Wintun x86 |
| **Linux x64** | `MaterialVless-Linux-x64.tar.gz` | Для 64-битных дистрибутивов Linux (Ubuntu, Debian, Fedora, Arch) |
| **Linux x86** | `MaterialVless-Linux-x86.tar.gz` | Для 32-битных дистрибутивов Linux |
| **macOS** | `MaterialVless-macOS.zip` | Universal (Apple Silicon M1/M2/M3/M4 + Intel x86_64) |
| **Базы правил** | `geoip.dat`, `geosite.dat` | Автономные базы маршрутизации прямо в релизе |

---

## 🛠️ Сборка из исходного кода

```bash
git clone https://github.com/qkryt/MaterialVless.git
cd MaterialVless
flutter pub get
flutter run
```

---

## 📄 Лицензия
Проект распространяется под лицензией MIT.
