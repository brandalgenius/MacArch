#!/usr/bin/env bash
# ===============================================================
# All-in-one Arch installer:
#  - macOS-like theme (WhiteSur) + Plank dock + Komorebi wallpaper
#  - Developer environment: Python (system + pyenv deps), pip tooling,
#    Node.js (node, npm) + yarn/pnpm, Docker, git, VS Code (AUR opt)
#  - Ethical security / research tools (nmap, wireshark, radare2, ghidra, pwntools...)
#  - Uses pacman + auto-installs paru (AUR helper) for AUR packages
#
# Usage:
#  chmod +x arch_macos_dev_installer.sh
#  ./arch_macos_dev_installer.sh
#
# Author: Dva.11 BREAKDEV (based on user's request)
# License: MIT-like (use at your own risk)
# ===============================================================

set -euo pipefail
IFS=$'\n\t'

# --------- Config ---------
USER_HOME="${HOME}"
THEME_DIR="$USER_HOME/.local/share/themes"
ICON_DIR="$USER_HOME/.local/share/icons"
FONT_DIR="$USER_HOME/.local/share/fonts"
TMPDIR="/tmp/arch_macos_install"
AUR_HELPER="paru"   # will install if missing
# Packages to install from official repos
PACMAN_PACKAGES=(
  base-devel git wget curl unzip tar unzip
  kvantum-qt5 qt5ct lxappearance
  plank gnome-themes-extra # plank & theme helpers
  papirus-icon-theme materia-gtk-theme
  ttf-dejavu noto-fonts noto-fonts-emoji
  python python-pip python-virtualenv python-virtualenvwrapper python-pytest
  nodejs npm
  yarn docker docker-compose
  git-lfs
  vim neovim
  fcitx5-im fcitx5-configtool # optional input framework
  nmap wireshark-qt binwalk radare2 john \
  binutils gdb strace ltrace ccache make cmake unzip
  # radare2 already included; ghidra & burpsuite will be AUR
)
# AUR packages (installed through paru)
AUR_PACKAGES=(
  komorebi               # live wallpaper (AUR)
  visual-studio-code-bin # or replace with vscodium if preferred
  ghidra
  burpsuite
  pwntools-git           # if not in repo
  yara
  hashcat
  # add other AUR tools as you need
)

# Ethical security stack (subset installed via pacman + AUR)
ETHICAL_TOOLS_PACMAN=(
  nmap wireshark-cli mitmproxy radare2 binwalk
)
ETHICAL_TOOLS_AUR=(
  ghidra burpsuite
)

# Developer extras
DEV_PY_PACKAGES=(
  pipenv poetry virtualenvwrapper debugpy pylint black isort mypy
)
DEV_NODE_GLOBALS=(
  pnpm
)

# --------- Helpers ---------
function header() {
  echo -e "\n\033[1;36m==> $1\033[0m"
}

function require_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    echo "Don't run this script as root. Re-run as your normal user (sudo is used internally)."
    exit 1
  fi
}

function ask_continue() {
  echo
  read -r -p "Proceed? [Y/n] " ans
  ans=${ans:-Y}
  if [[ ! $ans =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 0
  fi
}

# --------- Start ---------
require_root
header "This script will install themes, dev stacks, and ethical security tools on Arch."
echo "It will use sudo for package installation and may install AUR helper (paru)."
ask_continue

header "Creating temporary workspace: $TMPDIR"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR" "$THEME_DIR" "$ICON_DIR" "$FONT_DIR"

# --------- System update & base installs ---------
header "Syncing package databases and updating system (sudo pacman -Syu)"
sudo pacman -Syu --noconfirm

header "Installing base packages via pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

# --------- Install paru (AUR helper) if missing ---------
if ! command -v "$AUR_HELPER" &>/dev/null; then
  header "Installing paru (AUR helper) to /tmp and building it..."
  cd "$TMPDIR"
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
else
  header "AUR helper '$AUR_HELPER' is already installed."
fi

# --------- Install AUR packages ---------
if (( ${#AUR_PACKAGES[@]} )); then
  header "Installing selected AUR packages (this may take a while)..."
  # use paru in non-interactive; allow overwrites
  "$AUR_HELPER" -S --noconfirm --needed "${AUR_PACKAGES[@]}"
fi

# --------- Theme: WhiteSur (GTK / Icon / Cursor) ---------
header "Downloading and installing WhiteSur theme & icons (open-source macOS-like)"
cd "$TMPDIR"
# WhiteSur GTK
if [ ! -d "$TMPDIR/WhiteSur-gtk-theme" ]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git WhiteSur-gtk-theme
fi
cd WhiteSur-gtk-theme || true
# install script supports options; we'll call it to install locally
# Note: the official install script may request sudo for system install; we pass -d for custom dir when supported
if [[ -x ./install.sh ]]; then
  # try install locally
  ./install.sh -d "$THEME_DIR" || ./install.sh -s
fi

# Icons
cd "$TMPDIR"
if [ ! -d "$TMPDIR/WhiteSur-icon-theme" ]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git WhiteSur-icon-theme
fi
cd WhiteSur-icon-theme || true
if [[ -x ./install.sh ]]; then
  ./install.sh -d "$ICON_DIR" || true
fi

# Cursors
cd "$TMPDIR"
if [ ! -d "$TMPDIR/WhiteSur-cursors" ]; then
  git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git WhiteSur-cursors
fi
cd WhiteSur-cursors || true
if [[ -x ./install.sh ]]; then
  ./install.sh -d "$ICON_DIR" || true
fi

# --------- Fonts ---------
header "Installing recommended (open) fonts: Noto + Inter"
cd "$FONT_DIR"
# Inter (from github) and Noto are already in pacman but we ensure local cache updated
if ! fc-list | grep -iq "Inter"; then
  # download Inter if missing
  wget -qO inter.zip "https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip" || true
  unzip -o inter.zip -d ./inter || true
  find inter -type f -name "*.ttf" -exec mv {} . \; || true
fi
fc-cache -fv || true

# Inform about proprietary SF fonts
echo
echo "NOTE: This installer uses Inter/Noto as open replacements for macOS SF fonts."
echo "If you own SF Pro / SF Mono and want them, install them manually into $FONT_DIR and run 'fc-cache -fv'."

# --------- Desktop environment specific tweaks (KDE / XFCE) ---------
DE="unknown"
if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
  DE="kde"
elif [[ "${XDG_CURRENT_DESKTOP:-}" == *XFCE* ]]; then
  DE="xfce"
fi
header "Detected desktop environment: $DE (if this is wrong, you can still apply themes manually)"

if [[ "$DE" == "kde" ]]; then
  header "Applying KDE-specific settings..."
  # apply kvantum or widget settings if kvantum installed
  if command -v kvantummanager &>/dev/null; then
    # try to set theme if available
    kvantummanager --set WhiteSur-Dark || true
  fi
  kwriteconfig5 --file kdeglobals --group Icons --key Theme "WhiteSur-dark" || true
  kquitapp5 plasmashell &>/dev/null || true
  kstart5 plasmashell &>/dev/null || true
elif [[ "$DE" == "xfce" ]]; then
  header "Applying XFCE-specific settings..."
  xfconf-query -c xsettings -p /Net/ThemeName -s "WhiteSur-Dark" || true
  xfconf-query -c xsettings -p /Net/IconThemeName -s "WhiteSur-dark" || true
  xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "WhiteSur-cursors" || true
  xfconf-query -c xfwm4 -p /general/theme -s "WhiteSur-Dark" || true
  xfconf-query -c xfwm4 -p /general/use_compositing -s true || true
fi

# --------- Plank dock configuration & autostart ---------
header "Configuring Plank dock and autostart"
mkdir -p "$HOME/.config/plank/dock1/launchers"
# create a basic autostart .desktop
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Dock
EOF

# add some default launchers (Terminal, File Manager)
mkdir -p "$HOME/.local/share/applications"
# Create example .desktop launchers if they don't exist
if [ ! -f "$HOME/.local/share/applications/org.kde.konsole.desktop" ]; then
  cat > "$HOME/.local/share/applications/terminal.desktop" <<EO
[Desktop Entry]
Name=Terminal
Exec=alacritty
Icon=utilities-terminal
Type=Application
Categories=Utility;TerminalEmulator;
EO
fi

# --------- Komorebi autostart (live wallpaper) ---------
if command -v komorebi &>/dev/null; then
  cat > "$HOME/.config/autostart/komorebi.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=komorebi
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Komorebi Wallpaper
EOF
fi

# --------- Developer Tooling: Python ---------
header "Installing Python developer tooling (pip packages)..."
# upgrade pip and install tools in user context
python -m pip install --upgrade pip wheel setuptools --user
python -m pip install --user "${DEV_PY_PACKAGES[@]}" || true

# Install pyenv dependencies (allow building python versions)
header "Installing pyenv build dependencies (so you can install Python 3.12 via pyenv if needed)..."
sudo pacman -S --needed --noconfirm openssl zlib xz libffi bzip2 make cmake

# Optional: install pyenv (via git) in user's home
if [ ! -d "$HOME/.pyenv" ]; then
  header "Installing pyenv (optional) to manage Python versions..."
  git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
  # Shell instructions appended to .bashrc/.zshrc
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$HOME/.bashrc"
  echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> "$HOME/.bashrc"
  echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> "$HOME/.bashrc"
  echo "pyenv installed. Re-open your shell to use it (or source ~/.bashrc). To install Python 3.12: pyenv install 3.12.x"
fi

# --------- Developer Tooling: NodeJS / JS ---------
header "Installing Node global tooling (pnpm)..."
# pnpm via npm
sudo npm install -g pnpm || true
# yarn already installed via pacman (if not, user can install via npm if desired)
# optionally install global developer tools (eslint, typescript)
sudo npm install -g eslint typescript nodemon || true

# --------- IDE / Editor (Visual Studio Code via AUR) ---------
header "Installing Visual Studio Code (AUR) and other dev apps via AUR..."
if command -v "$AUR_HELPER" &>/dev/null; then
  "$AUR_HELPER" -S --noconfirm --needed visual-studio-code-bin || true
fi

# --------- Docker Setup (optional) ---------
header "Configuring Docker (add $USER to docker group)..."
sudo systemctl enable --now docker || true
sudo usermod -aG docker "$USER" || true

# --------- Ethical security tools extra (AUR) ---------
header "Installing ethical/research tools from AUR (Ghidra, Burp Suite, etc.)"
if command -v "$AUR_HELPER" &>/dev/null; then
  "$AUR_HELPER" -S --noconfirm --needed "${ETHICAL_TOOLS_AUR[@]}" || true
fi

# --------- Additional recommended packages ----------
header "Installing extra useful tools (git-related, terminal, utils)..."
sudo pacman -S --needed --noconfirm htop tmux ripgrep fd exa

# --------- Clean up temporary files ----------
header "Cleaning temporary files..."
rm -rf "$TMPDIR"

# --------- Final notes ----------
header "Installation complete (themes, dev tools, and ethical toolkits installed where possible)."

cat <<EOF

WHAT'S INSTALLED / DONE:
- WhiteSur-like GTK/Icon/Cursor themes installed under: $THEME_DIR and $ICON_DIR
- Plank dock configured to autostart
- Komorebi installed (AUR) and configured to autostart (if komorebi available)
- Fonts: Noto + Inter installed (open replacements). Install SF fonts manually if you own them.
- Developer stack:
    * Python (system) + pip + pipenv, poetry, black, mypy, isort, pylint
    * pyenv installed to manage custom Python versions (e.g., 3.12)
    * Node.js + npm + pnpm + yarn + common global tools
    * Visual Studio Code (AUR) installed as visual-studio-code-bin
    * Docker + docker-compose enabled
- Ethical/security tools (legal/ethical set):
    * nmap, wireshark, mitmproxy, radare2, binwalk, ghidra (AUR), burpsuite (AUR), pwntools (AUR)
    * others: john, hashcat (AUR) possibly installed depending on package list

IMPORTANT:
- Some packages (komorebi, ghidra, burpsuite, visual-studio-code-bin, etc.) are installed from AUR using '$AUR_HELPER'.
  AUR package builds require base-devel and may prompt during build if paru isn't fully non-interactive on your system.
- Proprietary macOS fonts (SF Pro / SF Mono) are **not** included due to licensing; you can add them manually to $FONT_DIR.
- This script aims to install legal, open-source tools useful for security research/testing.
  Do NOT use these tools for illegal activities. Always have explicit authorization before testing systems you do not own.

RECOMMENDATIONS:
- Log out and log in again to apply theme and group membership changes (docker).
- If you want Python 3.12 specifically via pyenv:
    1) Open a new shell (source ~/.bashrc)
    2) pyenv install 3.12.x
    3) pyenv global 3.12.x

FEEDBACK:
If you want:
- a) a revert script that removes all installed files and restores defaults, or
- b) extra config: Plank theme, more plank launchers, sample dotfiles, or
- c) automated installation of SF Pro fonts (if you provide them),
Tell me which and I will append it.

EOF

exit 0
