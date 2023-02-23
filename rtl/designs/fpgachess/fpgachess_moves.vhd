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
		store_move_trig : in std_logic;
		move_from : in unsigned(5 downto 0);
		move_to : in unsigned(5 downto 0);

		vid_line : in unsigned(5 downto 0);
		vid_move_show : out unsigned(1 downto 0);
		vid_move_ply : out unsigned(ply_count_bits-1 downto 0);
		vid_move_from : out unsigned(5 downto 0);
		vid_move_to : out unsigned(5 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_moves is
	type moves_t is array(0 to (2**ply_count_bits)-1) of unsigned(5 downto 0);
	signal moves_reg : moves_t := (others => (others => '0'));
	-- max_count_reg is one bit greater as ply result so ply<max compare also does work for last item in the storage
	signal max_count_reg : unsigned(ply_count_bits downto 0) := (others => '0');

	signal vid_move_show_reg : unsigned(vid_move_show'range) := (others => '0');
	signal vid_move_ply_reg : unsigned(vid_move_ply'range) := (others => '0');
	signal vid_move_from_reg : unsigned(vid_move_from'range) := (others => '0');
	signal vid_move_to_reg : unsigned(vid_move_to'range) := (others => '0');
begin
	vid_move_show <= vid_move_show_reg;
	vid_move_ply <= vid_move_ply_reg;
	vid_move_from <= vid_move_from_reg;
	vid_move_to <= vid_move_to_reg;

	process(clk)
	begin
		if rising_edge(clk) then
			if new_game_trig = '1' then
				max_count_reg <= (others => '0');
			end if;
			if store_move_trig = '1' then
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
				if vid_move_ply_reg+1 < max_count_reg then
					-- Black also made turn this move, so enable both bits
					vid_move_show_reg(1) <= '1';
				end if;
			end if;
		end if;
	end process;
end architecture;
