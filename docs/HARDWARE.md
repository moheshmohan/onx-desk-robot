# ONX2424G013 hardware reference

What we know about the Open Nextion ONX2424G013 and where each fact comes from. Nextion's own drawings and schematic are not included in this repository; get them from Nextion.

## Pins

From Nextion's schematic and their public ESPHome configuration (<https://github.com/opennextion/OpenNextion-Example-ESPHome_KNOB_Control>). The display and input pins are confirmed by the showcase firmware running on them.

| Function | GPIO | Notes |
|---|---|---|
| LCD MOSI | 1 | The panel has one data line. It is also used to read registers back |
| LCD CS | 2 | |
| LCD DC | 3 | |
| LCD SCLK | 5 | |
| LCD backlight | 6 | Drives a transistor. High = on. PWM capable |
| LCD tearing effect | 7 | High during vertical blank. 86 Hz |
| LCD reset | 8 | |
| Knob press | 9 | Low = pressed. 10 k pull-up and 100 nF on the board |
| Encoder B | 47 | 10 k pull-up, RC filtered on the board |
| Encoder A | 48 | Same |
| Boot button | 0 | |
| USB D-, D+ | 19, 20 | USB-C socket, also on the J4 header |
| UART0 TX, RX | 43, 44 | On the 4 pin J5 socket |
| J4 header | 10, 11, 17, 18 | Four free GPIOs, plus USB D+/D-, GND and about 4.7 V |

No 3.3 V is brought out on any connector.

## Display

- GC9A01A, 240 x 240, IPS. Colour inversion on, as in the factory configuration.
- ID register (0x04) reads `00 9A 01`.
- Register reads work over the single data line. Reading pixels back (0x2E) returned zeros.
- Runs at 80 MHz SPI: tested with 256 register writes and read-backs, no errors. The factory firmware uses 40 MHz.
- At 80 MHz a full frame takes 11.3 ms to send. The panel refreshes every 11.7 ms.

## Knob

- One click is one quadrature transition, so the knob rests in all four states of the cycle.
- Which direction counts up has not been confirmed on this unit. `ENC_DIR` in the firmware flips it.
- The push switch is under the display: pressing the whole knob presses it.

## Memory

- ESP32-S3 with 8 MB octal PSRAM and 16 MB quad flash.
- Largest free block of internal RAM at start-up with the Arduino core: 271 KB. A 240 x 240 x 32-bit frame buffer (230 KB) fits if it is allocated first.
- PSRAM is several times slower for a frame buffer that is written and read every frame.

## Mechanics

From Nextion's dimension drawing, which is a **back view**.

- Fixed base Ø43.27 x 8.4 mm. Knob Ø48 x 17 mm.
- Three M1.6 threaded holes in the back. Back-view positions in mm from the centre: (-16.90, 0), (8.60, 14.72), (9.11, -14.42).
- USB-C centre at (-11.0, 0) in the same view.
- Connectors stick out about 2.6 mm behind the back plane.

A part that mates with the back must use the mirror image of these positions.

## Flashing

- The USB-C socket is the ESP32-S3's native USB serial and JTAG port. `esptool` and `arduino-cli` upload with no button presses.
- Back up the factory firmware first: `firmware/tools/backup_factory.sh`.
- Opening the serial port can reset the chip. To watch the log without a reset from Python, open the port with `dsrdtr=True, rtscts=True`.
- Firmware must not wait on the USB serial port. See the freeze in [PROJECT_LOG.md](PROJECT_LOG.md).
