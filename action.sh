#!/system/bin/sh
# Custom Model Override - Action Script
# Uses same workflow as installation

MODDIR=${0%/*}
LOG="$MODDIR/action.log"
BUILD_TAG="CSVDBG-$(date +%Y-%m-%d-%H%M%S)"

# Redirect ui_print for action button context
ui_print() {
  echo "$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

ui_print "[Action] Build tag: $BUILD_TAG"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Action button pressed ===" >> "$LOG"

# Set environment for action context
export TMPDIR=/data/local/tmp
mkdir -p "$TMPDIR" 2>/dev/null

# Load common functions
. $MODDIR/common_functions.sh

# Run shared model configuration workflow
run_model_configuration "$MODDIR"

if [ $? -ne 0 ]; then
  ui_print " "
  ui_print "Action cancelled."
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Action cancelled" >> "$LOG"
  exit 1
fi

# Auto reboot
sleep 2
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rebooting device" >> "$LOG"
/system/bin/svc power reboot || /system/bin/reboot

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Action script finished ===" >> "$LOG"
