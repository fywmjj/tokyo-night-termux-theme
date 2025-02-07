#!/bin/bash

# Detect if fzf is available
HAS_FZF=$(command -v fzf >/dev/null 2>&1 && echo 1 || echo 0)

# Get script directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")
THEME_DIR="${SCRIPT_DIR}/tokyonight"

# Verify theme directory exists
if [[ ! -d "$THEME_DIR" ]]; then
    echo "Error: Theme directory not found at $THEME_DIR" >&2
    exit 1
fi

# Theme selection
options=("Tokyo Night" "Tokyo Night Light" "Tokyo Storm")
if [[ $HAS_FZF -eq 1 ]]; then
    selected_theme=$(printf "%s\n" "${options[@]}" | fzf --prompt="Choose a theme: ") || { echo "Aborted." >&2; exit 1; }
else
    PS3="Choose a theme (1-3): "
    select selected_theme in "${options[@]}"; do
        [[ -n $selected_theme ]] && break
        echo "Invalid selection. Try again."
    done
fi

# Map selection to filename
case $selected_theme in
    "Tokyo Night") file="TokyoNight.properties" ;;
    "Tokyo Night Light") file="TokyoNight.Light.properties" ;;
    "Tokyo Storm") file="TokyoStorm.properties" ;;
    *) echo "Invalid theme" >&2; exit 1 ;;
esac

src_file="${THEME_DIR}/${file}"
if [[ ! -f "$src_file" ]]; then
    echo "Error: Theme file $file not found" >&2
    exit 1
fi

# Backup logic
if [[ -f "$HOME/.termux/colors.properties" ]]; then
    if [[ $HAS_FZF -eq 1 ]]; then
        backup_choice=$(echo -e "Yes\nNo" | fzf --prompt="Backup current config? ") || { echo "Aborted." >&2; exit 1; }
    else
        read -p "Backup current colors.properties? [y/N] " yn
        case ${yn,,} in
            y*) backup_choice="Yes" ;;
            *) backup_choice="No" ;;
        esac
    fi

    if [[ $backup_choice == "Yes" ]]; then
        if ! cp "$HOME/.termux/colors.properties" "$HOME/.termux/colors.properties.bak"; then
            echo "Backup failed!" >&2
            exit 1
        fi
        echo "Backup created: $HOME/.termux/colors.properties.bak"
    fi
else
    echo "No existing colors.properties found. Skipping backup."
fi

# Apply theme
mkdir -p "$HOME/.termux"
if ! cp "$src_file" "$HOME/.termux/colors.properties"; then
    echo "Failed to apply theme!" >&2
    exit 1
fi
echo "Theme applied successfully."

# Reload prompt
if [[ $HAS_FZF -eq 1 ]]; then
    reload_choice=$(echo -e "Yes\nNo" | fzf --prompt="Reload Termux now? ") || { echo "Aborted." >&2; exit 1; }
else
    read -p "Reload Termux settings now? [y/N] " yn
    case ${yn,,} in
        y*) reload_choice="Yes" ;;
        *) reload_choice="No" ;;
    esac
fi

if [[ $reload_choice == "Yes" ]]; then
    termux-reload-settings
    exit 0
else
    echo "Manual reload required for changes to take effect."
    exit 1
fi
