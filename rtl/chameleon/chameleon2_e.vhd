-- -----------------------------------------------------------------------
--
-- Turbo Chameleon 64
--
-- Multi purpose FPGA expansion for the Commodore 64 computer
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2018 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--
-- -----------------------------------------------------------------------
--
-- Default toplevel entity for the Turbo Chameleon 64 second edition
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity chameleon2 is
	port (
-- Clocks
		signal clk8m : in std_logic;
		signal phi2_in : in std_logic;
		signal dotclk_in : in std_logic;

-- Buttons
		signal usart_cts : in std_logic;
		signal reset_btn : in std_logic;
		signal freeze_btn : in std_logic;

-- PS/2, IEC, LEDs
		signal iec_present : in std_logic;

		signal ps2iec_sel : out std_logic;
		signal ps2iec : in unsigned(3 downto 0);

		signal ser_out_clk : out std_logic;
		signal ser_out_dat : out std_logic;
		signal ser_out_rclk : out std_logic;

		signal iec_clk_out : out std_logic;
		signal iec_srq_out : out std_logic;
		signal iec_atn_out : out std_logic;
		signal iec_dat_out : out std_logic;

-- SPI, Flash and SD-Card
		signal flash_sel : out std_logic;
		signal mmc_cs : out std_logic;
		signal rtc_cs : out std_logic;

		signal sd_cd : in std_logic;
		signal sd_wp : in std_logic;
		signal sd_clk : out std_logic;
		signal sd_miso : in std_logic;
		signal sd_mosi : out std_logic;

-- Clock port
		signal clock_ior : out std_logic;
		signal clock_iow : out std_logic;

-- C64 bus
		signal reset_in : in std_logic;

		signal ioef : in std_logic;
		signal romlh : in std_logic;

		signal dma_out : out std_logic;
		signal game_out : out std_logic;
		signal exrom_out : out std_logic;

		signal irq_in : in std_logic;
		signal irq_out : out std_logic;
		signal nmi_in : in std_logic;
		signal nmi_out : out std_logic;
		signal ba_in : in std_logic;
		signal rw_in : in std_logic;
		signal rw_out : out std_logic;

		signal sa_dir : out std_logic;
		signal sa_oe : out std_logic;
		signal sa15_out : out std_logic;
		signal low_a : inout unsigned(15 downto 0);

		signal sd_dir : out std_logic;
		signal sd_oe : out std_logic;
		signal low_d : inout unsigned(7 downto 0);

-- SDRAM
		signal ram_clk : out std_logic;
		signal ram_ldqm : out std_logic;
		signal ram_udqm : out std_logic;
		signal ram_ras : out std_logic;
		signal ram_cas : out std_logic;
		signal ram_we : out std_logic;
		signal ram_ba : out unsigned(1 downto 0);
		signal ram_a : out unsigned(12 downto 0);
		signal ram_d : inout unsigned(15 downto 0);

-- IR eye
		signal ir_data : in std_logic;

-- USB micro
		signal usart_clk : in std_logic;
		signal usart_rts : in std_logic;
		signal usart_rx : out std_logic;
		signal usart_tx : in std_logic;

-- Audio output
		signal sigma_a : out std_logic;
		signal sigma_b : out std_logic;

-- VGA output
		signal red : out unsigned(4 downto 0);
		signal green : out unsigned(4 downto 0);
		signal blue : out unsigned(4 downto 0);
		signal hsync : out std_logic;
		signal vsync : out std_logic
	);
end entity;
