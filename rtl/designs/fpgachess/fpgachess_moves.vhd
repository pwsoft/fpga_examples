-- -----------------------------------------------------------------------
--
-- FPGA-Chess
--
-- Chess game engine for programmable logic devices
--
-- -----------------------------------------------------------------------
-- Copyright 2022-2023 by Peter Wendrich (pwsoft@syntiac.com)
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
-- Part of FPGA-Chess
-- Keeps track of move history. Both for display of previous moves, but also
-- for undo/redo and replay of moves.
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_moves is
	generic (
		ply_count_bits : integer;
		scroll_threshold : integer;
		vid_line_start : integer;
		vid_line_end : integer
	);
	port (
		clk : in std_logic;

		new_game_trig : in std_logic;
		move_trig : in std_logic;
		move_fromto : in unsigned(11 downto 0);
		move_captured : in piece_t;

		vid_line : in unsigned(5 downto 0);
		vid_move_show : out unsigned(1 downto 0);
		vid_move_ply : out unsigned(ply_count_bits-1 downto 0);
		vid_move_white : out unsigned(11 downto 0);
		vid_move_black : out unsigned(11 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_moves is
	type moves_t is array(0 to (2**ply_count_bits)-1) of unsigned(11 downto 0);
	signal moves_reg : moves_t := (others => (others => '0'));
	signal readout_reg : unsigned(11 downto 0) := (others => '0');

	-- max_count_reg is one bit greater as ply result so ply<max compare also does work for last item in the storage
	signal max_count_reg : unsigned(ply_count_bits downto 0) := (others => '0');

	signal vid_move_show_reg : unsigned(vid_move_show'range) := (others => '0');
	signal vid_move_ply_reg : unsigned(vid_move_ply'range) := (others => '0');
	signal vid_move_white_reg : unsigned(vid_move_white'range) := (others => '0');
	signal vid_move_black_reg : unsigned(vid_move_black'range) := (others => '0');
begin
	vid_move_show <= vid_move_show_reg;
	vid_move_ply <= vid_move_ply_reg;
	vid_move_white <= vid_move_white_reg;
	vid_move_black <= vid_move_black_reg;

	memory_blk : block
		signal we_reg : std_logic := '0';
		signal addr_reg : unsigned(ply_count_bits-1 downto 0) := (others => '0');

		signal vid_ready_reg : unsigned(1 downto 0) := (others => '0');
		signal vid_color_reg : unsigned(1 downto 0) := (others => '0');
	begin
		process(clk)
		begin
			if rising_edge(clk) then
				if we_reg = '1' then
					moves_reg(to_integer(addr_reg)) <= move_fromto;
				else
					readout_reg <= moves_reg(to_integer(addr_reg));
				end if;
			end if;
		end process;


		process(clk)
		begin
			if rising_edge(clk) then
				we_reg <= '0';
				vid_ready_reg <= vid_ready_reg(0) & '0';
				vid_color_reg(1) <= vid_color_reg(0);

				if move_trig = '1' then
					we_reg <= '1';
					addr_reg <= max_count_reg(addr_reg'range);
				else
					vid_color_reg(0) <= not vid_color_reg(0);
					addr_reg <= vid_move_ply_reg;
					addr_reg(0) <= not vid_color_reg(0);
					vid_ready_reg(0) <= '1';
				end if;

				-- A history read for video output is complete (takes 2 cycles)
				if vid_ready_reg(1) = '1' then
					if vid_color_reg(1) = '0' then
						vid_move_white_reg <= readout_reg;
					else
						vid_move_black_reg <= readout_reg;
					end if;
				end if;
			end if;
		end process;
	end block;

	process(clk)
	begin
		if rising_edge(clk) then
			if new_game_trig = '1' then
				max_count_reg <= (others => '0');
			end if;
			if move_trig = '1' then
				max_count_reg <= max_count_reg + 1;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			vid_move_show_reg <= (others => '0');

			if (vid_line >= vid_line_start) and (vid_line < vid_line_end) then
				vid_move_ply_reg(vid_move_ply_reg'high downto 1) <= resize(vid_line, ply_count_bits-1) - vid_line_start;
				vid_move_ply_reg(0) <= '0';
			end if;
			if vid_move_ply_reg < max_count_reg then
				-- At least white made a turn in this move
				vid_move_show_reg(0) <= '1';
				if vid_move_ply_reg < max_count_reg-1 then
					-- Black also made turn this move, so enable both bits
					vid_move_show_reg(1) <= '1';
				end if;
			end if;
		end if;
	end process;
end architecture;
