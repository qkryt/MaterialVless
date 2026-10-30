# MaterialVless 2.15.1 (Релиз 2.15.1)

<p align="center">
  <b><a href="README.md">Русский</a> | <a href="README_EN.md">English</a></b>
</p>

<p align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="MaterialVless Logo" />
</p>

<p align="center">
  <b>Современный высокопроизводительный десктопный клиент VPN для VLESS / Reality / gRPC / Hysteria 2 на базе ядра sing-box в дизайне Google Material Design 3 (Material You).</b>
</p>

<p align="center">
  <a href="https://github.com/qkryt/MaterialVless/releases/latest"><img src="https://img.shields.io/github/v/release/qkryt/MaterialVless?style=for-the-badge&color=6750A4" alt="Release" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/sing--box-1.14.4-00D2FF?style=for-the-badge" alt="sing-box" />
  <img src="https://img.shields.io/badge/Wintun-0.14.1-4CAF50?style=for-the-badge" alt="Wintun" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 🌟 Нововведения микропатча 2.1

### 🔗 Протокольные URL-схемы и Deep-Linking (`material://` и `happ://`)
MaterialVless 2.1 регистрирует в системе протокольные обработчики для схем `material://` и `happ://`, позволяя управлять подключением из браузеров, скриптов автоматизации и мессенджеров:

| Действие | URL-схемы | Описание |
| :--- | :--- | :--- |
| **Запустить туннель** | `material://connect`<br>`happ://connect`<br>`material://open`<br>`happ://open` | Подключает выбранный VPN-сервер |
| **Остановить туннель** | `material://disconnect`<br>`happ://disconnect`<br>`material://close`<br>`happ://close` | Разрывает соединение и восстанавливает системную маршрутизацию |
| **Переключить состояние** | `material://toggle`<br>`happ://toggle` | Переключает соединение (Connect / Disconnect) |
| **Добавить сервер / подписку** | `material://add{URL}`<br>`happ://add{URL}`<br>`material://crypt{URL}`<br>`happ://crypt{URL}`<br>`material://crypt2{URL}`<br>`happ://crypt2{URL}` | Автоматически импортирует URL подписки, прямую ссылку на узел или зашифрованный профиль |
| **Добавить маршрут** | `material://routing/add/{base64}`<br>`happ://routing/add/{base64}`<br>`material://routing/onadd/{base64}`<br>`happ://routing/onadd/{base64}` | Динамически добавляет доменное правило прямого обхода из строки base64 |
| **Сбросить маршруты** | `material://routing/off`<br>`happ://routing/off` | Очищает добавленные динамические правила маршрутизации |

### 🌐 Предпочитаемый тип IP (Preferred IP Strategy)
- **Auto (IPv4 / IPv6)**: Автоматический выбор IP-адреса в зависимости от доступности сети.
- **Только IPv4 (`ipv4_only`)**: Принудительное разрешение и маршрутизация только по IPv4 (актуально для сетей с нестабильным IPv6).
- **Предпочитать IPv6 (`prefer_ipv6`)**: Приоритет IPv6 адресов при их наличии на сервере.

### 🎨 Кастомизация интерфейса и Material You
- **Палитра семян Material You**: Выбор из 8 гармоничных цветовых акцентов (*Deep Purple, Electric Blue, Emerald Teal, Forest Green, Sunset Orange, Ruby Crimson, Cyber Pink, Graphite Slate*) с анимацией и мгновенным применением.
- **6 встроенных рабочих шрифтов**: `Google Sans`, `Roboto`, `Segoe UI`, `Consolas`, `Arial` и `Tahoma`.
- **Импорт шрифтов (.ttf, .otf)**: Возможность загрузить любой собственный шрифт с файловой системы с предпросмотром и кнопкой сброса на системный.
- **Двуязычный интерфейс**: Переключатель языков интерфейса на лету (Русский / English).
- **Режимы темы**: Системная, Светлая, Тёмная и глубокая **AMOLED Black** для OLED-экранов.

### ⚙️ Расширенные настройки подписок
- **Адаптивное поле ввода адреса**: Контейнер автоматически подстраивается под ширину окна и длину ссылки, поддерживая многострочный ввод.
- **Пользовательский User-Agent**: Возможность задать уникальный User-Agent для конкретного провайдера подписки с сохранением глобального значения по умолчанию.
- **Автоматические действия при запуске**:
  - Обновление подписки при старте приложения.
  - Пинг серверов подписки при старте.
  - Автоподключение к узлу с наименьшим пингом при старте.
- **Управление аппаратным HWID**: Включение/выключение передачи заголовка `X-HWID` и ввод альтернативного аппаратного идентификатора.

### 🛡️ Управление процессами и Single Instance
- **Защита от запуска дубликатов**: Встроенный IPC-сервер на порту `127.0.0.1:49281` предотвращает повторный запуск клиента, активирует и выводит уже открытое окно на передний план и передает ему URL-команды.
- **Восстановление после зависаний**: Автоматически обнаруживает некорректно завершенные процессы и очищает состояние.
- **Встроенный загрузчик обновлений**: Скачивает официальный установщик `.exe` из релизов GitHub в реальном времени с окном прогресса, запускает его и корректно закрывает приложение.

---

## 🚀 Основные возможности

- **Ядро sing-box v1.14.4 и драйвер Wintun v0.14.1**: Сетевой TUN-драйвер уровня ядра для сверхнизких задержек и высокой скорости передачи.
- **Поддержка современных протоколов**:
  - `vless://` (Reality, XTLS, Vision, gRPC, WebSocket)
  - `hysteria2://` / `hy2://` (Высокоскоростной UDP-протокол)
  - `ss://` (Shadowsocks 2022, AEAD)
  - `trojan://`
  - `vmess://`
  - Зашифрованные форматы подписок (`crypt://`, `crypt2://`)
- **Умная маршрутизация и обход блокировок**:
  - **Защищенный DNS (DoH)**: Cloudflare (`1.1.1.1`) и Google (`8.8.8.8`) через шифрованный HTTPS-туннель.
  - **Обход локальной сети (LAN)**: Автоматическое исключение подсетей (`192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12`).
  - **Пресет обхода сайтов РФ**: Прямой доступ к государственным и банковским ресурсам рунета без замедления.
- **Системный трей и поведение**:
  - Автозапуск вместе с Windows (через реестр HKCU Run).
  - Сворачивание в область уведомлений при закрытии окна.
  - Быстрое контекстное меню: Открыть, Перезагрузить ядро, Выйти.

---

## 📥 Загрузка готовых сборок

Сборки компилируются автоматически через GitHub Actions в разделе **[Releases](https://github.com/qkryt/MaterialVless/releases/latest)**:

| Платформа | Файл | Описание |
| :--- | :--- | :--- |
| **Windows x64** | `MaterialVless-Windows-x64-Setup.exe` | Рекомендуемый установщик для 64-битной Windows |
| **Windows x64** | `MaterialVless-Windows-x64.zip` | Портативная версия с sing-box и Wintun |
| **Windows x86** | `MaterialVless-Windows-x86-Setup.exe` | Установщик для 32-битной Windows |
| **Windows x86** | `MaterialVless-Windows-x86.zip` | Портативная версия x86 |
| **Linux x64** | `MaterialVless-Linux-x64.tar.gz` | Linux x86_64 сборка (Ubuntu, Debian, Fedora, Arch) |
| **Linux x86** | `MaterialVless-Linux-x86.tar.gz` | Linux 32-bit сборка |
| **macOS** | `MaterialVless-macOS.zip` | Универсальный архив macOS (Apple Silicon и Intel) |

---

## 🛠️ Сборка из исходников

### Требования
1. [Flutter SDK](https://flutter.dev/) (>= 3.22.0)
2. [Go](https://go.dev/) (>= 1.22)
3. Visual Studio 2022 с компонентом «Разработка классических приложений на C++»
4. [Inno Setup 6](https://jrsoftware.org/isdl.php) (для сборки инсталляторов Windows)

### Команды сборки
```bash
# Клонирование репозитория
git clone https://github.com/qkryt/MaterialVless.git
cd MaterialVless

# Установка зависимостей Flutter
flutter pub get

# Сборка Windows Release бинарника
flutter build windows --release

# Компиляция установщика Inno Setup
iscc windows/installer_x64.iss
```

---

## 📄 Лицензия

Проект распространяется под открытой лицензией [MIT License](LICENSE).
