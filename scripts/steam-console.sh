#!/usr/bin/env bash
# Abre o Steam em Big Picture (na GPU NVIDIA + cap 60 via MangoHud) e,
# assim que a interface sobe, navega direto pra Biblioteca.
# Ajuste o EXTRA_DELAY se ele abrir na Home (aumentar) ou navegar cedo demais.

EXTRA_DELAY=8

# Cursor invisivel SO no Steam/jogos (desktop do KDE mantem cursor normal).
# Usa o tema 'blank' (100% transparente) em ~/.local/share/icons/blank.
env MANGOHUD=1 \
    __NV_PRIME_RENDER_OFFLOAD=1 \
    __GLX_VENDOR_LIBRARY_NAME=nvidia \
    __VK_LAYER_NV_optimus=NVIDIA_only \
    XCURSOR_THEME=blank \
    XCURSOR_SIZE=24 \
    XCURSOR_PATH="$HOME/.local/share/icons:$HOME/.icons:/usr/share/icons:/usr/share/pixmaps" \
    /usr/bin/bazzite-steam -gamepadui "$@" &

# espera a UI do Steam (steamwebhelper) aparecer
for _ in $(seq 1 60); do
    pgrep -x steamwebhelper >/dev/null 2>&1 && break
    sleep 1
done

# folga extra pra Big Picture ficar interativo, entao pula pra Biblioteca
sleep "$EXTRA_DELAY"
/usr/bin/bazzite-steam steam://open/games >/dev/null 2>&1
