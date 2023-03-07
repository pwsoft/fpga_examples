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
	constant top_move_bits : integer := 8;
	constant eval_score_bits : integer := 12;

	signal new_game_trig : std_logic;
	signal search_start_trig : std_logic;
	signal white_top : std_logic;
	signal move_trig : std_logic;
	signal undo_trig : std_logic;
	signal redo_trig : std_logic;

	signal movelist_trig : std_logic;
	signal movelist_fromto : unsigned(11 downto 0);
	signal movelist_captured : piece_t;

	signal undo_valid : std_logic;
	signal undo_fromto : unsigned(11 downto 0);
	signal undo_captured : piece_t;
	signal redo_valid : std_logic;
	signal redo_fromto : unsigned(11 downto 0);

	signal searching : std_logic;
	signal search_req : std_logic;
	signal search_ack : std_logic;
	signal search_color : std_logic;
	signal search_fromto : unsigned(11 downto 0);
	signal found_done : std_logic;
	signal found_fromto : unsigned(11 downto 0);

	signal search_move_trig : std_logic;
	signal search_move_fromto : unsigned(11 downto 0);

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
		signal trig_loc : std_logic;
		signal move_from : unsigned(5 downto 0);
		signal move_to : unsigned(5 downto 0);
	begin
		board_inst : entity work.fpgachess_board
			port map (
				clk => clk,

				new_game_trig => new_game_trig,

				move_trig => trig_loc,
				move_fromto => move_from & move_to,

				undo_trig => undo_trig,
				undo_fromto => undo_fromto,
				undo_captured => undo_captured,

				search_req => search_req,
				search_ack => search_ack,
				search_color => search_color,
				search_fromto => search_fromto,
				found_done => found_done,
				found_fromto => found_fromto,

				movelist_trig => movelist_trig,
				movelist_fromto => movelist_fromto,
				movelist_captured => movelist_captured,

				vid_col => vid_col,
				vid_row => vid_row,
				vid_piece => vid_piece,

				vid_eval => vid_eval
			);
		trig_loc <= move_trig or search_move_trig;
		move_from <=
			search_move_fromto(11 downto 6) when search_move_trig = '1' else
			((not cursor_select_row) & cursor_select_col) xor (white_top & white_top & white_top & white_top & white_top & white_top);
		move_to <=
			search_move_fromto(5 downto 0) when search_move_trig = '1' else
			((not cursor_row) & cursor_col(2 downto 0)) xor (white_top & white_top & white_top & white_top & white_top & white_top);
	end block;

	search_inst : entity work.fpgachess_search
		generic map (
			ply_count_bits => ply_count_bits,
			top_move_bits => top_move_bits,
			eval_score_bits => eval_score_bits
		)
		port map (
			clk => clk,
			reset => reset,

			search_start_color => '1',
			search_start_trig => search_start_trig,
			search_abort_trig => '0',

			searching => searching,
			search_req => search_req,
			search_ack => search_ack,
			search_color => search_color,
			search_fromto => search_fromto,
			found_done => found_done,
			found_fromto => found_fromto,

			move_trig => search_move_trig,
			move_fromto => search_move_fromto
		);

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
			search_start_trig => search_start_trig,
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
			search_mode => searching,

			move_trig => movelist_trig,
			undo_trig => undo_trig,
			redo_trig => redo_trig,

			move_fromto => movelist_fromto,
			move_captured => movelist_captured,

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
