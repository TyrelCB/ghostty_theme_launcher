# Ghostty Theme Launcher

This project provides a small Linux launcher for Ghostty that prompts for a
theme before opening a new terminal window.

It uses `zenity` for the picker dialog and launches Ghostty with
`--gtk-single-instance=false` so the selected theme is respected even if
Ghostty is already running.

## What It Does

- Shows a graphical picker with a curated list of Ghostty themes.
- Includes a `Random` option that selects from the same curated list.
- Starts a new Ghostty window with the chosen theme.
- Sets the window title to `<theme> - <pwd>` at launch time.
- Reuses the standard Ghostty icon and appears as a normal desktop launcher.

## Files

- `ghostty-theme-launcher.sh`: Theme picker and Ghostty launcher script.
- `ghostty-theme-launcher.desktop`: Desktop entry that points to the installed script.

## Requirements

- Linux with Ghostty installed and available in `PATH`
- `zenity`
- A desktop environment that reads `.desktop` files from
  `~/.local/share/applications`

## Included Themes

- Vibrant Ink
- Argonaut
- Blue Matrix
- Box
- Cobalt Neon
- Cyberdyne
- Cyberpunk Scarlet Protocol
- Duotone Dark
- Vercel
- Firefly Traditional
- Firefox Dev
- Grape
- Grey Green
- Gruvbox Material
- Heeler
- Homebrew
- Kolorit
- Laser
- Monokai Remastered
- Neon
- Oxocarbon
- Phala Green Dark
- Powershell
- Purple Rain
- Sakura
- Shaman
- Slate
- Synthwave
- Treehouse
- Wez

## How It Works

The launcher script builds a `zenity --list --radiolist` dialog from the theme
array in `ghostty-theme-launcher.sh`.

If `Random` is selected, the script chooses a theme from the curated list using
Bash's `RANDOM`.

The final Ghostty invocation looks like this in principle:

```bash
ghostty --gtk-single-instance=false --theme="<theme>" --title="<theme> - <pwd>"
```

## Installation

Install the script into `~/.local/bin`:

```bash
install -Dm755 ghostty-theme-launcher.sh ~/.local/bin/ghostty-theme-launcher
```

Install the desktop entry into `~/.local/share/applications`:

```bash
install -Dm644 ghostty-theme-launcher.desktop \
  ~/.local/share/applications/ghostty-theme-launcher.desktop
```

The desktop entry expects the installed script at:

```text
/home/tyrel/.local/bin/ghostty-theme-launcher
```

## Usage

Launch `Ghostty Theme Launcher` from your application menu.

You can also run the installed script directly:

```bash
~/.local/bin/ghostty-theme-launcher
```

## Title Behavior

The launcher sets the Ghostty window title to:

```text
<theme> - <pwd>
```

This is the launch directory at startup, not a live-updating shell title.

If the launcher is started from a desktop menu, the working directory is often
your home directory, so the title will usually look like:

```text
Vibrant Ink - /home/tyrel
```

If you want the title to update whenever you `cd`, that should be implemented
through shell integration instead of a fixed `--title` argument.

## Customization

Edit the `themes` array in `ghostty-theme-launcher.sh` to add, remove, or
reorder themes.

Change the default selected theme by updating the `Vibrant Ink` check in the
dialog-building loop.

Change the title format by editing the `window_title` assignment near the end
of the script.

## Validation

Validate the script syntax:

```bash
bash -n ghostty-theme-launcher.sh
```

Validate the desktop entry:

```bash
desktop-file-validate ghostty-theme-launcher.desktop
```

## Troubleshooting

If nothing opens, confirm that `ghostty` is available in `PATH`.

If the picker does not appear, confirm that `zenity` is installed and that
you are launching from a graphical session.

If the launcher does not show up in your application menu immediately, log out
and back in or wait for your desktop environment to refresh its launcher cache.
