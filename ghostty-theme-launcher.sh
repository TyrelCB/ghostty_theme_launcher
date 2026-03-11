#!/usr/bin/env bash

set -euo pipefail

themes=(
  "Vibrant Ink"
  "Argonaut"
  "Blue Matrix"
  "Box"
  "Cobalt Neon"
  "Cyberdyne"
  "Cyberpunk Scarlet Protocol"
  "Duotone Dark"
  "Vercel"
  "Firefly Traditional"
  "Firefox Dev"
  "Grape"
  "Grey Green"
  "Gruvbox Material"
  "Heeler"
  "Homebrew"
  "Kolorit"
  "Laser"
  "Monokai Remastered"
  "Neon"
  "Oxocarbon"
  "Phala Green Dark"
  "Powershell"
  "Purple Rain"
  "Sakura"
  "Shaman"
  "Slate"
  "Synthwave"
  "Treehouse"
  "Wez"
)

if ! command -v zenity >/dev/null 2>&1; then
  printf 'zenity is required for the Ghostty theme launcher.\n' >&2
  exit 1
fi

ghostty_bin="${GHOSTTY_BIN:-$(command -v ghostty || true)}"

if [[ -z "${ghostty_bin}" ]]; then
  zenity --error --title="Ghostty Theme Launcher" --text="Ghostty was not found in PATH."
  exit 1
fi

dialog_args=(
  --list
  --title="Ghostty Theme Launcher"
  --text="Choose a Ghostty theme"
  --radiolist
  --column=""
  --column="Theme"
)

dialog_args+=(FALSE "Random")
for theme in "${themes[@]}"; do
  if [[ "${theme}" == "Vibrant Ink" ]]; then
    dialog_args+=(TRUE "${theme}")
  else
    dialog_args+=(FALSE "${theme}")
  fi
done

dialog_args+=(--height=900 --width=420)

selection="$(zenity "${dialog_args[@]}")" || exit 0

if [[ "${selection}" == "Random" ]]; then
  selection="${themes[RANDOM % ${#themes[@]}]}"
fi

launch_dir="${PWD:-$HOME}"
if resolved_dir="$(pwd -P 2>/dev/null)"; then
  launch_dir="${resolved_dir}"
fi

window_title="${selection} - ${launch_dir}"

exec "${ghostty_bin}" \
  --gtk-single-instance=false \
  --theme="${selection}" \
  --title="${window_title}"
