#!/bin/bash

set -e

readonly ROOT="${1%/}"
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

success() {
  echo -e "- ${GREEN}$1${NC}"
}

error() {
  echo -e "- ${RED}$1${NC}"
}

wp_cli() {
  local WP_USER
  WP_USER=$(stat -c'%U' "$ROOT")

  sudo -u "$WP_USER" -- wp --path="$ROOT" "$@"
}

wp_config_value() {
  local OPTION="$1"
  wp_cli config get "$OPTION" 2>/dev/null
}

wp_table_prefix() {
  wp_config_value table_prefix
}

wp_option_value() {
  local OPTION="$1"
  wp_cli option get "$OPTION"
}

wp_check_config_in_parent_dir() {
  if [ -f "$ROOT/../wp-config.php" ]; then
    success "Config file 'wp-config.php' is in parent dir, great!"
  fi

  if [ -f "$ROOT/wp-config.php" ]; then
    error "Config file 'wp-config.php' MUST be in parent dir!"
  fi
}

wp_check_config_debug_disabled() {
  local WP_DEBUG
  WP_DEBUG=$(wp_config_value 'WP_DEBUG')

  if [ -z "$WP_DEBUG" ]; then
    success "Config 'WP_DEBUG' properly set to FALSE."
  else
    error "Config 'WP_DEBUG' MUST be set to FALSE."
  fi
}

wp_check_config_disallow_file_edit() {
  local DISALLOW_FILE_EDIT
  DISALLOW_FILE_EDIT=$(wp_config_value 'DISALLOW_FILE_EDIT')

  if [ "$DISALLOW_FILE_EDIT" = 1 ]; then
    success "Config 'DISALLOW_FILE_EDIT' properly set to TRUE"
  else
    error "Config 'DISALLOW_FILE_EDIT' MUST be set to TRUE"
  fi
}

wp_check_config_disallow_file_mods() {
  local DISALLOW_FILE_EDIT
  DISALLOW_FILE_EDIT=$(wp_config_value 'DISALLOW_FILE_MODS')

  if [ "$DISALLOW_FILE_EDIT" = 1 ]; then
    success "Config 'DISALLOW_FILE_MODS' properly set to TRUE"
  else
    error "Config 'DISALLOW_FILE_MODS' MUST be set to TRUE"
  fi
}

wp_check_automatic_updater_plugin() {
  local PLUGIN_DIR

  if ! PLUGIN_DIR=$(wp_config_value 'PLUGINDIR'); then
    PLUGIN_DIR="$ROOT/wp-content/plugins/";
  fi

  if [ -d "$PLUGIN_DIR/automatic-updater" ]; then
    success "Plugin automatic-updater aka 'Advanced Automatic Updates' found!"
  else
    error "Plugin automatic-updater aka 'Advanced Automatic Updates' not found!"
  fi
}

wp_check_inactive_themes() {
  local THEMES=$(find "$ROOT/wp-content/themes/" -mindepth 1 -maxdepth 1 -type d)
  local CURRENT_THEME=$(wp_option_value 'current_theme')
  local THEME THEME_NAME

  for THEME in $THEMES; do
    THEME_NAME=$(basename "$THEME")
    if [ "$THEME_NAME" = "${CURRENT_THEME,,}" ]; then
      success "Theme '$THEME_NAME' is current theme, leave as is."
    elif [ "$THEME_NAME" = "twentytwentyfive" ]; then
      success "Theme '$THEME_NAME' is wp default, leave as is."
    else
      error "Theme '$THEME_NAME' MUST be removed!"
    fi
  done
}

wp_verify_core_checksums() {
  wp_cli --path="$ROOT" core verify-checksums
}

main() {
  if [ ! -d "$ROOT" ]; then
    echo "Usage $0 /path/to/wordpress/root"
    exit 1
  fi

  wp_check_config_in_parent_dir
  wp_check_config_debug_disabled
  wp_check_config_disallow_file_edit
  wp_check_config_disallow_file_mods
  wp_check_automatic_updater_plugin
  wp_check_inactive_themes
  wp_verify_core_checksums
}

main
