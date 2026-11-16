#!/bin/zsh
# Reads the display's whole 16 MB flash into factory_full_16MB.bin before you flash anything else.
# Reads 1 MB at a time and retries, because a long single read over USB can drop.
#   ./backup_factory.sh [output_dir]
OUT=${1:-.}
PORT=${PORT:-$(ls /dev/cu.usbmodem* /dev/ttyACM* 2>/dev/null | head -1)}
mkdir -p "$OUT" && cd "$OUT" || exit 1
for i in {0..15}; do
  f=$(printf "chunk_%02d.bin" $i)
  off=$(printf "0x%X" $((i * 0x100000)))
  n=0
  while [[ ! -s $f || $(wc -c < $f) -ne 1048576 ]]; do
    n=$((n + 1)); [[ $n -gt 6 ]] && { echo "FAILED at chunk $i"; exit 1; }
    : > $f
    esptool --port "$PORT" --baud 921600 --after no-reset read-flash $off 0x100000 $f > /dev/null 2>&1 || { echo "retry chunk $i"; sleep 2; }
  done
  echo "chunk $i ok"
done
cat chunk_??.bin > factory_full_16MB.bin
for i in {0..15}; do : > $(printf "chunk_%02d.bin" $i); done
shasum -a 256 factory_full_16MB.bin
echo "Done. The empty chunk_*.bin files can be deleted."
