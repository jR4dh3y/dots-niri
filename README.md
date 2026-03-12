## niri-dots (Arch Linux)

Dotfiles plus an interactive terminal installer.

If you only need the wallpaper assets, see `assets/wal/`.

### Preview

![preview](assets/Screenshot%20from%202025-08-12%2021-24-06.png)

## What the installer does

- Tweaks pacman (Color and Parallel Downloads)
- Adds Chaotic-AUR repo (keyring + mirrorlist)
- Installs prerequisites (base-devel, git, curl, wget, rsync, etc.)
- Installs paru (AUR helper) if missing
- Installs packages from `install/pkg.txt` plus auto-detected CPU/GPU vendor package lists using paru (deduplicated)
- Symlinks repo `.config/` to `~/.config/` and syncs `.local/` into `~/.local/`
- Initializes git submodules before syncing local apps like `wallpygui` and `iwd-applet`
- Copies wallpapers from `assets/wal/` to `~/.local/share/wallpapers/`
- Installs the tracked `ly` config into `/etc/ly/config.ini`
- Enables available services: `ly`, `iwd`, `power-profiles-daemon`
- Refreshes the font cache


## Install

1) Clone the repo

```bash
git clone --recurse-submodules https://github.com/jr4dh3y/dots-niri.git "$HOME/code/dots-niri"
cd "$HOME/code/dots-niri"
```

2) Optionally edit package lists

- `install/pkg.txt` for the main package list
- `install/pkg-cpu-intel.txt` / `install/pkg-cpu-amd.txt` for CPU microcode
- `install/pkg-gpu-intel.txt` / `install/pkg-gpu-amd.txt` / `install/pkg-nvi.txt` for GPU-specific packages

3) Run the installer

```bash
chmod +x install/install.sh
./install/install.sh
```

By default the installer opens a keyboard-driven terminal UI with arrow-key navigation, space-to-toggle checkboxes, and enter-to-confirm so you can choose between a full install and a custom run.

### One-line bootstrap

If you want a single URL that clones/updates the repo into `~/code/dots-niri` and then opens the regular installer UI, use `oneline.sh`:

```bash
curl -fsSL https://jr4.in/niri | bash
```

or:

```bash
wget -qO- https://jr4.in/niri | bash
```

You can also forward installer flags after the shell separator `--`:

```bash
curl -fsSL https://jr4.in/niri | bash -s -- --sync-only
```

During install, the script will also ask for the weather widget location. You can enter a city, state, full address, or pincode.

The installer auto-detects:

- CPU vendor and installs the matching microcode package (`intel-ucode` or `amd-ucode`)
- GPU vendor(s) and installs matching graphics packages for Intel, AMD/Mesa, and/or NVIDIA

## Post-install tips

- Switch your shell to fish (optional): `chsh -s /usr/bin/fish`
- Change wallpaper: `wallpaper ~/.local/share/wallpapers/<file>`
- `iwd-applet` is started via `~/.config/autostart/iwd-applet.desktop`, avoiding duplicate launches with `niri`

## Troubleshooting

- Pacman is locked: remove the stale DB lock: `sudo rm -f /var/lib/pacman/db.lck`
- Chaotic-AUR key issues: ensure keyserver access or re-run the installer; it retries key import and installs the keyring package.
- AUR build failures: re-run just that package with `paru -S <pkg>` to see full logs.

## Uninstall/rollback notes

- The installer backs up any existing `~/.config/<name>` as `<name>.bak` before linking. You can restore from those `.bak` folders if needed.

---

Made for personal use; adapt as needed. PRs/issues welcome.

