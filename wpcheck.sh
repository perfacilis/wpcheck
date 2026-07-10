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
  wp_cli config get "$OPTION" 2>/dev/null || true
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

wp_check_automatic_updater_plugin() {
  if wp_cli plugin is-active "automatic-updater"; then
    success "Plugin automatic-updater aka 'Advanced Automatic Updates' found!"
  else
    error "Plugin automatic-updater aka 'Advanced Automatic Updates' not found!"
  fi
}

wp_check_inactive_themes() {
  local THEMES CURRENT_THEME THEME_NAME
  THEMES=$(wp_cli theme list --field=name)
  CURRENT_THEME=$(wp_cli theme list --field=name --status=active)

  for THEME_NAME in $THEMES; do
    if [ "$THEME_NAME" = "$CURRENT_THEME" ]; then
      success "Theme '$THEME_NAME' is current theme, leave as is."
    else
      error "Theme '$THEME_NAME' MUST be removed!"
    fi
  done
}

wp_check_core_updates() {
  local NEW_VERSION
  NEW_VERSION=$(wp_cli core check-update --field=version)

  if [ ! -z "$NEW_VERSION" ]; then
    error "Wordpress MUST be updated to $NEW_VERSION."
  fi
}

wp_check_plugin_updates() {
  local UPDATE_PLUGINS PLUGIN_NAME
  UPDATE_PLUGINS=$(wp_cli plugin list --update=available --field=name)

  for PLUGIN_NAME in $UPDATE_PLUGINS; do
    error "Plugin '$PLUGIN_NAME' MUST be up[dated."
  done
}

wp_verify_core_checksums() {
  wp_cli core verify-checksums
}

wp_use_nonstandard_table_prefix() {
  local TABLE_PREFIX
  TABLE_PREFIX=$(wp_config_value table_prefix)

  if [ "$TABLE_PREFIX" = "wp_" ]; then
    error "Table prefix '$TABLE_PREFIX' SHOULD be changed to something non standard."
  else
    success "Table prefix '$TABLE_PREFIX' is non standard, great!"
  fi
}

main() {
  if [ ! -d "$ROOT" ]; then
    echo "Usage $0 /path/to/wordpress/root"
    exit 1
  fi

  # MUST fix
  wp_check_config_in_parent_dir
  wp_check_config_debug_disabled
  wp_check_config_disallow_file_edit
  wp_check_automatic_updater_plugin
  wp_check_inactive_themes
  wp_check_core_updates
  wp_check_plugin_updates
  wp_verify_core_checksums

  # SHOULD fix
  wp_use_nonstandard_table_prefix
}

main
