# MaterialVless

<p align="center">
  <img src="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/favicon.ico" width="80" height="80" alt="MaterialVless Logo" />
</p>

<p align="center">
  <b>Современный полнофункциональный VLESS / Reality клиент на базе ядра Xray-core в эстетике Material Design 3 (Material You).</b>
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
- **Двухпанельный адаптивный интерфейс**: удобная навигация по подпискам слева и интерактивная панель управления с большой кнопкой подключения справа.
- **Шрифт по умолчанию**: Google Sans.
- **Dynamic Color**: автоматическая адаптация палитры приложения под системные цвета Windows, Android и macOS.
- **Темы**: Светлая, Тёмная и глубокая **AMOLED Black**.

### 🛡️ Протоколы и ядро Xray-core
- **VLESS**: поддержка Reality, XTLS Vision, gRPC, WebSocket, xhttp / splithttp.
- **VMess**: стандартный шифрованный протокол.
- **Trojan & Shadowsocks**: полная поддержка современных шифров.
- **Hysteria & Hysteria 2 (`hy2://`)**: поддержка высокоскоростного UDP-протокола.
- **Единый режим защиты**: одновременная работа виртуального TUN-адаптера (Wintun) и системного прокси без утечек DNS.

### 📋 Менеджер подписок и импорт
- **Поддержка любых форматов**: Base64, ссылки подписок, прямые URL, а также файлы `.txt`.
- **Поддержка нескольких подписок**: добавление 1 и более источников с независимым обновлением и учетом трафика.
- **HWID**: генерация уникального аппаратного идентификатора для авторизации в панелях Marzban / V2Board.
- **Автообновление**: фоновое обновление по таймеру и при каждом запуске.

### ⚡ Пинг и тест скорости
- **Пинг Cloudflare**: проверка задержки через `http://cp.cloudflare.com/` с таймаутом в 1 секунду.
- **Тест скорости**: замер скорости загрузки через `http://cachefly.cachefly.net/1mb.test`.
- **Чистый замер**: автоматическое отключение активного VPN перед началом тестирования всех серверов.

### 🌐 Маршрутизация (Routing)
- Предустановленные пресеты:
  1. **None (по умолчанию)** — весь трафик направляется через защищенный прокси.
  2. **Russia** — автоматический обход сайтов РФ и локальных IP (`geosite:ru`, `geoip:ru`, `geoip:private` идут напрямую).
- Автоматическое скачивание актуальных баз `geoip.dat` и `geosite.dat` от Loyalsoldier.

---

## 📥 Загрузки (Поддерживаемые платформы и архитектуры)

Готовые бинарники компилируются автоматически через GitHub Actions в разделе **[Releases](https://github.com/qkryt/MaterialVless/releases/latest)**:

| Платформа | Файл релиза | Описание |
| :--- | :--- | :--- |
| **Windows x64** | `MaterialVless-Windows-x64.zip` | 64-битная версия с ядром Xray и драйвером Wintun x64 |
| **Windows x86** | `MaterialVless-Windows-x86.zip` | 32-битная версия с ядром Xray и драйвером Wintun x86 |
| **Android (Universal)** | `MaterialVless-Android-Universal.apk` | Универсальный APK для всех процессоров (ARM + x86) |
| **Android arm64** | `MaterialVless-Android-arm64-v8a.apk` | Оптимизирован для современных 64-битных смартфонов |
| **Android armv7** | `MaterialVless-Android-armeabi-v7a.apk`| Для старых 32-битных ARM устройств |
| **Android x86_64**| `MaterialVless-Android-x86_64.apk` | Для эмуляторов и планшетов на Intel/AMD |
| **iOS (IPA)** | `MaterialVless-iOS.ipa` | Пакет для Sideloadly, TrollStore, AltStore, Scarlet |
| **Linux x64** | `MaterialVless-Linux-x64.tar.gz` | Для 64-битных дистрибутивов Linux |
| **Linux x86** | `MaterialVless-Linux-x86.tar.gz` | Для 32-битных дистрибутивов Linux |
| **macOS** | `MaterialVless-macOS.zip` | Universal (Apple Silicon M1/M2/M3 + Intel x86_64) |
| **Базы правил** | `geoip.dat`, `geosite.dat` | Прямая загрузка баз маршрутизации из репозитория |

---

## 🛠️ Сборка из исходного кода

Требования:
- Flutter 3.27+ (канал `stable`)
- Go 1.22+ (для сборки ядра Xray-core)

```bash
# Клонирование репозитория
git clone https://github.com/qkryt/MaterialVless.git
cd MaterialVless

# Установка зависимостей Flutter
flutter pub get

# Запуск приложения
flutter run
```

---

## 📄 Лицензия
Проект распространяется под лицензией MIT.
