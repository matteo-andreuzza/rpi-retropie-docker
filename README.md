# rpi-retropie-docker

RetroPie (EmulationStation + RetroArch) in un container Docker per **Raspberry Pi 4**,
con l'immagine disegnata direttamente sulla TV via HDMI (DRM/KMS): niente server X,
niente desktop sull'host. Pensato per un Pi che fa da server e resta sempre attaccato
alla TV: si accende la TV, si sceglie l'ingresso HDMI e si gioca con il controller USB.

Fork di [nwildner/retropie-docker](https://github.com/nwildner/retropie-docker)
(x86_64 / X11), adattato a Pi 4 e KMS.

## Cosa contiene

- Base `debian:trixie` e [RetroPie-Setup](https://github.com/RetroPie/RetroPie-Setup)
  fissati a versioni precise (vedi `Dockerfile`); tutto è compilato dai sorgenti dagli
  script ufficiali di RetroPie.
- EmulationStation in modalità **Kiosk** (solo giochi, niente menu di impostazioni).
- Core: N64 (`lr-mupen64plus-next`), PS1 (`lr-pcsx-rearmed`), SNES, NES, Mega Drive /
  Master System / Game Gear, Game Boy / Color, GBA, PC Engine, Atari 2600.
- Nessuna porta esposta, niente `privileged`: il container vede solo GPU (`/dev/dri`),
  audio (`/dev/snd`) e dispositivi di input (`/dev/input`).
- I commit compilati sono elencati in `/opt/retropie/VERSIONS` dentro l'immagine.

## Requisiti sull'host

Raspberry Pi 4 a 64 bit con `dtoverlay=vc4-kms-v3d`, Docker con il plugin compose, git.
Nient'altro da installare o configurare.

## Installazione

```bash
git clone https://github.com/matteo-andreuzza/rpi-retropie-docker.git ~/rpi-retropie
cd ~/rpi-retropie
sudo docker compose up -d --build
```

Da quel momento il container parte da solo a ogni avvio del Pi.

La prima build compila tutto sul Pi e richiede alcune ore. Se si interrompe (per esempio
cade la connessione SSH), basta rilanciare lo stesso comando: i moduli già compilati
restano in cache.

Al primo avvio EmulationStation chiede di configurare il controller: va fatto una volta
davanti alla TV, poi resta salvato.

## Dati

Tutto resta in `~/rpi-retropie/data/`, creata al primo avvio:

| Cartella | Contenuto |
|---|---|
| `data/RetroPie/roms/<console>/` | ROM (es. `roms/n64/`); i salvataggi finiscono accanto alle ROM |
| `data/RetroPie/BIOS/` | BIOS (es. per la PS1) |
| `data/configs/` | configurazione di EmulationStation, RetroArch e controller |

I file appartengono all'utente con UID 1000 (`pi` nel container), di solito il primo
utente del Pi. Se le cartelle sono vuote, all'avvio vengono riempite con i valori
di default.

Dopo aver copiato nuove ROM:

```bash
sudo docker compose restart
```

Per reinstallare su un altro Pi o disco: copiare `~/rpi-retropie/data/` e ripetere
l'installazione.

## Aggiornare

```bash
cd ~/rpi-retropie && git pull && sudo docker compose up -d --build
```

Per prendere anche gli aggiornamenti di sicurezza di Debian: `sudo docker compose build --pull`.

## Configurare controller e impostazioni

Di default EmulationStation è in modalità Kiosk (solo giochi). Per avere i menu
completi (Start → CONFIGURE INPUT, impostazioni, ecc.):

```bash
sudo docker compose down && sudo ES_KIOSK=0 docker compose up
```

Per tornare in Kiosk: `sudo docker compose down && sudo docker compose up -d`.

In gioco: **Select+Start** esce, **Select+X** apre il menu di RetroArch.

## Note

- Se la TV è spenta all'avvio del Pi, il container aspetta che la porta HDMI risulti
  collegata e poi avvia EmulationStation.
- L'audio va sulla porta HDMI a cui è collegata la TV. Se la scelta automatica è
  sbagliata, decommentare `AUDIO_CARD` in `docker-compose.yml`.
- Le voci "Restart/Shutdown System" di EmulationStation non possono spegnere il Pi:
  chiudono solo EmulationStation dentro il container.

## Rimozione

```bash
cd ~/rpi-retropie
sudo docker compose down --rmi local --volumes
# opzionale, cancella ROM, salvataggi e configurazioni:
# rm -rf ~/rpi-retropie/data
```
