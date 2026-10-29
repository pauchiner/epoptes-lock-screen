#!/usr/bin/env bash
set -Eeuo pipefail

# Debe ejecutarse como root
if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta este script con sudo."
    exit 1
fi

KWRITECONFIG="$(command -v kwriteconfig5 || true)"

if [[ -z "$KWRITECONFIG" ]]; then
    echo "No se encuentra kwriteconfig5. Instala las herramientas de KDE Plasma 5."
    exit 1
fi

configure_user() {
    local home="$1"
    local config="$home/.config/kwinrc"

    mkdir -p "$home/.config"

    # Crear copia de seguridad si el archivo ya existe
    if [[ -f "$config" ]]; then
        cp -p "$config" "$config.bak"
    fi

    # Establecer la configuración de KWin
    "$KWRITECONFIG" --file "$config" \
        --group ModifierOnlyShortcuts \
        --key Meta ""

    echo "Configurado: $config"
}

# 1. Usuarios existentes con UID de usuario normal
while IFS=: read -r username _ uid _ _ home shell; do
    [[ "$uid" -ge 1000 ]] 2>/dev/null || continue
    [[ "$shell" != */nologin && "$shell" != */false ]] || continue
    [[ -n "$home" && -d "$home" ]] || continue

    configure_user "$home"
done < <(getent passwd)

# 2. Plantilla para usuarios nuevos
configure_user "/etc/skel"

echo
echo "Configuración aplicada."
echo "Los usuarios deben cerrar y volver a abrir su sesión para asegurar que se aplique."
