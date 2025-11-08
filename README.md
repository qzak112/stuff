# stuff 
> PROJECT STATUS : SUCCESS! (Tested on actual hardware)

> WARNING! : This script is currently a school project. It is designed to run ONLY on a fresh Arch Linux base installation. Do not run this on an existing production environment, as it performs destructive actions.

# Arch Linux Automated Setup Script

Automated installation script for Arch Linux with XFCE desktop environment.

## Features
- Core package installation (git, vim, neovim, fish, firefox, etc.)
- XFCE4 desktop environment
- AUR helper (yay) with Discord & Spotify
- Automatic user configuration
- System maintenance and cleanup

## Usage
```bash
chmod +x install.sh
sudo ./install.sh
```

## Requirements
- Fresh Arch Linux installation
- Internet connection
- Non-root user with sudo privileges
- Package 'git' and 'base-devel' should be installed.

## Packages Installed
### Core
- Development: git, vim, neovim
- System: btop, fish, networkmanager
- Desktop: xfce4, xfce4-goodies, ly (display manager)
- Audio: pulseaudio, alsa-utils

### AUR
- Discord
- Spotify

## License
MIT

## Known Issues
- [x] Test on actual hardware

## TODO
- [ ] Add option to skip AUR packages
- [ ] Add more desktop environment choices
- [ ] Test on fossil hardware (2GB RAM systems)

## Author
Made by a high school student that accidentally discovered linux 2 months ago.
