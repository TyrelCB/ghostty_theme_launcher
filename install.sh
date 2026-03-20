#!/usr/bin/env sh

set -eu

repo_base="${GHOSTTY_THEME_LAUNCHER_REPO:-https://raw.githubusercontent.com/TyrelCB/ghostty_theme_launcher/main}"
launcher_name="ghostty-theme-launcher"
launcher_url="${repo_base}/${launcher_name}.sh"
desktop_name="${launcher_name}.desktop"
desktop_url="${repo_base}/${desktop_name}"

bin_dir="${HOME}/.local/bin"
data_dir="${XDG_DATA_HOME:-${HOME}/.local/share}"
app_dir="${data_dir}/applications"
launcher_path="${bin_dir}/${launcher_name}"
desktop_path="${app_dir}/${desktop_name}"

read_desktop_value() {
  key="$1"
  file="$2"

  awk -F= -v key="$key" '
    $1 == key {
      print substr($0, index($0, "=") + 1)
      exit
    }
  ' "$file"
}

find_icon_file() {
  icon_name="$1"

  case "$icon_name" in
    /*)
      if [ -f "$icon_name" ]; then
        printf '%s\n' "$icon_name"
        return 0
      fi
      return 1
      ;;
  esac

  for base_dir in \
    "${HOME}/.local/share/icons" \
    "${HOME}/.icons" \
    "/usr/local/share/icons" \
    "/usr/share/icons" \
    "/usr/share/pixmaps" \
    "/var/lib/flatpak/exports/share/icons" \
    "${HOME}/.local/share/flatpak/exports/share/icons"
  do
    [ -d "$base_dir" ] || continue

    for candidate in \
      "${icon_name}.svg" \
      "${icon_name}.png" \
      "${icon_name}.xpm"
    do
      found_path="$(find "$base_dir" -type f -name "$candidate" -print -quit 2>/dev/null || true)"
      if [ -n "$found_path" ]; then
        printf '%s\n' "$found_path"
        return 0
      fi
    done
  done

  return 1
}

resolve_ghostty_icon() {
  icon_value="com.mitchellh.ghostty"

  for desktop_file in \
    "${HOME}/.local/share/applications/com.mitchellh.ghostty.desktop" \
    "${HOME}/.local/share/flatpak/exports/share/applications/com.mitchellh.ghostty.desktop" \
    "/var/lib/flatpak/exports/share/applications/com.mitchellh.ghostty.desktop" \
    "/var/lib/snapd/desktop/applications/com.mitchellh.ghostty.desktop" \
    "/usr/local/share/applications/com.mitchellh.ghostty.desktop" \
    "/usr/share/applications/com.mitchellh.ghostty.desktop"
  do
    [ -f "$desktop_file" ] || continue
    desktop_icon="$(read_desktop_value Icon "$desktop_file")"
    if [ -n "$desktop_icon" ]; then
      icon_value="$desktop_icon"
      break
    fi
  done

  resolved_icon="$(find_icon_file "$icon_value" || true)"
  if [ -n "$resolved_icon" ]; then
    printf '%s\n' "$resolved_icon"
    return 0
  fi

  printf '%s\n' "$icon_value"
}

download() {
  url="$1"
  destination="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$destination"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$destination" "$url"
    return
  fi

  printf 'curl or wget is required to install Ghostty Theme Launcher.\n' >&2
  exit 1
}

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

download "$launcher_url" "${tmp_dir}/${launcher_name}.sh"
download "$desktop_url" "${tmp_dir}/${desktop_name}"

mkdir -p "$bin_dir" "$app_dir"
install -Dm755 "${tmp_dir}/${launcher_name}.sh" "$launcher_path"
icon_value="$(resolve_ghostty_icon)"
sed \
  -e "s|^TryExec=.*$|TryExec=${launcher_path}|" \
  -e "s|^Exec=.*$|Exec=${launcher_path}|" \
  -e "s|^Icon=.*$|Icon=${icon_value}|" \
  "${tmp_dir}/${desktop_name}" > "$desktop_path"
chmod 644 "$desktop_path"

printf 'Installed Ghostty Theme Launcher to %s\n' "$launcher_path"
printf 'Installed desktop entry to %s\n' "$desktop_path"

if ! command -v ghostty >/dev/null 2>&1; then
  printf 'Warning: ghostty is not available in PATH yet.\n' >&2
fi

if ! command -v zenity >/dev/null 2>&1; then
  printf 'Warning: zenity is not installed yet.\n' >&2
fi
