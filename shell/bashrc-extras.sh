# Custom ~/.bashrc additions for the Sway setup.
# Source this from ~/.bashrc, or paste the pieces you want.
# Trim the PATH lines to what is actually installed on the machine.

export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.local/kitty.app/bin"   # kitty official installer
export EDITOR=vim

# Work around Codex TUI double-Backspace handling in foot/Sway.
codex() {
    CODEX_TUI_DISABLE_KEYBOARD_ENHANCEMENT=1 command codex "$@"
}

# UVA Anywhere VPN (Cisco AnyConnect via openconnect).
# Needs: openconnect, plus private certs copied manually (NOT in this repo):
#   ~/.cert/uva-vpn.p12          client cert from SecureW2 portal (passphrase < 15 chars)
#   ~/.cert/uva-anywhere-ca.pem  CA bundle for the gateway's emSign/InCommon chain
# Auth flow: cert passphrase -> Netbadge login -> Duo (type 'push').
# Usage: uva-vpn [up|down|status]   (bare `uva-vpn` connects; Ctrl-C disconnects)
uva-vpn() {
    local cert="$HOME/.cert/uva-vpn.p12"
    local gw="uva-anywhere-1.itc.virginia.edu"
    case "${1:-up}" in
        up|"")
            if [ ! -r "$cert" ]; then
                echo "uva-vpn: cert not found at $cert" >&2
                return 1
            fi
            echo "Connecting to UVA Anywhere VPN (Ctrl-C to disconnect)..."
            echo "  cert passphrase -> Netbadge login -> Duo (type 'push')"
            sudo openconnect --protocol=anyconnect --certificate "$cert" --cafile "$HOME/.cert/uva-anywhere-ca.pem" "$gw"
            ;;
        down)
            if pgrep -x openconnect >/dev/null; then
                sudo pkill -SIGINT -x openconnect && echo "UVA VPN disconnected."
            else
                echo "UVA VPN: nothing running."
            fi
            ;;
        status)
            if pgrep -x openconnect >/dev/null; then
                echo "UVA VPN: connected"
                ip -brief addr show | grep -E '^tun' || true
                echo "Public org: $(curl -s --max-time 5 https://ipinfo.io/org)"
            else
                echo "UVA VPN: not connected"
            fi
            ;;
        *)
            echo "Usage: uva-vpn [up|down|status]" >&2
            return 2
            ;;
    esac
}

# Prism Launcher (Minecraft) AppImage — see local/share/applications/prismlauncher.desktop
alias prism="~/.local/bin/PrismLauncher-Linux-x86_64.AppImage"
