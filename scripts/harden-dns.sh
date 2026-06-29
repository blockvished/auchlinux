#!/usr/bin/env bash
# =============================================================================
#  Encrypted DNS for AuchLinux — systemd-resolved + DNS-over-TLS + DNSSEC
#  Replaces plaintext DNS (e.g. an institutional 172.16.x resolver) with
#  authenticated, encrypted lookups. Coexists with Tailscale (which switches to
#  split-DNS via resolved: MagicDNS for the tailnet, DoT for everything else).
#
#  Usage:
#     sudo ./scripts/harden-dns.sh            # apply
#     sudo ./scripts/harden-dns.sh --revert   # undo (back to NM-managed DNS)
#     sudo ./scripts/harden-dns.sh --status   # show current resolver state
#
#  Safe to re-run (idempotent). Run after a fresh install (post-install step).
# =============================================================================
set -euo pipefail

RESOLVED_CONF=/etc/systemd/resolved.conf.d/dns-over-tls.conf
NM_CONF=/etc/NetworkManager/conf.d/dns.conf

c(){ printf '\033[0;36m[dns]\033[0m %s\n' "$*"; }
ok(){ printf '\033[0;32m[ok]\033[0m  %s\n' "$*"; }
warn(){ printf '\033[1;33m[!]\033[0m  %s\n' "$*"; }

# Re-exec as root if needed.
[[ $EUID -eq 0 ]] || exec sudo "$0" "$@"

case "${1:-apply}" in
  --status)
    resolvectl status 2>/dev/null | grep -E "Current DNS|DNS Servers|DNSOverTLS|DNSSEC|Protocols" || true
    echo "resolv.conf -> $(readlink -f /etc/resolv.conf)"
    exit 0 ;;
  --revert)
    c "Reverting to NetworkManager-managed DNS…"
    rm -f "$RESOLVED_CONF" "$NM_CONF"
    systemctl disable --now systemd-resolved 2>/dev/null || true
    # let NetworkManager own resolv.conf again
    rm -f /etc/resolv.conf
    systemctl restart NetworkManager
    systemctl restart tailscaled 2>/dev/null || true
    ok "Reverted. (Re-run without --revert to re-apply.)"
    exit 0 ;;
esac

# 1. DoT + DNSSEC resolver config (multiple DoT-capable providers + fallback)
c "Writing $RESOLVED_CONF …"
install -d /etc/systemd/resolved.conf.d
cat > "$RESOLVED_CONF" <<'EOF'
[Resolve]
# Preference order: Quad9 -> Cloudflare -> NextDNS. No Google.
# NextDNS here is the generic (unfiltered) anycast endpoint. For YOUR filtered
# NextDNS profile, sign up (free) and replace the hostname with your config id:
#   45.90.28.0#<id>.dns.nextdns.io  45.90.30.0#<id>.dns.nextdns.io
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 45.90.28.0#dns.nextdns.io 45.90.30.0#dns.nextdns.io
# Empty FallbackDNS = disable systemd's built-in fallback (which includes Google).
FallbackDNS=
DNSOverTLS=yes
DNSSEC=allow-downgrade
Cache=yes
EOF

# 2. enable + (re)start the resolver
#    NB: use restart, not `enable --now` — if resolved is already running (e.g. a
#    re-run after editing the config), `--now` won't reload it and you'd keep the
#    OLD servers. restart forces it to read the new config.
c "Enabling + restarting systemd-resolved…"
systemctl enable systemd-resolved
systemctl restart systemd-resolved
resolvectl flush-caches 2>/dev/null || true

# 3. point resolv.conf at the resolved stub (Tailscale then uses the resolved
#    D-Bus API for split-DNS instead of overwriting this file)
c "Linking /etc/resolv.conf -> resolved stub…"
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 4. hand DNS resolution to resolved in NetworkManager
c "Configuring NetworkManager dns=systemd-resolved…"
install -d /etc/NetworkManager/conf.d
cat > "$NM_CONF" <<'EOF'
[main]
dns=systemd-resolved
EOF
systemctl restart NetworkManager

# 5. let Tailscale re-detect resolved (split-DNS mode)
systemctl restart tailscaled 2>/dev/null || true

# 6. verify
sleep 2
c "Resolver status:"
resolvectl status 2>/dev/null | grep -E "Current DNS|DNS Servers|DNSOverTLS|DNSSEC" || true
if resolvectl query archlinux.org >/dev/null 2>&1; then
  ok "Encrypted DNS active (DoT + DNSSEC). Test query for archlinux.org succeeded."
else
  warn "Test query failed — if you're behind a captive portal, sign in first."
  warn "If a network blocks port 853, temporarily: set DNSOverTLS=opportunistic in $RESOLVED_CONF, or run this script with --revert."
fi
echo
c "Captive-portal tip: strict DoT can stall portal sign-in pages. If a café/hotel"
c "Wi-Fi won't load, run '--revert' for that session (or switch to opportunistic)."
