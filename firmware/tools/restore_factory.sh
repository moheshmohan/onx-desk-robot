#!/bin/zsh
# Writes a backup made by backup_factory.sh back to the display. Overwrites the whole flash.
# Not tried by the authors: the backup was verified, the restore was never run.
#   ./restore_factory.sh path/to/factory_full_16MB.bin
PORT=${PORT:-$(ls /dev/cu.usbmodem* /dev/ttyACM* 2>/dev/null | head -1)}
[[ -f "$1" ]] || { echo "usage: $0 factory_full_16MB.bin"; exit 1; }
esptool --port "$PORT" --baud 921600 write-flash 0 "$1"
