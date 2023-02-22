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
-- Keeps track of the board state
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_board is
	port (
		clk : in std_logic;

		move_trig : in std_logic;
		move_from : in unsigned(5 downto 0);
		move_to : in unsigned(5 downto 0);

		vid_col : in unsigned(2 downto 0);
		vid_row : in unsigned(2 downto 0);
		vid_piece : out piece_t
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_board is
	signal vid_piece_reg : piece_t := (others => '0');

	type board_t is array(0 to 63) of piece_t;
	signal display_board_reg : board_t := (
			piece_white & piece_rook, piece_white & piece_knight, piece_white & piece_bishop, piece_white & piece_queen, piece_white & piece_king, piece_white & piece_bishop, piece_white & piece_knight, piece_white & piece_rook,
			piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn,
			piece_black & piece_rook, piece_black & piece_knight, piece_black & piece_bishop, piece_black & piece_queen, piece_black & piece_king, piece_black & piece_bishop, piece_black & piece_knight, piece_black & piece_rook
		);
	signal display_col0_reg : piece_t := piece_white & piece_none;
	signal display_col1_reg : piece_t := piece_white & piece_none;
	signal display_col2_reg : piece_t := piece_white & piece_none;
	signal display_col3_reg : piece_t := piece_white & piece_none;
	signal display_col4_reg : piece_t := piece_white & piece_none;
	signal display_col5_reg : piece_t := piece_white & piece_none;
	signal display_col6_reg : piece_t := piece_white & piece_none;
	signal display_col7_reg : piece_t := piece_white & piece_none;
begin
	vid_piece <= vid_piece_reg;

	process(clk)
	begin
		if rising_edge(clk) then
			if move_trig = '1' then
				display_board_reg(to_integer(move_to)) <= display_board_reg(to_integer(move_from));
				display_board_reg(to_integer(move_from)) <= piece_white & piece_none;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			display_col0_reg <= display_board_reg(to_integer(vid_row & "000"));
			display_col1_reg <= display_board_reg(to_integer(vid_row & "001"));
			display_col2_reg <= display_board_reg(to_integer(vid_row & "010"));
			display_col3_reg <= display_board_reg(to_integer(vid_row & "011"));
			display_col4_reg <= display_board_reg(to_integer(vid_row & "100"));
			display_col5_reg <= display_board_reg(to_integer(vid_row & "101"));
			display_col6_reg <= display_board_reg(to_integer(vid_row & "110"));
			display_col7_reg <= display_board_reg(to_integer(vid_row & "111"));

			case vid_col is
			when "000" => vid_piece_reg <= display_col0_reg;
			when "001" => vid_piece_reg <= display_col1_reg;
			when "010" => vid_piece_reg <= display_col2_reg;
			when "011" => vid_piece_reg <= display_col3_reg;
			when "100" => vid_piece_reg <= display_col4_reg;
			when "101" => vid_piece_reg <= display_col5_reg;
			when "110" => vid_piece_reg <= display_col6_reg;
			when "111" => vid_piece_reg <= display_col7_reg;
			end case;
		end if;
	end process;
end architecture;
