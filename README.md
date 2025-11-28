# Quickshell Bar

A customizable status bar for Hyprland.

## Prerequisites

- Hyprland
- Quickshell
- Qt 6
- PulseAudio (for volume display)

## Installation

### Option 1: Clone directly to config:

```bash
git clone https://github.com/xWalfie-SMR/quickshell-bar.git ~/.config/quickshell
```

### Option 2: Clone to current directory and symlink:

```bash
git clone https://github.com/xWalfie-SMR/quickshell-bar.git
ln -sfn quickshell-bar ~/.config/quickshell
```

### Or with dotfiles:

If using [my dotfiles](https://github.com/xWalfie-SMR/dotfiles), quickshell-bar is installed automatically.

## Usage

```bash
quickshell
```

Or add to your `hyprland.conf`:

```bash
exec-once = quickshell
```

## Features

- **Logo**: Custom Arch icon
- **Media Info**: MPRIS-compatible player info (Spotify, VLC, etc.)
- **Workspaces**: Interactive workspace indicators (1-10) with animations
- **Time/Date**: Current time and date display
- **Volume**: Real-time volume via PulseAudio

## Configuration

Edit `shell.qml` to customize:

- Colors (border, workspace indicators)
- Panel height and margins
- Time/date format
- Workspace count
- Font sizes

Edit `Globals.qml` for fonts and icons.

## License

MIT License (see [LICENSE](LICENSE))
