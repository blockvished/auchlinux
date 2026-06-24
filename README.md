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

## 📦 Available installer

### 1) Run installer directly (Zen/Stable/Both selection is interactive)
```bash
curl -fsSL "https://raw.githubusercontent.com/blockvished/auchlinux/main/install.sh?$(date +%s)" | bash
```

### Or edit and run locally

```bash
curl -fsSL "https://raw.githubusercontent.com/blockvished/auchlinux/main/install.sh" -o install.sh
chmod +x install.sh
./install.sh
```