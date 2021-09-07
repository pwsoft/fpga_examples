load_package flow

set project_name chameleon1_gigatron
set project_path ${project_name}_files
set ownpath ..
set rtlpath ../../../../rtl

file mkdir $project_path
cd $project_path
project_new $project_name -revision $project_name -overwrite

source ../chameleon1_fpga_settings.tcl
source ../chameleon1_synthesis_settings.tcl
source ../chameleon1_pins.tcl

set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name TOP_LEVEL_ENTITY chameleon1

# Toplevel entities
set_global_assignment -name VHDL_FILE $ownpath/chameleon1_gigatron.vhd
set_global_assignment -name SDC_FILE $ownpath/chameleon1_gigatron.sdc

# PLL8
set_global_assignment -name VHDL_FILE $ownpath/pll8.vhd

# Gigatron entities
set_global_assignment -name VHDL_FILE $rtlpath/designs/gigatron/gigatron_logic.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/gigatron/gigatron_ram.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/gigatron/gigatron_sdram_ctrl.vhd
set_global_assignment -name VHDL_FILE $rtlpath/designs/gigatron/gigatron_top.vhd

# Chameleon entities
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
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_spi_flash.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_usb.vhd

# Chameleon1 edition specific
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon1_e.vhd
set_global_assignment -name VHDL_FILE $rtlpath/chameleon/chameleon_io.vhd

# Audio output
set_global_assignment -name VHDL_FILE $rtlpath/audio/audio_sigmadelta_dac.vhd

# Generic support entities
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_pipeline.vhd
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_reset.vhd
set_global_assignment -name VHDL_FILE $rtlpath/general/gen_usart.vhd

# IO controllers
set_global_assignment -name VHDL_FILE $rtlpath/ps2/io_ps2_com.vhd
set_global_assignment -name VHDL_FILE $rtlpath/ps2/io_ps2_keyboard.vhd
set_global_assignment -name VHDL_FILE $rtlpath/ps2/io_ps2_mouse.vhd

# Video output
set_global_assignment -name VHDL_FILE $rtlpath/video/video_pkg.vhd
set_global_assignment -name VHDL_FILE $rtlpath/video/video_vga_master.vhd

# Synthesize and compile project
execute_flow -compile

project_close
