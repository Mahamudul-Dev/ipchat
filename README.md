# IPChat

A secure, anonymous, and highly styled terminal-based E2EE group chat application. IPChat uses a custom Zero-Knowledge UDP relay to bypass NAT and strict firewalls without requiring third-party tools, router port forwarding, or VPNs.

## ✨ Features

* **Military-Grade E2EE:** Messages are encrypted locally using AES-256-GCM. The encryption key is derived from your Room Password via SHA-256 and never leaves your machine.
* **Zero-Knowledge Architecture:** The relay server routes raw binary blobs. It does not know your password, username, IP logs, or message contents.
* **Stealth Traffic (Port 443):** Chat traffic operates over UDP Port 443, camouflaging your connection to look like standard HTTP/3 (QUIC) web traffic to network sniffers and ISPs.
* **Stylish Terminal UI:** Features an ASCII art banner, 256-color ANSI rendering, dynamic timestamps, and ghost-input cursors for a clean, modern CLI experience.
* **No Database or Storage:** When a session ends or the terminal is closed, all traces vanish. Nothing is ever written to disk.

---

## 🛠️ Architecture

IPChat consists of two components:

1. **The Client (`bin/ipchat.dart`):** Compiles to a native executable. Handles UI, crypto, and UDP socket connections.
2. **The Relay (`relay.dart`):** A lightweight, single-threaded Dart script hosted on a Cloud VPS. It maps incoming hashes to rooms and blindly broadcasts packets to connected peers.

---

## 🚀 Installation & Compilation

You will need the [Dart SDK](https://dart.dev/get-dart) installed on your machine to compile the source code into native executables.

### 1. Client Setup (Linux / macOS)

Clone the repository and compile the client:

```bash
git clone https://github.com/yourusername/ipchat_secure.git
cd ipchat_secure
dart pub get
dart compile exe bin/ipchat.dart -o ipchat
sudo mv ipchat /usr/local/bin/

```

### 2. Client Setup (Windows)

To compile for Windows, either run the above commands on a Windows machine in PowerShell, or use the provided GitHub Actions workflow to automatically build the `.exe` file.

### 3. Server Setup (VPS)

Upload `relay.dart` to your Linux Cloud VPS. Compile and run it in the background:

```bash
dart compile exe relay.dart -o relay
chmod +x relay
ufw allow 443/udp  # Open the stealth port
nohup ./relay > relay.log 2>&1 &

```

*Note: Ensure you update the `vpsIp` constant in `bin/ipchat.dart` to match your server's IP address before compiling the client.*

---

## 💻 Usage

### Starting a Chat

Simply launch the application from your terminal:

```bash
ipchat

```

You will be prompted for:

1. **Username:** The display name your friends will see (leave blank for a random ID).
2. **Secret Room Password:** A shared secret (min. 6 characters). This is used to derive your AES-256 encryption key and the Room ID hash.

### Inviting Friends

Send the compiled `ipchat` binary to your friends. Tell them to run it and enter the **exact same Secret Room Password**. They will instantly join your secure tunnel.

### Exiting

Press `Ctrl + C` to instantly sever the connection, erase the session from memory, and close the port.