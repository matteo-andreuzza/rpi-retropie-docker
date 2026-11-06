# RetroPie (EmulationStation + RetroArch) for a Raspberry Pi 4, drawing straight
# to the HDMI TV through DRM/KMS: no X server, no desktop.
# Everything is built from source by the official RetroPie-Setup scripts.
FROM debian:trixie@sha256:9c6e381421d0f48d1b8133e573f33c185ee16cbf505eda9c4a8a4791b25ea8a6

LABEL org.opencontainers.image.source="https://github.com/matteo-andreuzza/rpi-retropie-docker"

# RetroPie-Setup revision of 2026-10-31.
ARG RETROPIE_SETUP_COMMIT=7a9d751e606702734da976981845ad28ee157ba9

# Build-time settings only (ARGs don't end up in the running container):
# - RetroPie can't detect the board from inside a build container, so name it.
# - __user is who RetroPie installs for (it normally reads it from sudo).
# - RetroPie runs make -j$(nproc) and nproc honours OMP_NUM_THREADS: use all
#   4 cores (lower it, e.g. --build-arg OMP_NUM_THREADS=2, if the power supply struggles).
ARG __platform=rpi4 __has_kms=1 __user=pi OMP_NUM_THREADS=4 DEBIAN_FRONTEND=noninteractive

# iproute2: RetroPie checks for internet access with 'ip route'.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git iproute2 libgl1-mesa-dri \
    && useradd -m -s /bin/bash pi \
    && git clone https://github.com/RetroPie/RetroPie-Setup.git /home/pi/RetroPie-Setup \
    && git -C /home/pi/RetroPie-Setup checkout -q "$RETROPIE_SETUP_COMMIT" \
    && chown -R pi:pi /home/pi/RetroPie-Setup

WORKDIR /home/pi/RetroPie-Setup

# One module per layer: if the build is interrupted, finished modules stay cached.
RUN nice -n 19 ./retropie_packages.sh retroarch
RUN nice -n 19 ./retropie_packages.sh emulationstation
RUN nice -n 19 ./retropie_packages.sh runcommand
RUN nice -n 19 ./retropie_packages.sh lr-mupen64plus-next
RUN nice -n 19 ./retropie_packages.sh lr-pcsx-rearmed
RUN nice -n 19 ./retropie_packages.sh lr-snes9x
RUN nice -n 19 ./retropie_packages.sh lr-fceumm
RUN nice -n 19 ./retropie_packages.sh lr-genesis-plus-gx
RUN nice -n 19 ./retropie_packages.sh lr-gambatte
RUN nice -n 19 ./retropie_packages.sh lr-mgba
RUN nice -n 19 ./retropie_packages.sh lr-beetle-pce-fast
RUN nice -n 19 ./retropie_packages.sh lr-stella2014

# - RetroArch reads controllers through SDL2, which finds them without udev events.
# - No runcommand launch menu: it needs a virtual keyboard (/dev/uinput) on the host.
# - Keep pristine copies of configs and RetroPie folder to fill empty host folders.
# - Record the exact source commits that were built.
RUN cfg=/opt/retropie/configs/all \
    && sed -i 's/^input_joypad_driver = .*/input_joypad_driver = "sdl2"/' $cfg/retroarch.cfg \
    && sed -i 's/^disable_menu = .*/disable_menu = "1"/' $cfg/runcommand.cfg \
    && grep -q '^input_joypad_driver = "sdl2"' $cfg/retroarch.cfg \
    && grep -q '^disable_menu = "1"' $cfg/runcommand.cfg \
    && grep -H 'pkg_repo_\(url\|branch\|commit\)' /opt/retropie/*/*/retropie.pkg > /opt/retropie/VERSIONS \
    && cp -a /opt/retropie/configs /opt/retropie/configs.dist \
    && cp -a /home/pi/RetroPie /home/pi/RetroPie.dist \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
