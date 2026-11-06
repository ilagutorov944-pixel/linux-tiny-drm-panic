#!/bin/sh
set -e

echo "=== Building Lightweight Alpine XFCE + Falkon Rootfs ==="

ROOTFS="/rootfs"
mkdir -p "$ROOTFS"

# 1. Configure Alpine package repositories (main + community)
cat > /etc/apk/repositories << 'EOF'
https://dl-cdn.alpinelinux.org/alpine/v3.21/main
https://dl-cdn.alpinelinux.org/alpine/v3.21/community
EOF

apk update

# 2. Install desktop, browser, input, sound, and X11 packages
echo "=== Installing Packages into Rootfs ==="
apk --root "$ROOTFS" --initdb --no-cache add \
    alpine-base \
    openrc \
    eudev \
    dbus \
    xorg-server \
    xinit \
    xf86-video-modesetting \
    xf86-input-libinput \
    xfce4 \
    xfce4-terminal \
    falkon \
    mesa-dri-gallium \
    font-dejavu \
    adwaita-icon-theme \
    sudo \
    ca-certificates \
    alsa-utils \
    tzdata

# 3. Setup system configurations
cp /etc/apk/repositories "$ROOTFS/etc/apk/repositories"
echo "nameserver 1.1.1.1" > "$ROOTFS/etc/resolv.conf"
echo "tiny-xfce" > "$ROOTFS/etc/hostname"

# Configure Xorg permissions for non-root users
mkdir -p "$ROOTFS/etc/X11"
cat > "$ROOTFS/etc/X11/Xwrapper.config" << 'EOF'
allowed_users=anybody
needs_root_rights=yes
EOF

chmod u+s "$ROOTFS"/usr/libexec/Xorg "$ROOTFS"/usr/bin/Xorg "$ROOTFS"/usr/libexec/Xorg.wrap 2>/dev/null || true

# 4. Create user 'alpine' with autologin privileges
chroot "$ROOTFS" addgroup -S alpine
chroot "$ROOTFS" adduser -S -D -G alpine -s /bin/sh alpine
chroot "$ROOTFS" addgroup alpine wheel
chroot "$ROOTFS" addgroup alpine audio
chroot "$ROOTFS" addgroup alpine video
chroot "$ROOTFS" addgroup alpine input
chroot "$ROOTFS" addgroup alpine tty
chroot "$ROOTFS" passwd -d alpine
chroot "$ROOTFS" passwd -d root

mkdir -p "$ROOTFS/etc/sudoers.d"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > "$ROOTFS/etc/sudoers.d/wheel"
chmod 0440 "$ROOTFS/etc/sudoers.d/wheel"

# 5. User X session startup (.xinitrc)
mkdir -p "$ROOTFS/home/alpine/.config/autostart"
mkdir -p "$ROOTFS/home/alpine/Desktop"

cat > "$ROOTFS/home/alpine/.xinitrc" << 'EOF'
#!/bin/sh
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
fi

# Autostart Falkon web browser 2 seconds after desktop initializes
(sleep 2 && falkon) &

# Run XFCE Desktop
exec dbus-launch --exit-with-session startxfce4
EOF
chmod +x "$ROOTFS/home/alpine/.xinitrc"

# Create Desktop Shortcut for Falkon
cat > "$ROOTFS/home/alpine/Desktop/falkon.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Falkon Web Browser
Comment=Fast and lightweight QtWebEngine browser
Icon=falkon
Exec=falkon %u
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x "$ROOTFS/home/alpine/Desktop/falkon.desktop"
chroot "$ROOTFS" chown -R alpine:alpine /home/alpine

# 6. Create custom /init for direct graphical boot
cat > "$ROOTFS/init" << 'EOF'
#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Mount virtual filesystems
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mkdir -p /dev/pts /dev/shm
mount -t devpts none /dev/pts
mount -t tmpfs none /dev/shm
mount -t tmpfs none /tmp
mount -t tmpfs none /run
chmod 1777 /tmp /dev/shm

# Device permissions for Xorg & audio
chmod 666 /dev/null /dev/zero /dev/urandom /dev/ptmx /dev/tty /dev/tty0 /dev/tty1 2>/dev/null || true
chmod 666 /dev/dri/* /dev/fb* /dev/snd/* 2>/dev/null || true

# Entropy & network DHCP in background
[ -c /dev/urandom ] && dd if=/dev/urandom of=/dev/null count=1 2>/dev/null
ip link set up dev lo
ip link set up dev eth0 2>/dev/null || true
udhcpc -i eth0 -b -s /usr/share/udhcpc/default.script 2>/dev/null &

# Start D-Bus daemon
mkdir -p /var/run/dbus
dbus-uuidgen --ensure=/etc/machine-id
dbus-uuidgen --ensure
dbus-daemon --system --fork

echo "========================================================="
echo "   Linux 6.12 Tiny-XFCE Live Distro (Falkon + DRM Panic)"
echo "========================================================="
echo "Launching XFCE Desktop environment for user 'alpine'..."

# Start graphical X11 session directly on console tty1
exec su -l alpine -c "startx" < /dev/tty1 > /dev/tty1 2>&1 || {
    echo "[!] X session exited. Starting fallback shell..."
    exec /bin/sh < /dev/tty1 > /dev/tty1 2>&1
}
EOF
chmod +x "$ROOTFS/init"

echo "=== Rootfs setup completed successfully ==="
