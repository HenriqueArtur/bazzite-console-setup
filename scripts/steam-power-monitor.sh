#!/usr/bin/env bash
# Monitor de energia sob demanda: vigia o processo 'steam' a sessao inteira e
# troca o perfil tuned conforme a Steam ABRE/FECHA. Roda pelo autostart do KDE
# (configs/steam-power-monitor.desktop), independente do launcher -- por isso
# reativa mesmo quando voce abre a Steam de novo depois de ter fechado.
#
# EDGE-TRIGGERED de proposito: so aplica perfil na TRANSICAO (abriu/fechou).
# Assim, um 'tuned-adm profile latency-performance' manual seu (ex.: build
# pesado no dev, com a Steam fechada) NAO e' atropelado enquanto o estado da
# Steam nao mudar.

PROFILE_GAME=latency-performance
PROFILE_IDLE=balanced-bazzite
POLL=5

steam_up() { pgrep -x steam >/dev/null 2>&1; }

# sincroniza uma vez com a realidade atual (login pode ja ter a Steam subindo)
if steam_up; then
    tuned-adm profile "$PROFILE_GAME" >/dev/null 2>&1; prev=1
else
    tuned-adm profile "$PROFILE_IDLE" >/dev/null 2>&1; prev=0
fi

# a partir daqui, so reage a transicoes
while true; do
    if steam_up; then now=1; else now=0; fi
    if [ "$now" != "$prev" ]; then
        if [ "$now" = 1 ]; then
            tuned-adm profile "$PROFILE_GAME" >/dev/null 2>&1
        else
            tuned-adm profile "$PROFILE_IDLE" >/dev/null 2>&1
        fi
        prev="$now"
    fi
    sleep "$POLL"
done
