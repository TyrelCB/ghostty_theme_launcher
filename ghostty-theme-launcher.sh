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

ghostty_bin="${GHOSTTY_BIN:-$(command -v ghostty || true)}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
preview_helper="${script_dir}/ghostty-theme-launcher-preview"
shell_helper="${script_dir}/ghostty-theme-launcher-shell"

if [[ -x "${preview_helper}" ]]; then
  if selection="$("${preview_helper}" "${themes[@]}")"; then
    :
  else
    helper_status=$?
    if [[ "${helper_status}" -eq 1 ]]; then
      exit 0
    fi
  fi
fi

if [[ -z "${ghostty_bin}" ]]; then
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --title="Ghostty Theme Launcher" --text="Ghostty was not found in PATH."
  else
    printf 'Ghostty was not found in PATH.\n' >&2
  fi
  exit 1
fi

if [[ -z "${selection:-}" ]]; then
  if ! command -v zenity >/dev/null 2>&1; then
    printf 'zenity is required for the Ghostty theme launcher fallback dialog.\n' >&2
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
fi

if [[ "${selection}" == "Random" ]]; then
  selection="${themes[RANDOM % ${#themes[@]}]}"
fi

launch_dir="${PWD:-$HOME}"
if resolved_dir="$(pwd -P 2>/dev/null)"; then
  launch_dir="${resolved_dir}"
fi

user_shell="${GHOSTTY_THEME_LAUNCHER_SHELL:-${SHELL:-/usr/bin/bash}}"
shell_name="${user_shell##*/}"

if [[ -x "${shell_helper}" && "${shell_name}" == "bash" ]]; then
  exec "${ghostty_bin}" \
    --gtk-single-instance=false \
    --theme="${selection}" \
    --working-directory="${launch_dir}" \
    --env="GHOSTTY_THEME_LAUNCHER_THEME=${selection}" \
    --env="GHOSTTY_THEME_LAUNCHER_IDLE_APP=${shell_name}" \
    --env="GHOSTTY_THEME_LAUNCHER_TARGET_SHELL=${user_shell}" \
    -e "${shell_helper}"
fi

window_title="${selection} - ${launch_dir}"

exec "${ghostty_bin}" \
  --gtk-single-instance=false \
  --theme="${selection}" \
  --title="${window_title}"
