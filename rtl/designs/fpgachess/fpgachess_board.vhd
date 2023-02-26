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

		new_game_trig : in std_logic;

		move_trig : in std_logic;
		move_fromto : in unsigned(11 downto 0);
		move_captured : out piece_t;

		vid_col : in unsigned(2 downto 0);
		vid_row : in unsigned(2 downto 0);
		vid_piece : out piece_t;

		vid_eval : out signed(11 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_board is
	constant eval_sum_bits : integer := 12;
	constant eval_part_bits : integer := 8;

	signal vid_piece_reg : piece_t := (others => '0');

	type board_t is array(0 to 63) of piece_t;
	type eval_cells_t is array(0 to 63) of signed(eval_part_bits-1 downto 0);
	type eval_sum_t is array(0 to 7) of signed(eval_sum_bits-1 downto 0);

	constant init_board : board_t :=  (
			piece_white & piece_rook, piece_white & piece_knight, piece_white & piece_bishop, piece_white & piece_queen, piece_white & piece_king, piece_white & piece_bishop, piece_white & piece_knight, piece_white & piece_rook,
			piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
			piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn,
			piece_black & piece_rook, piece_black & piece_knight, piece_black & piece_bishop, piece_black & piece_queen, piece_black & piece_king, piece_black & piece_bishop, piece_black & piece_knight, piece_black & piece_rook
		);
	signal display_board_reg : board_t := init_board;
	signal eval_board_reg : board_t := init_board;
	signal eval_cells_reg : eval_cells_t := (others => (others => '0'));
	signal eval_row_sum_reg : eval_sum_t := (others => (others => '0'));
	signal eval_sum_reg : signed(eval_sum_bits-1 downto 0) := (others => '0');

	signal move_piece_reg : piece_t := piece_empty;
	signal move_captured_reg : piece_t := piece_empty;
	signal move_phase2_reg : std_logic := '0';
	signal update_display_reg : std_logic := '0';
begin
	move_captured <= move_captured_reg;
	vid_piece <= vid_piece_reg;
	vid_eval <= eval_sum_reg;

	process(clk)
		variable row_sum : signed(eval_sum_bits-1 downto 0);
		variable sum : signed(eval_sum_bits-1 downto 0);
	begin
		if rising_edge(clk) then
			for cell in 0 to 63 loop
				case eval_board_reg(cell) is
				when piece_white & piece_pawn => eval_cells_reg(cell) <= to_signed(10, eval_part_bits);
				when piece_white & piece_bishop => eval_cells_reg(cell) <= to_signed(30, eval_part_bits);
				when piece_white & piece_knight => eval_cells_reg(cell) <= to_signed(30, eval_part_bits);
				when piece_white & piece_rook => eval_cells_reg(cell) <= to_signed(50, eval_part_bits);
				when piece_white & piece_queen => eval_cells_reg(cell) <= to_signed(70, eval_part_bits);
				when piece_white & piece_king => eval_cells_reg(cell) <= to_signed(100, eval_part_bits);
				when piece_black & piece_pawn => eval_cells_reg(cell) <= to_signed(-10, eval_part_bits);
				when piece_black & piece_bishop => eval_cells_reg(cell) <= to_signed(-30, eval_part_bits);
				when piece_black & piece_knight => eval_cells_reg(cell) <= to_signed(-30, eval_part_bits);
				when piece_black & piece_rook => eval_cells_reg(cell) <= to_signed(-50, eval_part_bits);
				when piece_black & piece_queen => eval_cells_reg(cell) <= to_signed(-70, eval_part_bits);
				when piece_black & piece_king => eval_cells_reg(cell) <= to_signed(-100, eval_part_bits);
				when others =>
					eval_cells_reg(cell) <= (others => '0');
				end case;
			end loop;

			for row in 0 to 7 loop
				row_sum := (others => '0');
				for col in 0 to 7 loop
					row_sum := row_sum + resize(eval_cells_reg(row*8+col), eval_sum_bits);
				end loop;
				eval_row_sum_reg(row) <= row_sum;
			end loop;

			sum := (others => '0');
			for row in 0 to 7 loop
				sum := sum + eval_row_sum_reg(row);
			end loop;
			eval_sum_reg <= sum;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			move_phase2_reg <= '0';
			update_display_reg <= '0';

			if new_game_trig = '1' then
				eval_board_reg <= (
					piece_white & piece_rook, piece_white & piece_knight, piece_white & piece_bishop, piece_white & piece_queen, piece_white & piece_king, piece_white & piece_bishop, piece_white & piece_knight, piece_white & piece_rook,
					piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn, piece_white & piece_pawn,
					piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
					piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
					piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
					piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none, piece_white & piece_none,
					piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn, piece_black & piece_pawn,
					piece_black & piece_rook, piece_black & piece_knight, piece_black & piece_bishop, piece_black & piece_queen, piece_black & piece_king, piece_black & piece_bishop, piece_black & piece_knight, piece_black & piece_rook
				);
				update_display_reg <= '1';
			end if;
			if move_trig = '1' then
				move_phase2_reg <= '1';
				move_piece_reg <= eval_board_reg(to_integer(move_fromto(11 downto 6)));
				move_captured_reg <= eval_board_reg(to_integer(move_fromto(5 downto 0)));
			end if;
			if move_phase2_reg = '1' then
				eval_board_reg(to_integer(move_fromto(5 downto 0))) <= move_piece_reg;
				eval_board_reg(to_integer(move_fromto(11 downto 6))) <= piece_empty;
				update_display_reg <= '1';
			end if;
		end if;
	end process;

	display_blk : block
		signal display_col0_reg : piece_t := piece_empty;
		signal display_col1_reg : piece_t := piece_empty;
		signal display_col2_reg : piece_t := piece_empty;
		signal display_col3_reg : piece_t := piece_empty;
		signal display_col4_reg : piece_t := piece_empty;
		signal display_col5_reg : piece_t := piece_empty;
		signal display_col6_reg : piece_t := piece_empty;
		signal display_col7_reg : piece_t := piece_empty;
	begin
		process(clk)
		begin
			if rising_edge(clk) then
				if update_display_reg = '1' then
					for i in 0 to 63 loop
						display_board_reg(i) <= eval_board_reg(i);
					end loop;
				end if;
			end if;
		end process;

		process(clk)
		begin
			if rising_edge(clk) then
				-- Select a single cell from the display board and send it to the video logic.
				-- Multiplexing 64 squares into one output makes the logic large.
				-- So it is done in two separate steps. First for the current row all
				-- the columns are collected. Then the selection of a specific column is made.
				-- This reduces the mux sizes from 64 to 8 making it easier to meet timing.
				--
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
	end block;
end architecture;
