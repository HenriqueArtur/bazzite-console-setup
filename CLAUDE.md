# CLAUDE.md — Bazzite Console Setup

Contexto pro Claude Code quando a sessão começar **dentro desta pasta**.

## O que é este repositório

Runbook de reinstalação de um **notebook Dell G3 3500 rodando Bazzite Kinoite** configurado como **console atrás da TV** (Big Picture no boot, controle por Bluetooth, Wake-on-LAN, cursor invisível, etc.). Se a máquina for formatada, tudo é refeito a partir do `README.md`.

**Este repo é PÚBLICO (GitHub).** Ver regras de dados sensíveis abaixo — é o ponto mais importante.

## 🔐 Dados sensíveis — regra número 1

- **NUNCA** commitar identificadores reais da máquina: usuário do sistema, endereços MAC (Ethernet/Bluetooth), IPs, hostname.
- Valores reais vivem **só no `.env`**, que está no `.gitignore`. **Nunca** versionar o `.env`.
- Nos arquivos versionados (README, configs, scripts) usar **placeholders**: `<SEU_USUARIO>`, `${ETHERNET_MAC}`, `${LOCAL_IP}`, `${BT_DS4_MAC}`, etc. As chaves estão em `.env.example`.
- Antes de qualquer commit, **varrer a pasta** atrás de vazamento:
  ```bash
  grep -rInE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}|192\.168\.|/home/[a-z]' \
    --exclude-dir=.git --exclude=.env .
  ```
  Só deve aparecer coisa dentro de `.env` (que não é commitado) ou placeholders.

## Ambiente da máquina (importante pra dar comandos certos)

- **Bazzite Kinoite** = imutável/atômico (rpm-ostree). Instalar/alterar sistema via **`ujust` / `rpm-ostree`**, **nunca `dnf` direto**.
- Imagem `bazzite-nvidia-open`. GPU **híbrida** Intel + NVIDIA (Optimus) — default do sistema é Intel; jogos são forçados na NVIDIA via env PRIME.
- Desktop **KDE Plasma 6 / Wayland** (login `plasmalogin`/SDDM). **Não** é a sessão gamescope/Game Mode do Steam Deck — o "console" é Big Picture sobre o KDE.
- `sudo` **não-interativo costuma falhar** neste ambiente: comandos que precisam de root devem ser **entregues ao usuário** pra ele rodar no terminal dele, não executados direto.

## Onde as coisas moram no sistema real

| Arquivo do repo | Destino |
|---|---|
| `scripts/steam-console.sh` | `~/.local/bin/` (chmod +x) — launcher central |
| `scripts/steam-power-monitor.sh` | `~/.local/bin/` (chmod +x) — governor sob demanda (autostart) |
| `configs/steam-power-monitor.desktop` | `~/.config/autostart/` |
| `scripts/make_blank_cursor.py` | roda 1x, gera `~/.local/share/icons/blank` |
| `configs/steam.desktop` | `~/.config/autostart/` |
| `configs/MangoHud.conf` | `~/.config/MangoHud/` |
| `configs/kwalletrc` | `~/.config/` |
| `configs/kcminputrc-Mouse.txt` | trecho de `~/.config/kcminputrc` |
| `configs/10-console.conf` | `/etc/systemd/logind.conf.d/` (sudo) |
| `configs/grub-additions.txt` | append em `/etc/default/grub` (sudo) |

## Convenções

- **Responder em português (BR).** O usuário é o Henrique.
- Ao editar o runbook, manter o padrão: cada item traz **o que fazer + comando + como reverter**.
- Se descobrir/alterar algo novo na máquina, refletir tanto no `README.md` quanto (se for valor pessoal) no `.env` + `.env.example`.
