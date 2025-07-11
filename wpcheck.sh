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

wp_config_file() {
  if [ -f "$ROOT/../wp-config.php" ]; then
    echo "$ROOT/../wp-config.php";
    return 0
  fi

  if [ -f "$ROOT/wp-config.php" ]; then
    echo "$ROOT/wp-config.php";
    return 0
  fi

  error "Cannot find wp-config.php!"
  exit 1
}

wp_config_value() {
  local WPCONFIG VALUE OPTION="$1"
  WPCONFIG=$(wp_config_file)
  VALUE="$(grep -oP "define\( *['\"]${OPTION}['\"], *\K(.+)\);" "$WPCONFIG" | sed "s/^[ '\"]*//;s/[ '\"]*);//")"

  if [ -z "$VALUE" ]; then
    echo "null";
    return 1
  fi

  echo "$VALUE"
  return 0
}

wp_table_prefix() {
  local WPCONFIG=$(wp_config_file)
  grep "\$table_prefix" "$WPCONFIG" | cut -d"'" -f2
}

wp_option_value() {
  local USER PASS HOST DBNAME DBMS="mysql" OPTION="$1"
  USER=$(wp_config_value 'DB_USER')
  PASS=$(wp_config_value 'DB_PASSWORD')
  HOST=$(wp_config_value 'DB_HOST')
  DBNAME=$(wp_config_value 'DB_NAME')
  DBPREFIX=$(wp_table_prefix)

  if [ -z "$OPTION" ]; then
    echo "Usage: wp_option_value OPTION"
    exit 1
  fi

  if which mariadb >/dev/null 2>&1; then
    DBMS="mariadb"
  fi

  $DBMS -h"$HOST" -u"$USER" -p"$PASS" --database "$DBNAME" -Bse "SELECT option_value FROM ${DBPREFIX}options WHERE option_name = '$OPTION';"
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

  if [ "${WP_DEBUG,,}" = "false" ]; then
    success "Config 'WP_DEBUG' properly set to FALSE."
  else
    error "Config 'WP_DEBUG' MUST be set to FALSE."
  fi
}

wp_check_config_disallow_file_edit() {
  local DISALLOW_FILE_EDIT
  DISALLOW_FILE_EDIT=$(wp_config_value 'DISALLOW_FILE_EDIT')

  if [ "${DISALLOW_FILE_EDIT,,}" = "true" ]; then
    success "Config 'DISALLOW_FILE_EDIT' properly set to TRUE"
  else
    error "Config 'DISALLOW_FILE_EDIT' MUST be set to TRUE"
  fi
}

wp_check_automatic_updater_plugin() {
  local PLUGIN_DIR="$ROOT/wp-content/plugins/"
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

main() {
  if [ ! -d "$ROOT" ]; then
    echo "Usage $0 /path/to/wordpress/root"
    exit 1
  fi

  wp_check_config_in_parent_dir
  wp_check_config_debug_disabled
  wp_check_config_disallow_file_edit
  wp_check_automatic_updater_plugin
  wp_check_inactive_themes
}

main
