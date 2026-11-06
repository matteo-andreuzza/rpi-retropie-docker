#!/bin/bash
# Runs as root only to prepare the container, then starts EmulationStation as 'pi'.
set -e

# Empty host folders (first start, new disk): fill them with the image defaults.
for dir in /opt/retropie/configs /home/pi/RetroPie; do
    if [ -z "$(ls -A "$dir")" ]; then
        echo "Filling empty $dir with defaults"
        cp -a "$dir.dist/." "$dir/"
    fi
    chown pi:pi "$dir"
done

# Let 'pi' open the GPU, sound and input devices, whatever group IDs the host uses.
for gid in $(find /dev/dri /dev/snd /dev/input -maxdepth 1 -type c -printf '%G\n' | sort -u); do
    [ "$gid" = 0 ] && continue
    getent group "$gid" >/dev/null || groupadd -g "$gid" "host$gid"
    usermod -aG "$(getent group "$gid" | cut -d: -f1)" pi
done

# With KMS the HDMI port reads "disconnected" while the TV is off: wait for it.
if ! hdmi=$(grep -l '^connected$' /sys/class/drm/card*-HDMI-A-*/status 2>/dev/null); then
    echo "Waiting for a TV on HDMI..."
    until hdmi=$(grep -l '^connected$' /sys/class/drm/card*-HDMI-A-*/status 2>/dev/null); do
        sleep 5
    done
fi
hdmi=${hdmi%%$'\n'*}
echo "TV found on ${hdmi%/status}"

# Sound to the HDMI port the TV is on (HDMI-A-1 = vc4hdmi0, HDMI-A-2 = vc4hdmi1),
# through the IEC958 'hdmi:' converter, as RetroPie's audiosettings module does.
case "$hdmi" in
    *HDMI-A-2*) card=vc4hdmi1 ;;
    *) card=vc4hdmi0 ;;
esac
card=${AUDIO_CARD:-$card}
echo "Audio on ALSA card $card"
mkdir -p /etc/alsa/conf.d
cat > /etc/alsa/conf.d/99-retropie.conf <<EOF
pcm.!default { type plug slave.pcm "hdmi:$card" }
ctl.!default { type hw card $card }
EOF

# Kiosk mode (games only, no settings menus) unless ES_KIOSK=0.
[ "${ES_KIOSK:-1}" = 0 ] || set -- --force-kiosk
exec setpriv --reuid=pi --regid=pi --init-groups env HOME=/home/pi USER=pi \
    emulationstation "$@"
