#!/usr/bin/env bash
# Abre o Steam em Big Picture (na GPU NVIDIA + cap 60 via MangoHud) e,
# assim que a interface sobe, navega direto pra Biblioteca.
# Ajuste o EXTRA_DELAY se ele abrir na Home (aumentar) ou navegar cedo demais.

EXTRA_DELAY=8

# Governor sob demanda (anti-stutter em jogo leve, sem gastar no "modo dev"):
# enquanto a Steam estiver aberta -> perfil 'latency-performance' (governor
# performance + C-states rasos). Ao FECHAR a Steam (ou deslogar) volta pro
# 'balanced-bazzite' (baixo consumo). O tuned-adm troca o perfil SEM sudo
# nesta sessao (via polkit). Substitui o feral gamemode, que nao instala
# nesta imagem por um estado corrompido do rpm-ostree (dedupe fantasma).
PROFILE_GAME=latency-performance
PROFILE_IDLE=balanced-bazzite
tuned-adm profile "$PROFILE_GAME" >/dev/null 2>&1
trap 'tuned-adm profile "$PROFILE_IDLE" >/dev/null 2>&1' EXIT

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

# segura o script vivo enquanto a Steam roda; quando ela fechar, o trap EXIT
# reverte o perfil de energia pro modo idle/dev.
while pgrep -x steam >/dev/null 2>&1; do
    sleep 10
done
