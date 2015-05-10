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
* rtl/chameleon. Support files for porting designs to the Turbo Chameleon 64 hardware.
* rtl/general. Varios support and example files.
* rtl/ps2. File for PS/2 keyboard and PS/2 mice.
* rtl/video. Support files for processing video.

