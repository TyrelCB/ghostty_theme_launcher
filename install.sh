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
icon_root="${data_dir}/icons/hicolor"

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

install_launcher_icon() {
  source_icon="$1"

  case "$source_icon" in
    /*)
      [ -f "$source_icon" ] || return 1
      ;;
    *)
      return 1
      ;;
  esac

  source_name="$(basename "$source_icon")"
  case "$source_name" in
    *.*)
      icon_ext="${source_name##*.}"
      ;;
    *)
      return 1
      ;;
  esac

  icon_subdir="$(printf '%s\n' "$source_icon" | sed -n 's|.*/icons/[^/]*/\([^/]*/apps\)/[^/]*$|\1|p')"
  if [ -z "$icon_subdir" ]; then
    case "$icon_ext" in
      svg)
        icon_subdir="scalable/apps"
        ;;
      png|xpm)
        icon_subdir="128x128/apps"
        ;;
      *)
        return 1
        ;;
    esac
  fi

  target_dir="${icon_root}/${icon_subdir}"
  mkdir -p "$target_dir"

  if [ -f "/usr/share/icons/hicolor/index.theme" ] && [ ! -f "${icon_root}/index.theme" ]; then
    install -Dm644 /usr/share/icons/hicolor/index.theme "${icon_root}/index.theme"
  fi

  install -Dm644 "$source_icon" "${target_dir}/${launcher_name}.${icon_ext}"
}

refresh_desktop_metadata() {
  if command -v gtk-update-icon-cache >/dev/null 2>&1 && [ -f "${icon_root}/index.theme" ]; then
    gtk-update-icon-cache -f -t "$icon_root" >/dev/null 2>&1 || true
  fi

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$app_dir" >/dev/null 2>&1 || true
  fi
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
launcher_icon_value="$icon_value"
if install_launcher_icon "$icon_value"; then
  launcher_icon_value="$launcher_name"
fi
sed \
  -e "s|^TryExec=.*$|TryExec=${launcher_path}|" \
  -e "s|^Exec=.*$|Exec=${launcher_path}|" \
  -e "s|^Icon=.*$|Icon=${launcher_icon_value}|" \
  "${tmp_dir}/${desktop_name}" > "$desktop_path"
chmod 644 "$desktop_path"
refresh_desktop_metadata

printf 'Installed Ghostty Theme Launcher to %s\n' "$launcher_path"
printf 'Installed desktop entry to %s\n' "$desktop_path"

if ! command -v ghostty >/dev/null 2>&1; then
  printf 'Warning: ghostty is not available in PATH yet.\n' >&2
fi

if ! command -v zenity >/dev/null 2>&1; then
  printf 'Warning: zenity is not installed yet.\n' >&2
fi
