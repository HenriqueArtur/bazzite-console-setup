# 🎮 Bazzite Console Setup — Dell G3 3500

Configuração completa de um **notebook Dell G3 3500 rodando Bazzite Kinoite** para funcionar como um **console atrás da TV**: liga e cai direto no jogo, sem senha/menus, tudo controlado por Bluetooth, com máximo de economia de energia.

Este repositório é o **runbook de reinstalação**: se eu formatar, sigo daqui e refaço tudo.

> 🔐 **Dados da máquina ficam no `.env`** (usuário, MACs, IPs) — que está no `.gitignore` e **nunca** vai pro GitHub. Ao longo deste README, valores como `${ETHERNET_MAC}` ou `<SEU_USUARIO>` são placeholders: os reais estão no seu `.env`. Comece copiando o modelo:
> ```bash
> cp .env.example .env    # depois edite .env com os seus valores
> ```

---

## Hardware / Sistema

| | |
|---|---|
| **Máquina** | Notebook Dell G3 3500 (BIOS 1.32) |
| **CPU** | Intel Core i5-10300H |
| **GPU** | Híbrida — Intel UHD + **NVIDIA GTX 1650 Mobile Max-Q** (driver open) |
| **SO** | Bazzite Kinoite — imagem `bazzite-nvidia-open` (atomic / rpm-ostree) |
| **Login manager** | `plasmalogin` (SDDM do Plasma 6) |
| **Rede** | Ethernet `${ETHERNET_IFACE}`, MAC `${ETHERNET_MAC}`, IP `${LOCAL_IP}` (NIC Realtek r8169) — valores no `.env` |
| **Bateria** | **Removida** (pra não inchar) — roda só no AC |
| **Uso** | Fica ligado no cabo Ethernet; costuma ficar **>1 mês desligado** |

**Notas importantes do ambiente atômico (Bazzite):**
- Usar `ujust` / `rpm-ostree`, **nunca `dnf` direto**.
- É a imagem **desktop** (KDE), **não** tem o Game Mode (gamescope/SteamOS) do Steam Deck. O "modo console" aqui é **Big Picture rodando por cima do KDE** — decisão consciente de **não** fazer rebase pra imagem `-deck`.

---

## Estrutura do repositório

```
bazzite-console-setup/
├── README.md                  ← este runbook
├── CLAUDE.md                  ← contexto pro Claude Code
├── .env.example               ← modelo dos dados da máquina (copiar p/ .env)
├── .env                       ← seus dados reais — NO .gitignore, não commitado
├── .gitignore
├── scripts/
│   ├── steam-console.sh        → vai pra ~/.local/bin/
│   └── make_blank_cursor.py    → gera o tema de cursor invisível
└── configs/
    ├── steam.desktop           → ~/.config/autostart/
    ├── MangoHud.conf           → ~/.config/MangoHud/
    ├── kwalletrc               → ~/.config/
    ├── kcminputrc-Mouse.txt    → trecho de ~/.config/kcminputrc
    ├── 10-console.conf         → /etc/systemd/logind.conf.d/  (sudo)
    └── grub-additions.txt      → append em /etc/default/grub  (sudo)
```

---

## ✅ Ordem recomendada após formatar

1. Instalar Bazzite `bazzite-nvidia-open` e fazer login.
2. [Autologin](#1-autologin-sem-senha) → [GRUB escondido](#2-grub-escondido) → [Boot](#15-boot-otimizado).
3. [Launcher do console](#4-console-no-boot-big-picture--biblioteca--nvidia--cap-60) (Big Picture + Biblioteca + NVIDIA + cap 60).
4. [GPU rendering do Big Picture](#5-gpu-rendering-do-big-picture) + [notificações](#6-notificações-do-kde-roubando-foco).
5. [Tampa fechada](#7-tampa-fechada-não-suspende) + [auto-suspend](#8-auto-suspend-nunca-no-ac) + [Wake-on-LAN](#9-wake-on-lan-ligar-desligado-pelo-celular).
6. [Áudio na TV](#11-áudio-na-tv) + [tela interna off](#10-tela-interna-desligada) + [cursor invisível](#14-cursor-invisível-no-big-picture-e-nos-jogos).
7. [Bluetooth](#18-bluetooth) dos periféricos.
8. Ajustes da [TV TCL](#16-tv-tcl--cor--contraste) e finos de [Proton](#17-proton--jogos-pesados).

---

## 1. Autologin sem senha

Arquivo `/etc/plasmalogin.conf` (feito manualmente):
```ini
[Autologin]
User=<SEU_USUARIO>
Session=plasma.desktop
```

## 2. GRUB escondido

```bash
ujust configure-grub hide
# reverter: ujust configure-grub show
```
Também adicionei em `/etc/default/grub` (ver `configs/grub-additions.txt`) e regenerei:
```bash
sudo nano /etc/default/grub     # adicionar GRUB_TIMEOUT=1 e GRUB_TIMEOUT_STYLE=hidden
sudo ujust regenerate-grub
```

## 3. KWallet desativado

Não uso. Arquivo `~/.config/kwalletrc`:
```ini
[Wallet]
Enabled=false
First Use=false
```
E removi os cofres antigos:
```bash
rm -f ~/.local/share/kwalletd/kdewallet.kwl ~/.local/share/kwalletd/kdewallet.salt
```

## 4. Console no boot (Big Picture + Biblioteca + NVIDIA + cap 60)

O coração do setup. Dois arquivos:

**a)** `scripts/steam-console.sh` → copiar pra `~/.local/bin/` e dar permissão:
```bash
mkdir -p ~/.local/bin
cp scripts/steam-console.sh ~/.local/bin/
chmod +x ~/.local/bin/steam-console.sh
```
Ele: abre o Steam em **Big Picture** (`-gamepadui`), força **todos os jogos na NVIDIA** (env PRIME offload), liga o **cap 60** (`MANGOHUD=1`), aplica o **cursor invisível** (`XCURSOR_THEME=blank`) e, quando a UI sobe, pula pra **Biblioteca** (`steam://open/games`).
- Se abrir na Home em vez da Biblioteca, aumentar `EXTRA_DELAY` (segundos) no topo do script.

**b)** `configs/steam.desktop` → autostart, chama o script:
```bash
cp configs/steam.desktop ~/.config/autostart/
```
A linha que importa (troque `<SEU_USUARIO>` pelo seu usuário — o `.desktop` exige caminho absoluto, não expande `~`):
```ini
Exec=/home/<SEU_USUARIO>/.local/bin/steam-console.sh %U
```

## 5. GPU rendering do Big Picture

Sem isso a UI do Big Picture fica lenta (software rendering — vem OFF por padrão em NVIDIA+Wayland):
> **Steam → Settings → Interface → "Enable GPU accelerated rendering in web views" = ON**

Se o Steam resetar num update, religar.

## 6. Notificações do KDE roubando foco

As notificações do KDE tiravam o foco do Big Picture. Resolver com **regra do KWin** para a janela do Steam:
- Fullscreen = Force
- Keep above = Yes
- Focus stealing prevention = None

\+ ativar **Não perturbe** (Do Not Disturb).

## 7. Tampa fechada não suspende

Arquivo `/etc/systemd/logind.conf.d/10-console.conf` (`configs/10-console.conf`):
```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
```bash
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp configs/10-console.conf /etc/systemd/logind.conf.d/
# aplica após reboot
```
Confirmar também no **KDE PowerDevil**: "quando a tampa fechar → não fazer nada".

## 8. Auto-suspend nunca no AC

Estava suspendendo rápido demais. Em **Configurações → Energia**: no AC, "Suspender automaticamente" = **Nunca**.

## 9. Wake-on-LAN (ligar desligado, pelo celular)

Plano de energia completo: **desliga de vez** e liga pelo iPhone (economia máxima pra ficar meses off). **Funciona até de poweroff total (S5).**

```bash
nmcli connection modify "Wired connection 1" 802-3-ethernet.wake-on-lan magic
# conferir:
nmcli -g 802-3-ethernet.wake-on-lan connection show "Wired connection 1"   # deve dizer: magic
```
**No BIOS Dell:** desativar **"Deep Sleep"**. (O G3 3500 **não** tem toggle "Wake on LAN" explícito — só desativar o Deep Sleep já basta pra acordar de desligado.)

**App no iPhone:** Mocha WOL (valores no seu `.env`)
- MAC: `${ETHERNET_MAC}`
- Broadcast: `${BROADCAST}`
- Porta: `${WOL_PORT}` (9 é o padrão)
- (IP do note: `${LOCAL_IP}`)

> ⚠️ Acordar por controle USB **não** funciona (o DualShock 4 não tem remote-wakeup). Acordar é via botão de power ou WoL.

## 10. Tela interna desligada

Uso só a TV. A tela interna `eDP-1` fica **desativada** (KDE → Tela e Monitor → desabilitar o painel interno, deixar só a saída HDMI da TV).

## 11. Áudio na TV

O som saía do alto-falante do note. Trocar a saída padrão pro HDMI da NVIDIA:
```bash
wpctl status                       # achar o ID do sink "HDA NVidia HDMI"
wpctl set-default <ID>             # ex: wpctl set-default 51
```
Persiste via WirePlumber.

## 12. GPU NVIDIA global nos jogos

Os jogos rodavam na Intel (lento). O default do sistema é Intel (via `switcherooctl`); forço NVIDIA via env — **já embutido no `steam-console.sh`**:
```bash
__NV_PRIME_RENDER_OFFLOAD=1
__GLX_VENDOR_LIBRARY_NAME=nvidia
__VK_LAYER_NV_optimus=NVIDIA_only
```
Conferir com `nvidia-smi` (o jogo deve aparecer usando a GPU).

## 13. Cap de FPS global = 60

O Steam desktop não tem cap global próprio (isso é do gamescope/Deck). Faço via **MangoHud**.

`configs/MangoHud.conf` → `~/.config/MangoHud/MangoHud.conf`:
```ini
fps_limit=60
fps_limit_method=late
no_display=1
```
```bash
mkdir -p ~/.config/MangoHud
cp configs/MangoHud.conf ~/.config/MangoHud/
```
\+ `MANGOHUD=1` no launcher (já no `steam-console.sh`). Mostrar/ocultar overlay: **Shift_R + F12**.

## 14. Cursor invisível (no Big Picture E nos jogos)

O KDE/Wayland **não** esconde o cursor do mouse sozinho (é "intencional" — [KDE bug 465119](https://bugs.kde.org/show_bug.cgi?id=465119)), e o gamescope aninhado não colou na NVIDIA. Solução: **tema de cursor 100% transparente**.

**a)** Gerar o tema `blank`:
```bash
python3 scripts/make_blank_cursor.py
# cria ~/.local/share/icons/blank (cursor transparente + ~115 nomes de forma)
```

**b)** No Big Picture o `XCURSOR_THEME=blank` do `steam-console.sh` já resolve. Mas o **ponteiro solto dentro do jogo** é desenhado pelo KWin/XWayland e **não herda** essa env — então precisa aplicar o tema na **sessão inteira**:
```bash
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme blank
# depois: logout/login (ou reboot)
```
Ou pela GUI: **Configurações → Cores e Temas → Cursores → "blank" → Aplicar**.

**Reverter** (cursor de volta no desktop):
```bash
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors
```
> 💡 Como é console operado por controle, o cursor invisível no desktop é aceitável — na prática quase nunca uso o desktop.

## 15. Boot otimizado

Boot frio ~33s (aceitável — uso normal é suspend/resume ~2s; boot frio só ~1x/mês).
```bash
sudo systemctl disable --now NetworkManager-wait-online.service
sudo systemctl mask displaylink.service
sudo systemctl mask mandb-update... # (serviço de atualização do mandb)
```
\+ GRUB escondido (seção 2). O "chão duro" (firmware ~5s + GRUB carregando initramfs grande ~7s + initrd ~9s) **não** vale cortar — encolher o initramfs no atomic é arriscado (quebra boot em update).

## 16. TV TCL — cor / contraste

A TV é uma **TCL** no HDMI (sai da NVIDIA, 1080p60). **Cuidado conhecido:** ao voltar do suspend a TV desajusta contraste/cor (RGB range do HDMI). Resolvido **no lado da TV**: rotular a entrada HDMI como **"PC"** e/ou fixar o **HDMI Color Range**. Se voltar a acontecer, dá pra criar um hook de resume que reaplica a tela.

## 17. Proton / jogos pesados

Ex.: **Fatal Fury: City of the Wolves** — a GTX 1650 Mobile está **abaixo** do recomendado (pede RTX 2070). Sintoma 30↔60 fps = VSync caindo pela metade quando não segura 60.
- **Receita:** Proton GE (Propriedades → Compatibilidade) + settings baixos pra **fixar 60** + Shader Pre-Caching ON.
- Bug de trava de câmera após ~1h: launch option `LD_PRELOAD="" %command%`.

## 18. Bluetooth

Todos pareados e **trusted** (reconectam sozinhos). Pareamento **pela GUI** (applet KDE/Bluedevil) funciona após reboot limpo — exigência: tem que funcionar pela interface porque troco periféricos.

| Dispositivo | MAC (valores no `.env`) |
|---|---|
| Teclado Logitech POP Icon Keys | `${BT_KEYBOARD_MAC}` |
| Controle DualShock 4 | `${BT_DS4_MAC}` |
| Mouse Logitech Pebble 2 M350s | *(parear pela GUI)* |

Adaptador: Intel 9460/9560.

**Dicas recorrentes:**
- O periférico **não aparece** se estiver grudado no **celular** (desligar BT do cel) ou se não estiver em modo de pareamento (LED piscando rápido).
- **DS4 desconectando toda hora** = bond quebrado (`Paired:no, Trusted:yes`). Corrigir:
  ```bash
  bluetoothctl remove <MAC_DO_DS4>   # ${BT_DS4_MAC} — ver .env
  # colocar o DS4 em pareamento (Share + PS) e parear de novo pela GUI
  ```

## 19. Térmico / G-Mode

Fans **funcionam** e sobem com a curva (~3470 RPM idle-load → ~4100 em jogo pesado; máx ~5600). Sob jogo pesado: CPU ~85°C, GPU NVIDIA ~68°C.

Como fica fechado atrás da TV: **posicionar em pé/elevado** (entrada de ar é embaixo), vãos livres, manter o cap 60. Se precisar de margem, o G3 tem **G-Mode** (fans no máximo, via `alienware_wmi`) — ainda não configurado.

---

## Resumo do estado

**Console essencialmente PRONTO.** Em aberto/opcional: monitorar temperatura em sessões longas (ativar G-Mode se necessário); hook de resume pra cor da TV só se o problema voltar.

**Filosofia:** experiência de console (liga → jogo, sem senha/menus, controle por BT, economia máxima). Pra ficar meses desligado, a melhor opção é **poweroff + Wake-on-LAN**.
