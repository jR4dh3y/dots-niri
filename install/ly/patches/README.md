# Ly bigclock background panel

Stock Ly skips cells with `ch == 0`, so empty digit holes never paint a background
and the animation shows through the big clock.

## Patch

`0001-bigclock-bg-panel.patch` draws a solid panel (+ border) behind the big clock
before painting the digits.

Requires `bg = 0x20000000` (true black) in `/etc/ly/config.ini` for a solid black panel.

## Rebuild / reinstall after `ly` package updates

```bash
# needs zig >= 0.16
cd /tmp
rm -rf ly-bigclock-bg
git clone --depth 1 --branch v1.4.1 https://github.com/fairyglade/ly.git ly-bigclock-bg
cd ly-bigclock-bg
patch -p1 < ~/code/dots-niri/install/ly/patches/0001-bigclock-bg-panel.patch
zig build -Doptimize=ReleaseSafe
sudo cp -a /usr/bin/ly-dm /usr/bin/ly-dm.stock.bak
sudo install -Dm755 zig-out/bin/ly /usr/bin/ly-dm
sudo systemctl restart ly@tty2
```

Stock binary backup (from first install): `/usr/bin/ly-dm.stock-1.4.1`
