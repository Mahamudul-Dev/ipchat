# IPChat

<div align="center">
  <img src="assets/logo.jpg" alt="IPChat Logo" width="180"/>
  <p><strong>A secure, anonymous, and ephemeral terminal-based E2EE group chat application.</strong></p>
  <p>Operates over a custom Zero-Knowledge UDP relay on Port 443 (HTTP/3 QUIC disguise) to bypass NAT and strict firewalls without port forwarding, third-party accounts, or VPNs.</p>
</div>

---

## ✨ Features

* **Military-Grade E2EE:** Messages are encrypted locally using **AES-256-GCM**. The encryption key is derived from your Room Password via SHA-256 and never leaves your device.
* **Zero-Knowledge Architecture:** The relay server only routes raw, blind binary blobs. It does not possess encryption keys, usernames, passwords, or message content.
* **Stealth Traffic (UDP Port 443):** Chat packets run over UDP Port 443, camouflaging connections to look like standard HTTP/3 (QUIC) traffic to network firewalls and ISPs.
* **NAT Traversal & Keep-Alive:** Built-in background heartbeats keep router NAT port mappings open automatically during prolonged silence.
* **Persistent Relay Configuration:** Use the official public relay (`ipchatrelay.octetit.com`) out-of-the-box, or register your own self-hosted relay with a single command.
* **Stylish Terminal UI:** Features clean 256-color ANSI rendering, inline timestamps, and a real-time prompt.
* **Zero Persistence:** Everything lives purely in volatile memory. When you press `Ctrl + C`, session keys and message history vanish permanently.

---

## 🚀 Client Installation

### 1. Arch Linux / Manjaro (AUR)
```bash
yay -S ipchat-bin
# or
paru -S ipchat-bin
```

### 2. Debian / Ubuntu (APT)
Download the latest `.deb` package from [GitHub Releases](https://github.com/Mahamudul-Dev/ipchat/releases):
```bash
wget https://github.com/Mahamudul-Dev/ipchat/releases/latest/download/ipchat_0.1.0_amd64.deb
sudo dpkg -i ipchat_0.1.0_amd64.deb
```

### 3. Snap Store
```bash
sudo snap install ipchat
```

### 4. Direct Binary Download (Linux / macOS / Windows)
Grab pre-compiled standalone executables from the [Releases Page](https://github.com/Mahamudul-Dev/ipchat/releases):
* **Linux (x64 / arm64)**
* **macOS (Apple Silicon / Intel)**
* **Windows (x64)**

### 5. Build From Source
```bash
git clone https://github.com/Mahamudul-Dev/ipchat.git
cd ipchat
dart pub get
dart compile exe bin/ipchat.dart -o ipchat
sudo mv ipchat /usr/local/bin/
```

---

## 🛡️ Self-Hosting the Relay Server

You can easily host your own private relay server using Docker, Docker Compose, or native Dart.

### Option A: Docker (Recommended)

Run the containerized relay directly from GitHub Container Registry:

```bash
docker run -d \
  --name ipchat-relay \
  --restart unless-stopped \
  -p 443:443/udp \
  ghcr.io/mahamudul-dev/ipchat-relay:latest
```

### Option B: Docker Compose

Create a `docker-compose.yml` file:

```yaml
services:
  ipchat-relay:
    image: ghcr.io/mahamudul-dev/ipchat-relay:latest
    container_name: ipchat-relay
    restart: unless-stopped
    ports:
      - "443:443/udp"
    environment:
      - PORT=443
```

Run:
```bash
docker compose up -d
```

### Option C: Bare Metal (Linux VPS)

```bash
# Allow UDP port 443 in firewall
sudo ufw allow 443/udp

# Compile and launch
dart compile exe bin/relay.dart -o relay
nohup ./relay > relay.log 2>&1 &
```

---

## ⚙️ Connecting to a Self-Hosted Relay

Normal users can launch `ipchat` directly to use the official relay server (`ipchatrelay.octetit.com`).

If you host your own relay, configure your client using the CLI:

### 1. Register Your Server Permanently
```bash
# Register an IP or domain name:
ipchat set-relay my-relay.example.com

# Or specify a custom port:
ipchat set-relay 192.168.1.100:8443
```
*Your choice is saved persistently to `~/.config/ipchat/config.json` (or `%APPDATA%\ipchat\config.json` on Windows).*

### 2. Check Active Relay
```bash
ipchat get-relay
```

### 3. Reset to Official Relay
```bash
ipchat reset-relay
```

### 4. One-Time Session Override
```bash
ipchat --relay 1.2.3.4 --port 443
```

---

## 💻 Usage

### 1. Launch IPChat
```bash
ipchat
```

### 2. Enter Session Details
1. **Username:** Display name shown to other participants (press `Enter` for a random anonymous tag like `Anon_1234`).
2. **Secret Room Password:** A shared passphrase (min. 6 characters).
   * *The password derives the 256-bit AES key and the room ID.*
   * *Anyone entering the exact same password automatically joins your encrypted room.*

### 3. Exit Cleanly
Press `Ctrl + C` at any time to sever connection, notify the relay, erase the encryption keys from memory, and terminate.

---

## 🔐 Cryptography & Privacy Design

1. **Key Derivation:**
   $$\text{Key} = \text{SHA-256}(\text{Password})$$
2. **Zero-Knowledge Room ID:**
   $$\text{Room ID} = \text{SHA-256}(\text{Key})[0..16]$$
   *Because the room ID is a one-way hash of the key, the relay server never possesses the password or decryption key.*
3. **Payload Structure:**
   $$\text{Transmission} = \text{Base64}(\text{IV}_{16}) + \text{Base64}(\text{AES-256-GCM}(\text{Data}))$$
4. **Relay Inactivity Pruning:**
   The relay maintains an active memory table. Disconnected clients or clients inactive for over 60 seconds are automatically evicted.

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
