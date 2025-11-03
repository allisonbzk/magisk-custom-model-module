#!/system/bin/sh
# Service script - runs on boot

MODDIR=${0%/*}

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# Log module status
echo "[$(date)] Custom Model Override module loaded" >> "$MODDIR/service.log"
echo "[$(date)] Current model: $(getprop ro.product.model)" >> "$MODDIR/service.log"
