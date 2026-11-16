#!/bin/zsh
# Build (and with "flash", upload) the showcase. Needs arduino-cli with the esp32 core and LovyanGFX.
#   ./build.sh            compile only
#   ./build.sh flash      compile and upload to the display on USB
cd "$(dirname "$0")"
FQBN="esp32:esp32:esp32s3:USBMode=hwcdc,CDCOnBoot=cdc,PSRAM=opi,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,CPUFreq=240,FlashMode=qio"
PORT=${PORT:-$(ls /dev/cu.usbmodem* 2>/dev/null | head -1)}
arduino-cli compile --fqbn "$FQBN" --build-path build --build-property "compiler.optimization_flags=-O2" . || exit 1
[[ "$1" == "flash" ]] && arduino-cli upload --fqbn "$FQBN" --input-dir build -p "$PORT" .
