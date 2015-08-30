fpga_examples
=============

Example code in vhdl to help starting new projects using FPGA devices.

What is here
============

Quartus II projects files for the Turbo Chameleon 64 hardware. These are located in the quartus/chameleon folder.
* chameleon_example_io. An example demonstrating how to access I/O ports on the Chameleon hardware.
* chameleon_life. Conways game of life implementation for Chameleon. It requires a PS/2 mouse.
* chameleon_v5_hwtest. Chameleon hardware selftest for hardware production and diagnostics.

Various vhdl files to be reused in other designs.
* rtl/audio. Support files for processing audio.
    * audio_sigmadelta_dac.vhd  Audio sigmadelta first order 1 bit converter.
* rtl/chameleon. Support files for porting designs to the Turbo Chameleon 64 hardware.
    * chameleon_1khz.vhd  An 1 khz trigger generator (requires 1 mhz trigger input).
    * chameleon_1mhz.vhd  An 1 Mhz trigger generator.
    * chameleon_autofire.vhd  Joystick autofire circuit.
    * chameleon_buttons.vhd  Logic to debounce the three blue buttons on the Chameleon. Detects short and long presses.
    * chameleon_c64_joykeyb.vhd  Logic to readout the C64 keyboard and joystick ports (used by chameleon_io).
    * chameleon_cdtv_remote.vhd  Decoder for the IR signals transmitted by the CDTV remote.
    * chameleon_docking_station.vhd  Decoder for the bitstream generated by the Chameleon docking-station.
    * chameleon_io.vhd  Chameleon timing and I/O driver. Handles all the timing and multiplexing details of the cartridge port and the CPLD mux.
    * chameleon_led.vhd  LED blinking circuit.
    * chameleon_old_sdram.vhd  Example SDRAM controller (has multiple ports of different widths)
    * chameleon_phi_clock_*.vhd  C64 Phi2-clock regeneration and divider. (used by chameleon_io to sync. to PHI2 signal)
    * chameleon_spi_flash.vhd  Read data from on of the slots in the 16 Mbyte SPI serial flash.
    * chameleon_usb.vhd  Logic to allow reading and writing memory through the usb port with chaco. Also supplies the current flash slot.
* rtl/general. Varios support and example files.
    * gen_bin2gray.vhd  Binary to gray converter.
    * gen_button.vhd  Button debouncer
    * gen_counter.vhd  Up/Down counter example.
    * gen_counter_signed.vhd  Up/Down counter that outputs signed value.
    * gen_dualram.vhd
    * gen_lfsr.vhd  Linear Feedback Shift Register. Generates pseudo random numbers.
    * gen_pipeline.vhd  Configurable pipeline building block.
    * gen_register.vhd  Register example.
    * gen_reset.vhd  Power-on reset circuit with manual reset button input.
    * gen_usart.vhd  Synchronous serial receiver/transmitter
* rtl/ps2. Design files to add support for PS/2 keyboards and PS/2 mice.
    * io_ps2_com.vhd  Lowlevel PS/2 driver. Allowes receiving and sending bytes to PS/2 devices.
    * io_ps2_keyboard.vhd  PS/2 keyboard interface (uses io_ps2_com). Receives scancodes and can control the LEDs.
    * io_ps2_mouse.vhd   PS/2 mouse interface (uses io_ps2_com). Gets position and button information from PS/2 mice.
* rtl/video. Support files for processing video.
    * video_vga_master.vhd  VGA sync. and timing generator.
