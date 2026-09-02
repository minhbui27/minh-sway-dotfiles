#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
backup_root="$HOME/.dotfiles-backup"
stamp=$(date '+%Y%m%d-%H%M%S')
backup_dir="$backup_root/$stamp"
dry_run=0
source_home="/home/minhbui"

if [ "${1:-}" = "--dry-run" ]; then
    dry_run=1
fi

log() {
    printf '%s\n' "$1"
}

run() {
    if [ "$dry_run" = "1" ]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

backup_path() {
    path=$1
    [ -e "$path" ] || [ -L "$path" ] || return 0

    rel=${path#"$HOME"/}
    backup_dest="$backup_dir/$rel"
    run mkdir -p "$(dirname "$backup_dest")"
    run cp -a "$path" "$backup_dest"
}

copy_file() {
    src=$1
    dest=$2
    rewrite=${3:-text}

    log "install $dest"
    backup_path "$dest"
    run mkdir -p "$(dirname "$dest")"

    if [ "$dry_run" = "1" ]; then
        printf '[dry-run] copy %s -> %s\n' "$src" "$dest"
        return
    fi

    case "$rewrite" in
        binary)
            cp -a "$src" "$dest"
            ;;
        *)
            sed "s|$source_home|$HOME|g" "$src" > "$dest"
            chmod --reference="$src" "$dest" 2>/dev/null || true
            ;;
    esac
}

copy_tree() {
    src_dir=$1
    dest_dir=$2

    [ -d "$src_dir" ] || return 0

    find "$src_dir" -type f | while IFS= read -r src; do
        rel=${src#"$src_dir"/}
        case "$rel" in
            __pycache__/*|*.pyc)
                continue
                ;;
            assets/*)
                copy_file "$src" "$dest_dir/$rel" binary
                ;;
            *)
                copy_file "$src" "$dest_dir/$rel" text
                ;;
        esac
    done
}

log "repo: $repo_dir"
log "backup: $backup_dir"

run mkdir -p "$backup_dir"

copy_tree "$repo_dir/config/sway" "$HOME/.config/sway"
copy_tree "$repo_dir/config/fcitx5" "$HOME/.config/fcitx5"
copy_tree "$repo_dir/config/kitty" "$HOME/.config/kitty"
copy_tree "$repo_dir/config/terminator" "$HOME/.config/terminator"
copy_tree "$repo_dir/config/mako" "$HOME/.config/mako"
copy_file "$repo_dir/config/mozc/ibus_config.textproto" "$HOME/.config/mozc/ibus_config.textproto" text

copy_tree "$repo_dir/local/bin" "$HOME/.local/bin"
copy_tree "$repo_dir/local/share/applications" "$HOME/.local/share/applications"

copy_file "$repo_dir/docs/sway-shortcuts.md" "$HOME/sway-shortcuts.md" text

log "done"
log "optional lid-suspend disable:"
log "  sudo install -Dm644 systemd/logind.conf.d/10-sway-no-lid-suspend.conf /etc/systemd/logind.conf.d/10-sway-no-lid-suspend.conf"
log "  reboot afterward, or restart systemd-logind from a TTY"
log "optional s2idle/internal keyboard wake:"
log "  sudo install -Dm755 systemd/enable-wake-sources.sh /usr/local/bin/minh-enable-wake-sources"
log "  sudo install -Dm644 systemd/system/minh-wake-sources.service /etc/systemd/system/minh-wake-sources.service"
log "  sudo systemctl enable --now minh-wake-sources.service"
log "optional deep sleep (if resume from s2idle hangs; see README Suspend section):"
log "  sudo install -Dm644 systemd/tmpfiles.d/mem-sleep.conf /etc/tmpfiles.d/mem-sleep.conf"
log "shell extras (uva-vpn, aliases, PATH): source shell/bashrc-extras.sh from ~/.bashrc"
log "reload sway with: swaymsg reload"
