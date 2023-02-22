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
-- This is the entity to look at when porting the design to a different
-- platform.
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
	signal white_top : std_logic;
	signal move_trig : std_logic;
	signal cursor_row : unsigned(2 downto 0);
	signal cursor_col : unsigned(3 downto 0);
	signal cursor_select : std_logic;
	signal cursor_select_row : unsigned(2 downto 0);
	signal cursor_select_col : unsigned(2 downto 0);
	signal vid_row : unsigned(2 downto 0);
	signal vid_col : unsigned(2 downto 0);
	signal vid_piece : piece_t;
begin
	board_blk : block
		signal move_from : unsigned(5 downto 0);
		signal move_to : unsigned(5 downto 0);
	begin
		board_inst : entity work.fpgachess_board
			port map (
				clk => clk,

				move_trig => move_trig,
				move_from => move_from,
				move_to => move_to,

				vid_col => vid_col,
				vid_row => vid_row,
				vid_piece => vid_piece
			);
		move_from <= ((not cursor_select_row) & cursor_select_col) xor (white_top & white_top & white_top & white_top & white_top & white_top);
		move_to <= ((not cursor_row) & cursor_col(2 downto 0)) xor (white_top & white_top & white_top & white_top & white_top & white_top);
	end block;

	ui_inst : entity work.fpgachess_ui
		port map (
			clk => clk,
			ena_1khz => ena_1khz,

			cursor_up => cursor_up,
			cursor_down => cursor_down,
			cursor_left => cursor_left,
			cursor_right => cursor_right,
			cursor_enter => cursor_enter,

			white_top => white_top,
			move_trig => move_trig,
			cursor_row => cursor_row,
			cursor_col => cursor_col,
			cursor_select => cursor_select,
			cursor_select_row => cursor_select_row,
			cursor_select_col => cursor_select_col
		);

	video_inst : entity work.fpgachess_video
		port map (
			clk => clk,
			ena_1sec => ena_1sec,

			white_top => white_top,

			cursor_row => cursor_row,
			cursor_col => cursor_col,
			cursor_select => cursor_select,
			cursor_select_row => cursor_select_row,
			cursor_select_col => cursor_select_col,

			row => vid_row,
			col => vid_col,
			piece => vid_piece,

			red => red,
			grn => grn,
			blu => blu,
			hsync => hsync,
			vsync => vsync
		);
end architecture;
