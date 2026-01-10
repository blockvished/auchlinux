# Arch Install Scripts

Minimal **automated Arch Linux installation scripts** using `curl | bash`.

> [!WARNING]
> These scripts will **erase your selected disk** and configure partitions, **LUKS**, and **systemd-boot**.
> Use only if you understand what the script does. **Test in a VM first.**

---

## ✅ What this installs

- Base system (**Zen kernel only**, or **Linux + Zen**)
- Basic **LUKS encryption**
- **systemd + systemd-boot** essential setup
- Networking + user creation + sudo setup

---

## 📦 Available installers

### 1) Arch install with (Zen kernel -> my preference)
```bash
curl -fsSL "https://raw.githubusercontent.com/blockvished/auchlinux/main/install.sh?$(date +%s)" | bash
```

### 2) Install both kernels (Linux is default + Zen)
```bash
curl -fsSL "https://raw.githubusercontent.com/blockvished/auchlinux/main/install-both.sh?$(date +%s)" | bash
```

### You can edit and run locally

```bash
curl -fsSL "https://raw.githubusercontent.com/blockvished/auchlinux/main/install.sh" -o install.sh

#or

curl -fsSL "https://raw.githubusercontent.com/blockvished/auchlinux/main/install-both.sh" -o install.sh

chmod +x install.sh
./install.sh
```