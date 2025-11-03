#!/system/bin/sh
# Common functions for Custom Model Override

# Volume key prompt function
# Usage: chooseport "message"
# Returns: 0 for Vol Up (yes), 1 for Vol Down (no)
chooseport() {
  local EVENTS_DIR="${TMPDIR:-/data/local/tmp}"
  local EVENTS_FILE="$EVENTS_DIR/volume_events"
  
  while true; do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > "$EVENTS_FILE"
    if $(/system/bin/cat "$EVENTS_FILE" 2>/dev/null | /system/bin/grep VOLUME >/dev/null); then
      break
    fi
  done
  
  if $(/system/bin/cat "$EVENTS_FILE" | /system/bin/grep VOLUMEUP >/dev/null); then
    return 0
  else
    return 1
  fi
}

# Prompt with volume keys
# Usage: ask_user "Question text"
# Returns: 0 for yes, 1 for no
ask_user() {
  ui_print " "
  ui_print "$1"
  ui_print "  Vol Up   = Yes"
  ui_print "  Vol Down = No"
  if chooseport; then
    ui_print "→ Yes"
    return 0
  else
    ui_print "→ No"
    return 1
  fi
}

# Get device codename
get_device_codename() {
  # Priority order for codename detection (to avoid GSI generic names)
  
  # 1. Try product vendor properties first (contains real device codename)
  CODENAME=$(getprop ro.product.vendor.device)
  [ -z "$CODENAME" ] && CODENAME=$(getprop ro.product.vendor.name)
  
  # 2. Try odm properties
  [ -z "$CODENAME" ] && CODENAME=$(getprop ro.product.odm.device)
  [ -z "$CODENAME" ] && CODENAME=$(getprop ro.product.odm.name)
  
  # 3. Try system properties (may be GSI on some ROMs)
  [ -z "$CODENAME" ] && CODENAME=$(getprop ro.product.device)
  [ -z "$CODENAME" ] && CODENAME=$(getprop ro.product.name)
  [ -z "$CODENAME" ] && CODENAME=$(getprop ro.build.product)
  
  # 4. Filter out common GSI codenames
  case "$CODENAME" in
    *"arm64"*|*"arm"*|*"gsi"*|*"treble"*|*"generic"*)
      # This looks like a GSI name, try harder
      CODENAME=$(getprop ro.product.vendor.device)
      [ -z "$CODENAME" ] && CODENAME=$(getprop ro.product.board)
      ;;
  esac
  
  echo "$CODENAME"
}

# Get local offline db name from device database
get_local_offline_db() {
  local codename="$1"
  # Prefer module's device_db.txt (MODDIR) when available, otherwise fall back to TMPDIR
  local dbfile
  if [ -n "$MODDIR" ] && [ -f "$MODDIR/device_db.txt" ]; then
    dbfile="$MODDIR/device_db.txt"
  else
    dbfile="${TMPDIR:-/data/local/tmp}/device_db.txt"
  fi

  if [ -f "$dbfile" ]; then
    # Search for codename in database
    local result
    result=$(grep "^$codename=" "$dbfile" | cut -d'=' -f2-)
    if [ -n "$result" ]; then
      echo "$result"
      return 0
    fi
  fi

  # Not found
  return 1
}

# Fetch online model name from API
fetch_online_name() {
  local codename="$1"
  
  # Ensure TMPDIR is set for curl/wget to work properly
  export TMPDIR="${TMPDIR:-/data/local/tmp}"
  export HOME="${HOME:-/data/local/tmp}"
  
  # Check if curl or wget is available
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    return 1
  fi
  
  # Try API 1: Google's Android certified devices database
  local result=""
  local temp_csv="/data/local/tmp/devices_$$.csv"
  
  if command -v curl >/dev/null 2>&1; then
    curl -L -s --connect-timeout 10 --max-time 15 "https://storage.googleapis.com/play_public/supported_devices.csv" -o "$temp_csv" 2>/dev/null
  else
    wget -qO "$temp_csv" --timeout=15 "https://storage.googleapis.com/play_public/supported_devices.csv" 2>/dev/null
  fi
  
  if [ -f "$temp_csv" ]; then
    # Convert UTF-16LE CSV (Google export) to UTF-8 for reliable parsing
    local csv_utf8="${temp_csv}.utf8"
    if command -v iconv >/dev/null 2>&1; then
      iconv -f UTF-16LE -t UTF-8 "$temp_csv" > "$csv_utf8" 2>/dev/null || cp "$temp_csv" "$csv_utf8"
    else
      tr -d '\000' < "$temp_csv" | tr -d '\r' > "$csv_utf8" 2>/dev/null
    fi

    # Remove BOM if present
    if [ -f "$csv_utf8" ]; then
      local bom_bytes="$(head -c 3 "$csv_utf8" 2>/dev/null | od -An -t x1 | tr -d ' \n')"
      if [ "${bom_bytes}" = "efbbbf" ]; then
        tail -c +4 "$csv_utf8" > "${csv_utf8}.nobom" 2>/dev/null && mv "${csv_utf8}.nobom" "$csv_utf8"
      fi
    fi

    local csv_file="$csv_utf8"

    # CSV format: "Retail Branding","Marketing Name","Device","Model"
    local line=""
    local result=""

    # Search by pattern: ,"codename",
    line=$(grep ',"'"$codename"'",' "$csv_file" 2>/dev/null | head -1)
    # Fallbacks
    [ -z "$line" ] && line=$(grep ",$codename," "$csv_file" 2>/dev/null | head -1)
    [ -z "$line" ] && line=$(awk -F'","' -v code="$codename" '$3 == code || $3 == "\""code"\"" {print; exit}' "$csv_file" 2>/dev/null)

    if [ -n "$line" ]; then
      # Extract Marketing Name (2nd field)
      result=$(echo "$line" | sed -n 's/^"\([^\"]*\)","\([^\"]*\)","\([^\"]*\)".*/\2/p' | tr -d '\r')
      # Fallback via awk if sed failed
      [ -z "$result" ] && result=$(echo "$line" | awk -F'","' '{print $2}' | sed 's/^"//;s/"$//' | tr -d '\r')
    fi

    # Cleanup temp files
    rm -f "$csv_utf8" "$temp_csv" 2>/dev/null
  else
    ui_print "CSV not found: $temp_csv"
  fi
  
  if [ -n "$result" ] && [ "$result" != "Model" ]; then
    MODEL_NAME="$result"
    echo "$result"
    return 0
  fi
  
  # Try API 2: XDA Device database (GitHub mirror)
  local result2=""
  if command -v curl >/dev/null 2>&1; then
    result2=$(curl -L -s --connect-timeout 10 --max-time 15 "https://raw.githubusercontent.com/androidtrackers/certified-android-devices/master/by_device.json" 2>/dev/null | grep -A 10 "\"$codename\"" | grep "marketing_name" | head -1 | sed 's/.*: "//;s/".*//')
  else
    result2=$(wget -qO- --timeout=15 "https://raw.githubusercontent.com/androidtrackers/certified-android-devices/master/by_device.json" 2>/dev/null | grep -A 10 "\"$codename\"" | grep "marketing_name" | head -1 | sed 's/.*: "//;s/".*//')
  fi
  
  if [ -n "$result2" ]; then
    MODEL_NAME="$result2"
    echo "$result2"
    return 0
  fi
  
  return 1
}

# Apply model configuration
apply_model() {
  local model_name="$1"
  local modpath="$2"
  
  ui_print " "
  ui_print "✓ Setting model to: $model_name"
  
  cat > "$modpath/system.prop" <<EOF
ro.product.product.model=$model_name
ro.product.model=$model_name
EOF
  
  return 0
}

# Interactive model selection (shared by install and action)
select_model_interactive() {
  # Step 1: Get device codename
  ui_print " "
  ui_print "→ Detecting device..."
  CODENAME=$(get_device_codename)
  ui_print "  Device codename: $CODENAME"

  # Step 2: Try to get name from local offline db
  ui_print " "
  ui_print "→ Looking up local offline db..."
  LOCAL_DB_NAME=$(get_local_offline_db "$CODENAME")

  SELECTED_MODEL=""

  if [ -n "$LOCAL_DB_NAME" ]; then
    # Found in local offline db
    ui_print "  Found: $LOCAL_DB_NAME"

    if ask_user "Use this name?"; then
      SELECTED_MODEL="$LOCAL_DB_NAME"
    fi
  fi

  # Step 3: If user declined or not found, try online lookup
  if [ -z "$SELECTED_MODEL" ]; then
    ui_print " "
    ui_print "→ Trying online lookup..."

      ONLINE_NAME=$(fetch_online_name "$CODENAME")

      if [ -n "$ONLINE_NAME" ]; then
        ui_print "  Found online: $ONLINE_NAME"
      
      if ask_user "Use this online name?"; then
        SELECTED_MODEL="$ONLINE_NAME"
      fi
    else
      ui_print "  Not found online"
    fi
  fi

  # Step 4: If still no model, ask about using codename
  if [ -z "$SELECTED_MODEL" ]; then
    ui_print " "
    if ask_user "Use device codename ($CODENAME)?"; then
      SELECTED_MODEL="$CODENAME"
    fi
  fi

  # Step 5: If user declined everything, abort with instructions
  if [ -z "$SELECTED_MODEL" ]; then
    ui_print " "
    ui_print "╔════════════════════════════════════╗"
    ui_print "║  Aborted!                          "
    ui_print "╚════════════════════════════════════╝"
    ui_print " "
    ui_print "Your device codename: $CODENAME"
    ui_print " "
    ui_print "This device is not in our database."
    ui_print " "
    ui_print "To add your device:"
    ui_print "1. Edit /data/adb/modules/custom-model/device_db.txt"
    ui_print "2. Add line: $CODENAME=Your Model Name"
    ui_print "3. Reinstall module"
    ui_print " "
    ui_print "Please also investigate why codename"
    ui_print "'$CODENAME' is not in online databases:"
    ui_print "- Google Play Supported Devices"
    ui_print "- Android Trackers GitHub"
    ui_print " "
    ui_print "This may indicate a custom ROM or"
    ui_print "uncommon device variant."
    return 1
  fi

  # Set global variable instead of echo
  MODEL_NAME="$SELECTED_MODEL"
  return 0
}

# Main workflow - shared by both install and action
run_model_configuration() {
  local modpath="$1"
  
  # Print header
  ui_print "╔════════════════════════════════════╗"
  ui_print "║   Custom Model Override Module     "
  ui_print "║        by xbzk (v2.0)              "
  ui_print "╚════════════════════════════════════╝"

  # Call interactive selection
  select_model_interactive
  
  if [ $? -ne 0 ] || [ -z "$MODEL_NAME" ]; then
    return 1
  fi

  # Apply the selected model
  apply_model "$MODEL_NAME" "$modpath"

  ui_print " "
  ui_print "╔════════════════════════════════════╗"
  ui_print "║ Configuration Complete!            "
  ui_print "╚════════════════════════════════════╝"
  ui_print " "
  ui_print "Model configured: $MODEL_NAME"
  ui_print " "
  ui_print "• Reboot to apply changes"
  ui_print " "
  
  return 0
}
