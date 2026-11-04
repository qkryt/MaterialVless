# MaterialVless 3.2.0 (Material Design 3 VPN Client)

<p align="center">
  <b>English | <a href="README.md">Русский</a></b>
</p>

<p align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="MaterialVless Logo" />
</p>

<p align="center">
  <b>Modern high-performance multiplatform desktop VPN client for VLESS / Reality / gRPC based on official Xray-core (XTLS) with native Wintun TUN mode, fluid alive animations, bundled Visual C++ runtime libraries, and Google Material Design 3 (Material You).</b>
</p>

<p align="center">
  <a href="https://github.com/qkryt/MaterialVless/releases/latest"><img src="https://img.shields.io/github/v/release/qkryt/MaterialVless?style=for-the-badge&color=6750A4" alt="Release" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Xray--core-v26.10.21-6750A4?style=for-the-badge" alt="Xray-core" />
  <img src="https://img.shields.io/badge/Visual%20C%2B%2B-Bundled-blue?style=for-the-badge" alt="VC++ Bundled" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

---

## 🌟 What's New in Version 3.2.0

* **Active Sliding Worker Pool for Ping**:
  * Configurable concurrent ping threads (3, 5, 10, 15, 20, 30, 50).
  * High-efficiency async worker pipeline: if fast servers reply while one is still waiting on timeout, free workers instantly pick the next servers without waiting.
  * Real-time UI updates: latency values appear live as each node responds.
* **Server Sorting by Ping in "Ping & Latency" Tab**:
  * Added dedicated card in Ping settings with toggle "Sort servers by ping" and order selection: ascending (lowest ping first) or descending.
  * Real-time sorting applies to both dashboard and node list, placing unmeasured or failed nodes at the end.
* **High-Precision Ping Engine**:
  * Migrated to `IOClient` with automatic response stream draining and safe socket lifecycle.
  * Sub-millisecond precision (`elapsedMicroseconds / 1000`).
* **Fluid In-Place Settings Transition**:
  * Fixed animation — elegant Material 3 Fade & Subtle Scale transition without horizontal displacement over the server list.
* **Transparent Settings Background**:
  * Custom wallpaper now smoothly shines through the settings screen and cards.

## 🌟 What's New in Version 3.1.2

### 🏷️ Fixed Subscription Tab Names and Server Count Display
- Restored accurate subscription names and server counters on top navigation chips: `Name (count)`.
- Manual servers tab accurately displays `Servers (count)`.

### 🌐 Complete UI Localization Across All Settings
- All settings entries now display localized names and descriptions without raw keys:
  - **Start with Windows**: localized title and startup explanation.
  - **Minimize to tray on close**: clear description for close button behavior.
  - **Start minimized to tray**: background startup toggle and explanation.
  - **Device HWID transmission**: anonymous device identifier toggle.
  - **Subscription auto-update**: auto-sync on startup explanation.
  - **IP Resolution Strategy**: selection for Auto, IPv4, and IPv6.

---

## 🌟 What's New in Version 3.1.1

### 🛠️ Out-of-the-Box Visual C++ Runtime Bundling
- Official **Microsoft Visual C++** runtime libraries (`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140_1.dll`, `msvcp140_2.dll`, `vcomp140.dll`) are bundled directly into both Windows portable zip packages and setup installers.
- Launches seamlessly on fresh Windows installations without *"VCRUNTIME140.dll was not found"* errors.
- Inno Setup installers include silent `vc_redist` detection and installation.

### 🔄 Reorder Subscriptions via Long-Press Drag & Drop
- Long-pressing on any subscription chip in the top navigation panel lifts it up:
  - Drag horizontally to swap positions with other subscriptions (`ReorderableListView` + `ReorderableDelayedDragStartListener`).
  - New custom order is automatically persisted across application restarts.
  - A quick tap still immediately selects and views the subscription.

### 🎬 Visual Refinements & Enhanced Animations
- **Clean Connection Visuals**: During connection establishment (`CONNECTING...`), the outer busy circle around the power button is removed, keeping focus on the clean internal spinner.
- **Cinematic Settings Transition**: Opening Settings triggers a smooth Material 3 slide-and-fade animation (`SlideTransition` + `FadeTransition`, `320ms`, `Curves.easeOutCubic`).
- **Dialog Animations**: Add subscription and JSON viewer dialogs open with soft scale (`ScaleTransition` 0.92 ➔ 1.0) and fade transitions.
- **Smooth Server List Cross-Fading**: Switching subscription tabs gently cross-fades the server list with `AnimatedSwitcher`.
- **Minimalist Clean Header**: Removed the top-left icon and resized **MaterialVless** brand typography to a refined size (`14px`, `FontWeight.w600`).

---

## 🌟 What's New in Version 3.1 & 3.0

### 💫 Fluid Alive Animations
- **Breathing Connection Aura**: Pulsing radiant glow expanding gently around the main power button (`_pulseController`) while a secure VPN tunnel is active.
- **Rotating Radar Ring**: Gradient busy ring animation (`_BusyRingPainter`) spinning during latency tests.
- **Interactive Button Response**: Smooth scaling (`AnimatedScale`) and dynamic elevation/shadow response on mouse cursor hover.
- **Seamless State Switching**: Zero-flicker transitions via `AnimatedSwitcher` across connection states (*CONNECTING...*, *CONNECTED*, *CONNECT*) and session timer.
- **Smooth Theme Morphing**: Animated color transitions when toggling Light, Dark, and AMOLED themes without page reload.

### 🎴 Enhanced M3 Rounded Server Cards
- **Generous Corner Radii**: Server cards feature rounded corners — `20px` when selected and `16px` at rest.
- **Selection Morphing Animation**: Smooth `AnimatedContainer` transition when choosing a node — dynamic shape adaptation, accent tint, contour border, and subtle drop shadow.
- **Animated Radio Checkmark**: Selection indicator smoothly scales in and out using `ScaleTransition`.
- **Rounded Flags and Badges**: Country flag containers feature `12px` border radius, and ping badges have `8px` rounded corners.

### ⚡ Comprehensive Multi-Mode Ping System (4 Testing Methods)
Professional latency measurement with method configuration in the dedicated **"Ping & Latency"** settings tab:
1. **via Proxy (GET)** — End-to-end HTTP GET request sent directly through the encrypted proxy tunnel (verifies actual bidirectional data throughput).
2. **via Proxy (HEAD)** — Rapid HTTP HEAD request through the proxy without response payload overhead.
3. **TCP Handshake** — Direct TCP handshake with target endpoint to assess raw physical link latency.
4. **ICMP Ping** — Standard OS-level echo request.

Displayed on server tiles in clean format:
`Time (XXXX ms/icon)` with adaptive color badges (green `<120ms`, lime `<250ms`, amber `<450ms`, red `>450ms`, and timeout `Timeout`).

### 🖱️ Contextual Server Action Modal (Right-Click) & Quick Selection (Left-Click)
- **Left Click (LKM)**: Instantly selects the server as active for connection.
- **Right Click (RKM) / Long Press / "⋮" Button**: Opens the Material You action modal with `28px` corner radius:
  - ⚡ **Measure Ping**: Modal auto-closes instantly, navigates to the node in the list, marks it as selected, and triggers a live latency test with `Time (...)` indicator.
  - 📋 **JSON Configuration**: View complete outbound Xray JSON configuration with one-click clipboard copying.
  - 🔌 **Select Server**: Make this node active for connecting.
  - 🔗 **Copy Node Link**: Copies the raw URI (`vless://...`).
  - 🗑️ **Delete Node**: Removes manually added custom servers.

### 💖 Support the Project
A quick **"Support"** button in the top app bar takes you directly to the donation page:  
👉 [Support the author on DonationAlerts](https://www.donationalerts.com/r/qkryt)

---

## 🔗 Protocol URL Schemes & Deep-Linking (`material://` and `happ://`)

| Action | URL Schemes | Description |
| :--- | :--- | :--- |
| **Start Tunnel** | `material://connect`<br>`happ://connect`<br>`material://open`<br>`happ://open` | Connects selected VPN server |
| **Stop Tunnel** | `material://disconnect`<br>`happ://disconnect`<br>`material://close`<br>`happ://close` | Disconnects tunnel and restores OS routing |
| **Toggle State** | `material://toggle`<br>`happ://toggle` | Toggles tunnel connection |
| **Add Server / Subscription** | `material://add{URL}`<br>`happ://add{URL}`<br>`material://crypt{URL}`<br>`happ://crypt{URL}`<br>`material://crypt2{URL}`<br>`happ://crypt2{URL}` | Automatically imports subscription URL, raw node URI, or encrypted profile |
| **Add Routing Rule** | `material://routing/add/{base64}`<br>`happ://routing/add/{base64}` | Dynamically adds direct bypass domain rule from base64 string |
| **Reset Routing** | `material://routing/off`<br>`happ://routing/off` | Clears all dynamic routing rules |

---

## 🚀 Core Features

- **Xray Core v26.10.21 (XTLS) with Native Wintun TUN**: Routes 100% of entire system traffic (including Telegram, browsers, GitHub, Discord, Steam, and online games).
- **Supported Protocols**:
  - `vless://` (Reality, XTLS Vision, gRPC, WebSocket)
  - `hysteria2://` / `hy2://` (High-speed UDP protocol)
  - `ss://` (Shadowsocks 2022, AEAD)
  - `trojan://`
  - `vmess://`
  - Encrypted subscription formats (`crypt://`, `crypt2://`)
- **Smart Routing & Unblocking**:
  - **Encrypted DNS (DoH)**: Cloudflare (`1.1.1.1`) and Google (`8.8.8.8`) over HTTPS.
  - **Local Area Network (LAN) Bypass**: Automatic exclusion of private ranges (`192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12`).
  - **Customizable Routing Presets**: Direct access for regional banking and government resources without performance degradation.
- **Appearance Customization**:
  - Custom UI background wallpapers (JPG, PNG, GIF) with adjustable dimming overlay.
  - 8 Material You color palettes.
  - Google Sans, Roboto, Segoe UI, Consolas, and custom `.ttf` / `.otf` font file importer.
  - True pitch-black **AMOLED Black** mode for OLED screens.

---

## 📥 Download Pre-built Binaries

Pre-compiled packages are automatically built with GitHub Actions in **[Releases](https://github.com/qkryt/MaterialVless/releases/latest)**:

| Platform | File | Description |
| :--- | :--- | :--- |
| **Windows x64** | `MaterialVless-Windows-x64-Setup.exe` | Recommended installer with bundled Visual C++ libraries |
| **Windows x64** | `MaterialVless-Windows-x64.zip` | Portable package with Xray-core and VC++ DLLs |
| **Windows x86** | `MaterialVless-Windows-x86-Setup.exe` | Installer for 32-bit Windows |
| **Windows x86** | `MaterialVless-Windows-x86.zip` | Portable package for Windows x86 with VC++ DLLs |
| **Linux x64** | `MaterialVless-Linux-x64.tar.gz` | Linux x86_64 archive (Ubuntu, Debian, Fedora, Arch) |
| **Linux x86** | `MaterialVless-Linux-x86.tar.gz` | Linux 32-bit archive |
| **macOS** | `MaterialVless-macOS.zip` | Universal macOS archive (Apple Silicon and Intel) |

---

## 🛠️ Building from Source

### Prerequisites
1. [Flutter SDK](https://flutter.dev/) (>= 3.22.0)
2. [Go](https://go.dev/) (>= 1.22)
3. Visual Studio 2022 with Desktop development with C++
4. [Inno Setup 6](https://jrsoftware.org/isdl.php) (for Windows installers)

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

## 📄 License

This project is licensed under the open-source [MIT License](LICENSE).
