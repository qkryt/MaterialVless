# MaterialVless 2.0 (Qt6 Edition)

<p align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="MaterialVless Logo" />
</p>

<p align="center">
  <b>Современный полнофункциональный десктопный клиент VLESS / Reality / gRPC / Hysteria на базе нативного фреймворка Qt6 и высокопроизводительного ядра sing-box 1.14.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/qkryt/MaterialVless?style=for-the-badge&color=3574F0" alt="Release" />
  <img src="https://img.shields.io/badge/Qt-6.x-41CD52?style=for-the-badge&logo=qt" alt="Qt6" />
  <img src="https://img.shields.io/badge/Python-3.12+-3776AB?style=for-the-badge&logo=python" alt="Python" />
  <img src="https://img.shields.io/badge/sing--box-1.14-00D2FF?style=for-the-badge" alt="sing-box" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 🚀 Особенности и возможности версии 2.0

### 🎨 Нативный интерфейс Qt6 (Без Flutter)
- **Современный стиль Qt6 Fusion**: графитовая тёмная тема, четкие 1px границы, аппаратное ускорение и мгновенный отклик.
- **Управление окном и трей**: меню из 3 пунктов («Открыть», «Перезагрузить ядро», «Выйти»), сворачивание в трей при закрытии.
- **Пользовательские шрифты**: импорт любого шрифта (`.ttf`, `.otf`) с мгновенным применением ко всем элементам интерфейса.
- **Единый официальный логотип**: векторный фирменный знак MaterialVless на окне, в системном трее и в установщике.

### 🛡️ Маршрутизация и Сеть
- **Защищенный DNS (DoH)**: шифрованные запросы Cloudflare (`1.1.1.1`) и Google (`8.8.8.8`) через туннель с активным переключателем в настройках.
- **Обход локальной сети (LAN)**: настраиваемый прямой доступ к локальным IP (`192.168.*`, `10.*`, `172.16.*`).
- **Обход сайтов РФ**: предустановленный пресет для прямого доступа к сервисам рунета без замедления.
- **Настраиваемый таймаут пинга**: интерактивный регулятор от 1 до 5 секунд.

### 📋 Подписки и Серверы
- **Редактирование адреса подписки**: возможность напрямую изменять URL в настройках подписки без удаления и создания заново.
- **Закрепление сверху (Pin)**: закрепление важных подписок над всеми остальными.
- **Каталог User-Agent**: поддержка более 14 вариантов (v2rayN, sing-box, ClashMeta, Shadowrocket, QuantumultX, Surge, FlClash, Chrome, Firefox) + пользовательский ввод.
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

- **Google Deepmind / Antigravity Agent** — разработка архитектуры Qt6, сетевого стека sing-box, Wintun и CI/CD автоматизации.
- **qkryt** — автор проекта и мейнтейнер.
