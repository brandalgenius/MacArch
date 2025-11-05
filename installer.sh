#!/bin/bash
set -e

echo "🍏 Starting macOS-style setup for GNOME on Arch Linux..."

# --- Essentials ---
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm gnome-tweaks gnome-shell-extensions chrome-gnome-shell git wget unzip base-devel

# --- Node.js & npm ---
echo "🟢 Installing Node.js + npm..."
sudo pacman -S --noconfirm nodejs npm

# (Optional) install yarn globally
sudo npm install -g yarn

# --- WhiteSur GTK Theme ---
echo "🎨 Installing WhiteSur GTK theme..."
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme
./install.sh -d ~/.themes
cd ..

# --- WhiteSur Icons ---
echo "🖼️ Installing WhiteSur icon theme..."
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
cd WhiteSur-icon-theme
./install.sh -d ~/.icons
cd ..

# --- WhiteSur Cursors ---
echo "🖱️ Installing WhiteSur cursor theme..."
git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1
cd WhiteSur-cursors
./install.sh -d ~/.icons
cd ..

# --- macOS Fonts ---
echo "🔤 Installing macOS SF Pro fonts..."
git clone https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts.git --depth=1
mkdir -p ~/.local/share/fonts
cp San-Francisco-Pro-Fonts/*.otf ~/.local/share/fonts/
fc-cache -fv

# --- GNOME Extensions ---
echo "🧩 Installing GNOME extensions..."
sudo pacman -S --noconfirm gnome-shell-extension-dash-to-dock gnome-shell-extension-appindicator

# --- Optional: Install extra extensions (Blur My Shell, Just Perfection, Arc Menu) ---
echo "⬇️ Installing extra extensions..."
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

mkdir -p "$EXT_DIR"
# Blur My Shell
git clone https://github.com/aunetx/blur-my-shell.git "$EXT_DIR/blur-my-shell@aunetx"
# Just Perfection
git clone https://github.com/justperfection/channel.git "$EXT_DIR/just-perfection-desktop@just-perfection"
# Arc Menu
git clone https://github.com/LinxGem33/Arc-Menu.git "$EXT_DIR/arcmenu@arcmenu.com"

# --- Wallpapers ---
echo "🌄 Downloading macOS wallpapers..."
mkdir -p ~/Pictures/Wallpapers
wget -O ~/Pictures/Wallpapers/WhiteSur-wallpapers.zip https://github.com/vinceliuice/WhiteSur-wallpapers/archive/refs/heads/main.zip
unzip -o ~/Pictures/Wallpapers/WhiteSur-wallpapers.zip -d ~/Pictures/Wallpapers/

# --- Apply GTK / Icon / Cursor theme defaults ---
echo "⚙️ Applying GNOME theme settings..."
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark"
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"
gsettings set org.gnome.desktop.interface cursor-theme "WhiteSur-cursors"
gsettings set org.gnome.shell.extensions.user-theme name "WhiteSur-Dark"

# --- Final Notes ---
echo "✅ Setup complete!"
echo ""
echo "💡 Next steps:"
echo "  • Log out and back in (or press Alt+F2 → type r → Enter on Xorg) to reload GNOME Shell."
echo "  • Open GNOME Tweaks → Appearance to fine-tune theme, icons, and fonts."
echo "  • Manage extensions via the GNOME Extensions app."
echo ""
echo "Node.js $(node -v) and npm $(npm -v) installed successfully! 🎉"
