## niri-dots (Arch Linux)

Dotfiles and an automated installer

If you only need the wallpaper assets, see `assets/wal/`.

### Preview

![preview](assets/Screenshot%20from%202025-08-12%2021-24-06.png)

## What the installer does

- Tweaks pacman (Color and Parallel Downloads)
- Adds Chaotic-AUR repo (keyring + mirrorlist)
- Installs prerequisites (base-devel, git, curl, wget, rsync, etc.)
- Installs paru (AUR helper) if missing
- Installs packages from `pkg.txt` and `pkg-aur.txt` using paru (deduplicated)
- Symlinks repo `.config/` to `~/.config/` and syncs `.local/` into `~/.local/`
- Copies wallpapers from `assets/wal/` to `~/.local/share/wallpapers/`
- Enables available services: `ly`, `power-profiles-daemon`, `auto-cpufreq`, `swayidle`, `swaync`
- Refreshes the font cache


## Install

1) Clone the repo

```bash
git clone https://github.com/jr4dh3y/dots-niri.git "$HOME/code/dots-niri"
cd "$HOME/code/dots-niri"
```

2) Optionally edit package lists

- `pkg.txt` for official/Chaotic packages
- `pkg-aur.txt` for AUR packages

3) Run the installer

```bash
chmod +x install.sh
./install.sh
```

## Post-install tips

- Switch your shell to fish (optional): `chsh -s /usr/bin/fish`
- Change wallpaper: `wallpaper ~/.local/share/wallpapers/<file>`

## Troubleshooting

- Pacman is locked: remove the stale DB lock: `sudo rm -f /var/lib/pacman/db.lck`
- Chaotic-AUR key issues: ensure keyserver access or re-run the installer; it retries key import and installs the keyring package.
- AUR build failures: re-run just that package with `paru -S <pkg>` to see full logs.

## Uninstall/rollback notes

- The installer backs up any existing `~/.config/<name>` as `<name>.bak` before linking. You can restore from those `.bak` folders if needed.

---

Made for personal use; adapt as needed. PRs/issues welcome.

