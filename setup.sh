
#!/usr/bin/env bash
set -Eeuo pipefail

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"
TMP_CONFIG="$(mktemp)"
trap 'rm -f "$TMP_CONFIG"' EXIT

# KDE Plasma KWin configuration
cat > "$TMP_CONFIG" <<'KWINRC'
[Version]
update_info=kwin.upd:replace-scalein-with-scale,kwin.upd:port-minimizeanimation-effect-to-js,kwin.upd:port-scale-effect-to-js,kwin.upd:port-dimscreen-effect-to-js,kwin.upd:auto-bordersize,kwin.upd:animation-speed,kwin.upd:desktop-grid-click-behavior,kwin.upd:no-swap-encourage,kwin.upd:make-translucency-effect-disabled-by-default,kwin.upd:remove-flip-switch-effect,kwin.upd:remove-cover-switch-effect,kwin.upd:remove-cubeslide-effect,kwin.upd:remove-xrender-backend,kwin.upd:enable-scale-effect-by-default,kwin.upd:overview-group-plugin-id,kwin.upd:animation-speed-cleanup,kwin.upd:replace-cascaded-zerocornered

[Desktops]
Id_1=30d131be-27ed-4b46-b150-0ff3e93beb89
TabBox=false
TabBoxAlternative=false

[Effect-presentwindows]
BorderActivate=9
BorderActivateAll=9
BorderActivateClass=9

[ModifierOnlyShortcuts]
Meta=

[Tiling]
padding=4

[Tiling][08bd8f3d-43f1-541a-9683-41a5bd29b473]
tiles={"layoutDirection":"horizontal","tiles":[{"width":0.25},{"width":0.5},{"width":0.25}]}

[org.kde.kdecoration2]
BorderSizeAuto=false
KWINRC

install_config() {
    local target="$1"
    local owner="${2:-}"
    local group="${3:-}"

    mkdir -p "$(dirname "$target")"

    # Back up existing configuration before replacing it
    if [[ -f "$target" ]]; then
        cp -a "$target" "${target}.bak.${BACKUP_SUFFIX}"
        echo "Backup created: ${target}.bak.${BACKUP_SUFFIX}"
    fi

    install -m 0644 "$TMP_CONFIG" "$target"

    if [[ -n "$owner" && -n "$group" ]]; then
        chown "$owner:$group" "$target"
    fi

    echo "Installed: $target"
}

# 1. Default configuration for newly created users
install_config "/etc/skel/.config/kwinrc"

# 2. Existing regular users with home directories under /home
while IFS=: read -r username _ uid gid _ home _; do
    [[ "$uid" =~ ^[0-9]+$ ]] || continue
    (( uid >= 1000 )) || continue
    [[ "$home" == /home/* && -d "$home" ]] || continue

    install_config "$home/.config/kwinrc" "$uid" "$gid"
done < <(getent passwd)

echo
echo "KWin configuration installation complete."
echo "Existing users may need to log out and back in."
