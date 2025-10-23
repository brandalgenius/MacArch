#!/bin/bash
# ===============================================================
#  macOS Desktop Auto Installer for Arch Linux
#  Supports KDE Plasma and XFCE4
#  Adds: Themes + Icons + Fonts + Dock (Plank) + Blur (Komorebi)
#  Author: Dva.11 BREAKDEV | License: MIT
# ===============================================================

set -e

# --- Function Helpers -----------------------------------------
function header() {
  echo -e "\n\033[1;34m==> $1\033[0m"
}

# --- Detect Desktop Environment --------------------------------
header "Detecting desktop environment..."
if [[ $XDG_CURRENT_DESKTOP == *"KDE"* ]]; then
  DE="kde"
elif [[ $XDG_CURRENT_DESKTOP == *"XFCE"* ]]; then
  DE="xfce"
else
  echo "❌ Unsupported desktop. Use KDE Plasma or XFCE4."
  exit 1
fi
echo "Detected: $DE"

# --- Install Dependencies --------------------------------------
header "Installing dependencies..."
sudo pacman -S --needed --noconfirm git wget unzip curl \
  kvantum-qt5 qt5ct lxappearance plank komorebi \
  papirus-icon-theme materia-gtk-theme \
  ttf-dejavu ttf-roboto ttf-font-awesome gnome-themes-extra

# --- Download macOS Themes -------------------------------------
THEME_DIR="$HOME/.local/share/themes"
ICON_DIR="$HOME/.local/share/icons"
mkdir -p "$THEME_DIR" "$ICON_DIR"

header "Downloading macOS-style GTK, icon, and cursor themes..."

# GTK + Kvantum Theme
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/whitesur-gtk
cd /tmp/whitesur-gtk
./install.sh -d "$THEME_DIR" -l

# Icons
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/whitesur-icon
cd /tmp/whitesur-icon
./install.sh -d "$ICON_DIR" -a

# Cursors
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git /tmp/whitesur-cursors
cd /tmp/whitesur-cursors
./install.sh -d "$ICON_DIR"

# --- Fonts -----------------------------------------------------
header "Installing SF Pro fonts..."
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget -q https://github.com/sahibjotsaggu/SFMono-Nerd-Font/blob/master/SFMono-Regular.ttf?raw=true -O SFMono-Regular.ttf
wget -q https://github.com/sahibjotsaggu/SFProFonts/archive/refs/heads/master.zip -O sfpro.zip
unzip -q sfpro.zip
mv SFProFonts-master/*.ttf .
rm -rf SFProFonts-master sfpro.zip
fc-cache -fv

# --- Configure KDE ---------------------------------------------
if [[ "$DE" == "kde" ]]; then
  header "Applying KDE macOS appearance..."
  lookandfeeltool -a org.kde.breezedark.desktop
  kwriteconfig5 --file kdeglobals --group Icons --key Theme "WhiteSur-dark"
  kwriteconfig5 --file kdeglobals --group General --key ColorScheme "WhiteSur"
  kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle "kvantum"
  kvantummanager --set WhiteSur-Dark
  # Enable blur
  kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe false
  kwriteconfig5 --file kwinrc --group Compositing --key Backend "OpenGL"
  kwriteconfig5 --file kwinrc --group Compositing --key GLCore true
  kquitapp5 plasmashell && kstart5 plasmashell
fi

# --- Configure XFCE --------------------------------------------
if [[ "$DE" == "xfce" ]]; then
  header "Applying XFCE4 macOS appearance..."
  xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark"
  xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark"
  xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "WhiteSur-cursors"
  xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark"
  # Enable compositor + shadows + transparency
  xfconf-query -c xfwm4 -p /general/use_compositing -s true
  xfconf-query -c xfwm4 -p /general/show_frame_shadow -s true
  xfconf-query -c xfwm4 -p /general/frame_opacity -s 95
fi

# --- Configure Plank Dock --------------------------------------
header "Setting up Plank Dock..."
mkdir -p ~/.config/plank/dock1/launchers
cat <<EOF > ~/.config/autostart/plank.desktop
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Dock
EOF

# --- Configure Komorebi ---------------------------------------
header "Setting up Komorebi live wallpaper..."
mkdir -p ~/.config/autostart
cat <<EOF > ~/.config/autostart/komorebi.desktop
[Desktop Entry]
Type=Application
Exec=komorebi
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Komorebi Wallpaper
EOF

# --- Clean up --------------------------------------------------
header "Cleaning temporary files..."
rm -rf /tmp/whitesur-*

# --- Final message ---------------------------------------------
header "✅ macOS Theme installation complete!"
echo "🎨 Applied WhiteSur theme, icons, fonts, dock, and blur effects."
echo "🪄 Restart your session or log out to see full macOS-like visuals."
echo "Dock: Plank (auto-starts) | Wallpaper: Komorebi (auto-starts)"

exit 0
