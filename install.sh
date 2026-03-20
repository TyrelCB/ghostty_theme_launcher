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
sed \
  -e "s|^TryExec=.*$|TryExec=${launcher_path}|" \
  -e "s|^Exec=.*$|Exec=${launcher_path}|" \
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
