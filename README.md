# MaterialVless 2.0

<p align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="MaterialVless Logo" />
</p>

<p align="center">
  <b>Современный полнофункциональный десктопный клиент VLESS / Reality / gRPC / Hysteria на базе ядра sing-box в дизайне Material Design 3 (Material You).</b>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/qkryt/MaterialVless?style=for-the-badge&color=6750A4" alt="Release" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/sing--box-1.14-00D2FF?style=for-the-badge" alt="sing-box" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 🚀 Особенности и возможности версии 2.0

### 🎨 Дизайн и интерфейс (Material Design 3 / Material You)
- **Стильный двухпанельный интерфейс**: слева список подписок и серверов с флагами стран, справа — минималистичная панель управления со светящейся кнопкой подключения.
- **Единый официальный логотип**: фирменный логотип MaterialVless в стиле Material You для окна программы, системного трея и установщика.
- **Импорт пользовательских шрифтов**: поддержка загрузки любых шрифтов (`.ttf`, `.otf`) с мгновенным применением ко всему интерфейсу.
- **Темы оформления**: Светлая, Тёмная и глубокая **AMOLED Black** с поддержкой Dynamic Color.

### 🛡️ Маршрутизация и Сеть
- **Активные переключатели DNS и LAN**:
  - **Защищенный DNS (DoH)**: шифрованные запросы Cloudflare (`1.1.1.1`) и Google (`8.8.8.8`) через туннель с возможностью включения и отключения в настройках.
  - **Обход локальной сети (LAN)**: настраиваемый прямой доступ к домашним устройствам и локальным подсетям (`192.168.*`, `10.*`, `172.16.*`).
- **Обход сайтов РФ**: предустановленный пресет для прямого доступа к сервисам рунета без замедления.
- **Настраиваемый таймаут пинга**: интерактивный регулятор от 1 до 5 секунд.

### 📋 Подписки и Серверы
- **Редактирование адреса подписки**: возможность напрямую изменять URL в настройках подписки без удаления и создания заново.
- **Закрепление сверху (Pin)**: закрепление важных подписок над всеми остальными.
- **Каталог User-Agent**: поддержка более 14 вариантов (v2rayN, sing-box, ClashMeta, Shadowrocket, QuantumultX, Surge, FlClash, Chrome, Firefox) + пользовательский ввод.
- **Системный трей**: меню из 3 пунктов («Открыть», «Перезагрузить ядро», «Выйти»), сворачивание в трей при закрытии.
- **Протоколы**: VLESS (Reality, TLS, Vision, gRPC, WebSocket), Hysteria 2 (`hy2://`), Trojan, Shadowsocks, VMess.

---

## 📥 Загрузки (Десктопные платформы)

Готовые релизы компилируются автоматически через GitHub Actions в разделе **[Releases](https://github.com/qkryt/MaterialVless/releases/latest)**:

| Платформа | Файл релиза | Описание |
| :--- | :--- | :--- |
| **Windows x64** | `MaterialVless-Windows-x64-Setup.exe` | Официальный установщик Windows 64-bit |
| **Windows x64** | `MaterialVless-Windows-x64.zip` | Портативная версия с sing-box и Wintun |
| **Windows x86** | `MaterialVless-Windows-x86-Setup.exe` | Официальный установщик Windows 32-bit |
| **Windows x86** | `MaterialVless-Windows-x86.zip` | Портативная версия x86 |
| **Linux x64** | `MaterialVless-Linux-x64.tar.gz` | Дистрибутивы Linux (Ubuntu, Debian, Fedora, Arch) |
| **Linux x86** | `MaterialVless-Linux-x86.tar.gz` | 32-битная версия для Linux |
| **macOS** | `MaterialVless-macOS.zip` | Универсальная сборка (Intel & Apple Silicon) |

---

## 👥 Contributors

- **qkryt** — автор проекта и мейнтейнер.
- **Google Deepmind / Antigravity Agent** — разработка сетевого стека, Wintun интеграции и CI/CD автоматизации.
