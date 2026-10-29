# MaterialVless 2.1 (Micropatch 2.1)

<p align="center">
  <b><a href="README_EN.md">English</a> | <a href="README.md">Русский</a></b>
</p>

<p align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="MaterialVless Logo" />
</p>

<p align="center">
  <b>Modern, high-performance desktop VPN client for VLESS / Reality / gRPC / Hysteria 2 powered by the sing-box core in Google's Material Design 3 (Material You).</b>
</p>

<p align="center">
  <a href="https://github.com/qkryt/MaterialVless/releases/latest"><img src="https://img.shields.io/github/v/release/qkryt/MaterialVless?style=for-the-badge&color=6750A4" alt="Release" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/sing--box-1.14.4-00D2FF?style=for-the-badge" alt="sing-box" />
  <img src="https://img.shields.io/badge/Wintun-0.14.1-4CAF50?style=for-the-badge" alt="Wintun" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 🌟 What's New in Micropatch 2.1

### 🔗 Deep-Linking & Protocol Schemes (`material://` and `happ://`)
MaterialVless 2.1 registers system-wide protocol handlers for `material://` and `happ://`, enabling remote control from web browsers, scripts, and automation tools:

| Action | URL Schemes | Description |
| :--- | :--- | :--- |
| **Start Tunnel** | `material://connect`<br>`happ://connect`<br>`material://open`<br>`happ://open` | Connects to the currently selected VPN server |
| **Stop Tunnel** | `material://disconnect`<br>`happ://disconnect`<br>`material://close`<br>`happ://close` | Disconnects VPN and restores system routing |
| **Toggle Tunnel** | `material://toggle`<br>`happ://toggle` | Toggles VPN connection on or off |
| **Add Server / Profile** | `material://add{URL}`<br>`happ://add{URL}`<br>`material://crypt{URL}`<br>`happ://crypt{URL}`<br>`material://crypt2{URL}`<br>`happ://crypt2{URL}` | Automatically imports subscription URL, direct node, or encrypted payload |
| **Custom Routing** | `material://routing/add/{base64}`<br>`happ://routing/add/{base64}`<br>`material://routing/onadd/{base64}`<br>`happ://routing/onadd/{base64}` | Dynamically adds direct routing rule from base64 string |
| **Clear Routing** | `material://routing/off`<br>`happ://routing/off` | Clears all dynamic custom routing rules |

### 🌐 Preferred IP Strategy
- **Auto (IPv4 / IPv6)**: Dynamically resolves both IPv4 and IPv6 based on network availability.
- **IPv4 Only**: Forces pure IPv4 resolution and routing for maximum compatibility with networks where IPv6 is degraded.
- **Prefer IPv6**: Prioritizes IPv6 routes for networks with native IPv6 connectivity.

### 🎨 Material You Design & Customization
- **Dynamic Accent Color Seeds**: Pick from 8 curated Material You palettes (*Deep Purple, Electric Blue, Emerald Teal, Forest Green, Sunset Orange, Ruby Crimson, Cyber Pink, Graphite Slate*).
- **6 Working Built-in Fonts**: Includes `Google Sans`, `Roboto`, `Segoe UI`, `Consolas`, `Arial`, and `Tahoma`.
- **Custom Font Loader**: Import any `.ttf` or `.otf` font file with instant system-wide preview and application.
- **Bilingual Interface**: Full English (EN) and Russian (RU) localization switcher.
- **Theme Modes**: System, Light, Dark, and deep **AMOLED Black** for OLED displays.

### ⚙️ Enhanced Subscription & Profile Management
- **Responsive URL Input**: Smart layout container with multi-line expandability for long subscription and configuration tokens.
- **Per-Subscription User-Agent**: Set custom HTTP User-Agent per subscription provider while retaining a global fallback.
- **Automated Startup Triggers**:
  - Auto-update subscription on application launch.
  - Auto-ping subscription nodes on launch.
  - Auto-connect to the lowest ping server on launch.
- **Hardware ID (HWID) Control**: Toggle `X-HWID` headers with optional custom/alternative hardware identifier per profile.

### 🛡️ Single Instance & Windows Process Management
- **Single Instance Enforcement**: Prevents multiple instances via a dedicated loopback IPC server (`127.0.0.1:49281`). Opening an additional instance instantly brings the existing window to the foreground and forwards any deep links.
- **Stale Instance Recovery**: Automatically cleans up and recovers if a prior instance was terminated abnormally.
- **Seamless In-App Updater**: Downloads `.exe` updates with a real-time progress bar dialog, launches the installer, and closes the current application cleanly.

---

## 🚀 Key Features

- **Sing-box Core v1.14.4 & Wintun Driver v0.14.1**: Kernel-level TUN driver providing ultra-low latency, full UDP forwarding, and wire-speed throughput.
- **Wide Protocol Support**:
  - `vless://` (Reality, XTLS, Vision, gRPC, WebSocket)
  - `hysteria2://` / `hy2://` (High-speed UDP obfuscation)
  - `ss://` (Shadowsocks 2022, AEAD)
  - `trojan://`
  - `vmess://`
  - Encrypted subscription formats (`crypt://`, `crypt2://`)
- **Smart Routing & Bypass**:
  - **Secure DNS (DoH)**: Cloudflare (`1.1.1.1`) and Google (`8.8.8.8`) over HTTPS inside the tunnel.
  - **Bypass LAN**: Automatic exclusion of local subnets (`192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12`).
  - **Country-based Direct Routing**: Bypass domestic services without speed loss.
- **Clean System Tray**:
  - Minimized background operation.
  - Quick action menu: Open, Restart Core, Exit.

---

## 📥 Downloads

Pre-built binaries are compiled on GitHub Actions:

| Platform | Download File | Details |
| :--- | :--- | :--- |
| **Windows x64** | `MaterialVless-Windows-x64-Setup.exe` | Recommended installer for 64-bit Windows |
| **Windows x64** | `MaterialVless-Windows-x64.zip` | Portable version with embedded sing-box & Wintun |
| **Windows x86** | `MaterialVless-Windows-x86-Setup.exe` | 32-bit Windows installer |
| **Windows x86** | `MaterialVless-Windows-x86.zip` | 32-bit portable edition |
| **Linux x64** | `MaterialVless-Linux-x64.tar.gz` | Linux x86_64 binaries (Ubuntu, Debian, Fedora, Arch) |
| **Linux x86** | `MaterialVless-Linux-x86.tar.gz` | Linux 32-bit edition |
| **macOS** | `MaterialVless-macOS.zip` | Universal macOS binary (Apple Silicon & Intel) |

---

## 🛠️ Building from Source

### Prerequisites
1. [Flutter SDK](https://flutter.dev/) (>= 3.22.0)
2. [Go](https://go.dev/) (>= 1.22)
3. Visual Studio 2022 with Desktop development with C++
4. [Inno Setup 6](https://jrsoftware.org/isdl.php) (for creating Windows installers)

### Build Commands
```bash
# Clone the repository
git clone https://github.com/qkryt/MaterialVless.git
cd MaterialVless

# Install Flutter dependencies
flutter pub get

# Build Windows Release binary
flutter build windows --release

# Compile Inno Setup installer
iscc windows/installer_x64.iss
```

---

## 👥 Contributors

- **qkryt** — Lead Developer & Maintainer.
- **Google Deepmind / Antigravity Agent** — Core network engine, Wintun integration, Material Design 3 UI, and CI/CD pipelines.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
