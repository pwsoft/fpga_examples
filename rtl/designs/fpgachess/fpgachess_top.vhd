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
-- Top level that glues the various building blocks together.
-- This is the entity to look at as first step, when porting the design to
-- a different platform.
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_top is
	port (
		clk : in std_logic;
		ena_1khz : in std_logic;
		ena_1sec : in std_logic;
		reset : in std_logic;

		cursor_up : in std_logic;
		cursor_down : in std_logic;
		cursor_left : in std_logic;
		cursor_right : in std_logic;
		cursor_enter : in std_logic;

		red : out unsigned(7 downto 0);
		grn : out unsigned(7 downto 0);
		blu : out unsigned(7 downto 0);
		hsync : out std_logic;
		vsync : out std_logic
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_top is
	constant ply_count_bits : integer := 8;

	signal new_game_trig : std_logic;
	signal white_top : std_logic;
	signal move_trig : std_logic;
	signal undo_trig : std_logic;
	signal redo_trig : std_logic;
	signal move_captured : piece_t;

	signal undo_valid : std_logic;
	signal undo_fromto : unsigned(11 downto 0);
	signal undo_captured : piece_t;
	signal redo_valid : std_logic;
	signal redo_fromto : unsigned(11 downto 0);

	signal cursor_row : unsigned(2 downto 0);
	signal cursor_col : unsigned(3 downto 0);
	signal cursor_select : std_logic;
	signal cursor_select_row : unsigned(2 downto 0);
	signal cursor_select_col : unsigned(2 downto 0);
	signal vid_line : unsigned(5 downto 0);
	signal vid_row : unsigned(2 downto 0);
	signal vid_col : unsigned(2 downto 0);
	signal vid_piece : piece_t;
	signal vid_eval : signed(11 downto 0);

	signal vid_move_show : unsigned(1 downto 0);
	signal vid_move_ply : unsigned(ply_count_bits-1 downto 0);
	signal vid_move_white : unsigned(11 downto 0);
	signal vid_move_black : unsigned(11 downto 0);
begin
	board_blk : block
		signal move_from : unsigned(5 downto 0);
		signal move_to : unsigned(5 downto 0);
	begin
		board_inst : entity work.fpgachess_board
			port map (
				clk => clk,

				new_game_trig => new_game_trig,

				move_trig => move_trig,
				move_fromto => move_from & move_to,
				move_captured => move_captured,

				undo_trig => undo_trig,
				undo_fromto => undo_fromto,
				undo_captured => undo_captured,

				search_trig => '0',
				search_color => '0',
				search_fromto => (others => '0'),

				vid_col => vid_col,
				vid_row => vid_row,
				vid_piece => vid_piece,

				vid_eval => vid_eval
			);
		move_from <= ((not cursor_select_row) & cursor_select_col) xor (white_top & white_top & white_top & white_top & white_top & white_top);
		move_to <= ((not cursor_row) & cursor_col(2 downto 0)) xor (white_top & white_top & white_top & white_top & white_top & white_top);
	end block;

	ui_inst : entity work.fpgachess_ui
		port map (
			clk => clk,
			ena_1khz => ena_1khz,
			reset => reset,

			undo_valid => undo_valid,
			redo_valid => redo_valid,

			cursor_up => cursor_up,
			cursor_down => cursor_down,
			cursor_left => cursor_left,
			cursor_right => cursor_right,
			cursor_enter => cursor_enter,

			new_game_trig => new_game_trig,
			white_top => white_top,
			move_trig => move_trig,
			undo_trig => undo_trig,
			redo_trig => redo_trig,

			cursor_row => cursor_row,
			cursor_col => cursor_col,
			cursor_select => cursor_select,
			cursor_select_row => cursor_select_row,
			cursor_select_col => cursor_select_col
		);

	movelist_blk : block
		signal move_from : unsigned(5 downto 0);
		signal move_to : unsigned(5 downto 0);
	begin
		movelist_inst : entity work.fpgachess_movelist
			generic map (
				ply_count_bits => ply_count_bits,
				scroll_threshold => 5,
				vid_line_start => 1,
				vid_line_end => 25
			)
			port map (
				clk => clk,

				new_game_trig => new_game_trig,
				move_trig => move_trig,
				undo_trig => undo_trig,
				redo_trig => redo_trig,

				move_fromto => move_from & move_to,
				move_captured => move_captured,

				undo_valid => undo_valid,
				undo_fromto => undo_fromto,
				undo_captured => undo_captured,
				redo_valid => redo_valid,
				redo_fromto => redo_fromto,

				vid_line => vid_line,
				vid_move_show => vid_move_show,
				vid_move_ply => vid_move_ply,
				vid_move_white => vid_move_white,
				vid_move_black => vid_move_black
			);
		move_from <= ((not cursor_select_row) & cursor_select_col) xor (white_top & white_top & white_top & white_top & white_top & white_top);
		move_to <= ((not cursor_row) & cursor_col(2 downto 0)) xor (white_top & white_top & white_top & white_top & white_top & white_top);
	end block;

	video_inst : entity work.fpgachess_video
		generic map (
			ply_count_bits => ply_count_bits
		)
		port map (
			clk => clk,
			ena_1sec => ena_1sec,
			reset => reset,

			white_top => white_top,
			show_undo => undo_valid,
			show_redo => redo_valid,

			cursor_row => cursor_row,
			cursor_col => cursor_col,
			cursor_select => cursor_select,
			cursor_select_row => cursor_select_row,
			cursor_select_col => cursor_select_col,

			vid_line => vid_line,
			vid_row => vid_row,
			vid_col => vid_col,
			piece => vid_piece,

			vid_eval => vid_eval,

			move_show => vid_move_show,
			move_ply => vid_move_ply,
			move_white => vid_move_white,
			move_black => vid_move_black,

			red => red,
			grn => grn,
			blu => blu,
			hsync => hsync,
			vsync => vsync
		);
end architecture;
