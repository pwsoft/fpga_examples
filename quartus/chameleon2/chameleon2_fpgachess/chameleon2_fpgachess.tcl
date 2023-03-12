load_package flow

set project_name chameleon2_fpgachess
set project_path ${project_name}_files
set ownpath ..
set rtlpath ../../../../rtl

file mkdir $project_path
cd $project_path
project_new $project_name -revision $project_name -overwrite

cd ..
source chameleon2_fpga_settings.tcl
source chameleon2_synthesis_settings.tcl
source chameleon2_pins.tcl

set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name TOP_LEVEL_ENTITY chameleon2

# Toplevel entities
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/chameleon2_fpgachess.vhd
set_global_assignment -name SDC_FILE $rtlpath/designs/fpgachess/chameleon2_fpgachess.sdc

# PLL50
set_global_assignment -name VHDL_FILE $ownpath/pll50/pll50.vhd

# FPGACHESS specific enties
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_board.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_movelist.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_pkg.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_popcnt8.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_search.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_stats.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_top.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_ui.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/fpgachess/fpgachess_video.vhd

# Chameleon entities
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon2_e.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_1mhz.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_1khz.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_autofire.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_buttons.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_c64_joykeyb.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_cdtv_remote.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_docking_station.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_led.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_old_sdram.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_phi_clock_a.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_phi_clock_e.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon2_spi.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_usb.vhd

# Chameleon2 edition specific
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon2_io_a.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon2_io_e.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon2_io_ps2iec.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon2_io_shiftreg.vhd

# Audio output
set_global_assignment -name VHDL_FILE $rtlpath/audio/audio_sigmadelta_dac.vhd

# Generic support entities
set_global_assignment -name VHDL_FILE $rtlpath/general/fractal_noise.vhd
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_lfsr.vhd
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_pipeline.vhd
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_reset.vhd
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_usart.vhd

# IO controllers
set_global_assignment -name VHDL_FILE $rtlpath/ps2/io_ps2_com.vhd
set_global_assignment -name VHDL_FILE $rtlpath/ps2/io_ps2_keyboard.vhd
set_global_assignment -name VHDL_FILE $rtlpath/ps2/io_ps2_mouse.vhd

# Video output
set_global_assignment -name VHDL_FILE $rtlpath/video/video_pkg.vhd
set_global_assignment -name VHDL_FILE $rtlpath/video/video_dither.vhd
set_global_assignment -name VHDL_FILE $rtlpath/video/video_dither_rgb.vhd
set_global_assignment -name VHDL_FILE $rtlpath/video/video_vga_master.vhd

# Synthesize and compile project
execute_flow -compile

project_close
