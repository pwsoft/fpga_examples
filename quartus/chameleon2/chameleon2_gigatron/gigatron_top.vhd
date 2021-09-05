-- -----------------------------------------------------------------------
--
-- Turbo Chameleon
--
-- Multi purpose FPGA expansion for the Commodore 64 computer
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2021 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/chameleon.html
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
-- Part of the Gigatron emulator.
-- Gigatron emulator main logic file.
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- -----------------------------------------------------------------------

entity gigatron_top is
	generic (
		clk_ticks_per_usec : integer;
		romload_size : integer := 131072
	);
	port (
		clk : in std_logic;
		reset : in std_logic;

		flashslot : in unsigned(4 downto 0);
		joystick : in unsigned(6 downto 0);

	-- SPI interface
		spi_cs_n : out std_logic;
		spi_req : out std_logic;
		spi_ack : in std_logic;
		spi_d : out unsigned(7 downto 0);
		spi_q : in unsigned(7 downto 0);

	-- SDRAM interface
		ram_data : inout unsigned(15 downto 0);
		ram_addr : out unsigned(12 downto 0);
		ram_ba : out unsigned(1 downto 0);
		ram_we : out std_logic;
		ram_ras : out std_logic;
		ram_cas : out std_logic;
		ram_ldqm : out std_logic;
		ram_udqm : out std_logic;

	-- Video
		red : out unsigned(4 downto 0);
		grn : out unsigned(4 downto 0);
		blu : out unsigned(4 downto 0);
		hsync : out std_logic;
		vsync : out std_logic
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of gigatron_top is
	signal romload_start : std_logic;
	signal romload_busy : std_logic;

	signal romload_req : std_logic;
	signal romload_ack : std_logic;
	signal romload_a : unsigned(24 downto 0);
	signal romload_q : unsigned(7 downto 0);

	signal rom_req : std_logic;
	signal rom_ack : std_logic;
	signal rom_a : unsigned(15 downto 0);
	signal rom_q : unsigned(15 downto 0);

	signal sram_we : std_logic;
	signal sram_a : unsigned(15 downto 0); -- Only lower 32kb connected
	signal sram_d : unsigned(7 downto 0);
	signal sram_q : unsigned(7 downto 0);

	signal inport : unsigned(7 downto 0);
	signal outport : unsigned(7 downto 0);

	signal tick : std_logic;
begin
-- -----------------------------------------------------------------------
-- ROM loader from spi-flash into sdram
-- -----------------------------------------------------------------------
	romload_blk : block
	begin
		romload_inst : entity work.chameleon_spi_flash
			generic map (
				a_bits => 25
			)
			port map (
				clk => clk,
				slot => flashslot(3 downto 0),
				start => romload_start,

				start_addr => (others => '0'),
				flash_offset => (others => '0'),
				amount => to_unsigned(romload_size, 24),

				busy => romload_busy,

				cs_n => spi_cs_n,
				spi_req => spi_req,
				spi_ack => spi_ack,
				spi_d => spi_d,
				spi_q => spi_q,

				req => romload_req,
				ack => romload_ack,
				a => romload_a,
				q => romload_q
			);
	end block;

-- -----------------------------------------------------------------------
-- SDRAM controller (emulating 16-bit ROM)
-- -----------------------------------------------------------------------
	sdram_ctrl_inst : entity work.gigatron_sdram_ctrl
		generic map (
			clk_ticks_per_usec => clk_ticks_per_usec
		)
		port map (
			clk => clk,
			reset => reset,

		-- Parameters
			cas_latency => "10",
			ras_nops => "0001",
			write_nops => "0000",
			precharge_nops => "0001",
			refresh_nops => "0110",

		-- Initial ROM image load from spi-flash
			romload_req => romload_req,
			romload_ack => romload_ack,
			romload_a => romload_a,
			romload_d => romload_q,

		-- Reading of 16-bit ROM data from emulation
			rom_req => rom_req,
			rom_ack => rom_ack,
			rom_a => rom_a,
			rom_q => rom_q,

		-- SDRAM interface
			ram_data => ram_data,
			ram_addr => ram_addr,
			ram_ba => ram_ba,
			ram_we => ram_we,
			ram_ras => ram_ras,
			ram_cas => ram_cas,
			ram_ldqm => ram_ldqm,
			ram_udqm => ram_udqm
		);

-- -----------------------------------------------------------------------
-- 32k internal SRAM mapped to FPGA blockram
-- -----------------------------------------------------------------------
	sram_inst : entity work.gigatron_ram
		port map (
			clk => clk,

			we => sram_we,
			a => sram_a(14 downto 0),
			d => sram_d,
			q => sram_q
		);

-- -----------------------------------------------------------------------
-- Logic emulation
-- -----------------------------------------------------------------------
	logic_blk : block
	begin
		logic_inst : entity work.gigatron_logic
			port map (
				clk => clk,
				reset => reset,
				tick => tick,

				rom_req => rom_req,
				rom_a => rom_a,
				rom_q => rom_q,

				sram_we => sram_we,
				sram_a => sram_a,
				sram_d => sram_d,
				sram_q => sram_q,

				inport => inport,
				outport => outport
			);
	end block;

-- -----------------------------------------------------------------------
-- Joystick mapping
-- -----------------------------------------------------------------------
	inport <= joystick(4) & joystick(5) & "11" & joystick(0) & joystick(1) & joystick(2) & joystick(3);

-- -----------------------------------------------------------------------
-- Video/Color encoding
-- -----------------------------------------------------------------------
	red <= outport(1 downto 0) & outport(1 downto 0) & outport(1);
	grn <= outport(3 downto 2) & outport(3 downto 2) & outport(3);
	blu <= outport(5 downto 4) & outport(5 downto 4) & outport(5);
	hsync <= outport(6);
	vsync <= outport(7);

-- -----------------------------------------------------------------------
-- Main statemachine
-- -----------------------------------------------------------------------
	main_blk : block
		type state_t is (
			ST_RESET, ST_WAITSLOT, ST_LOADROM, ST_RUN);
		signal state_reg : state_t := ST_RESET;
		signal romload_start_reg : std_logic := '0';
		signal tick_div_reg : unsigned(4 downto 0) := (others => '0');
		signal tick_reg : std_logic := '0';
	begin
		romload_start <= romload_start_reg;
		tick <= tick_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				romload_start_reg <= '0';
				tick_reg <= '0';

				case state_reg is
				when ST_RESET =>
					state_reg <= ST_WAITSLOT;
				when ST_WAITSLOT =>
					if flashslot(4) = '1' then
						romload_start_reg <= '1';
						state_reg <= ST_LOADROM;
					end if;
				when ST_LOADROM =>
					if (romload_start_reg = '0') and (romload_busy = '0') then
						state_reg <= ST_RUN;
					end if;
				when ST_RUN =>
					if tick_div_reg = 15 then
						if rom_req = rom_ack then
							tick_div_reg <= (others => '0');
							tick_reg <= '1';
						end if;
					else
						tick_div_reg <= tick_div_reg + 1;
					end if;
				end case;
				if reset = '1' then
					state_reg <= ST_RESET;
				end if;
			end if;
		end process;
	end block;
end architecture;
