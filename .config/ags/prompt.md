Act as a developer building a custom widget-based dashboard panel using AGS (A Glorious Start) for the Niri window manager on Wayland. The panel should open as a vertical drawer from the right side of the screen, toggleable via a hotkey or script. It should not be a top/bottom bar.

The panel should include:

1. **System Stats**: Show live CPU, RAM, Power, Gpu, and temperature stats using tools like `top`, `free`, and `sensors`.
2. **Media Player Widget**: Show current playing song via `playerctl` with play/pause/next/previous buttons.
3. **Notification Center**: Display latest notifications, with ability to clear them.
4. **Volume and Brightness Controls**: Use `pactl` and `brightnessctl`, with sliders or buttons.
5. **Clock and Calendar**: Show time and allow toggling a calendar (e.g., with `cal` or a graphical calendar).
6. **Network Info**: Show current connection, IP address, and download/upload speeds.
7. **Optional Buttons**: Add buttons to log out, reboot, lock, etc.

Panel requirements:
- Vertical layout, slides in from the **right**
- Rounded corners, minimal blur or transparency (Wayland-safe)
- Auto-hides or toggles via script or keybinding (e.g., using `ags -t`)
- Modular widget structure (each widget in a separate file)
- Use AGS best practices (`Widget`, `Utils.execAsync`, `Notifications`, etc.)

Output: modular AGS config in JavaScript (GJS syntax), with a `dashboard.js` or `panel.js` file that constructs the full panel.

Optional: Add smooth transition animation when opening/closing the panel.
