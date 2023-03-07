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
-- Search algorithm for finding the best move.
--
-- -----------------------------------------------------------------------
--
-- ply_count_bits  - Capacity in the movelist, absolute limit of search depth
--                   In practise likely never reached
-- top_move_bits   - Capacity for storing every first move during search.
--                   By storing all the first moves with evaluation results,
--                   the deepening algorithm can focus of best moves first.
-- eval_score_bits - Number of bits that build up the board evaluation score
--
-- clk             - System clock input
-- reset           - System reset input
--
--
-- searching       - High when the search algorithm is active
-- search_trig     - Start a move search on the board
-- search_color    - Color to use when searching a move on the board
-- search_fromto   - Starting point when searching a move on the board
-- found_valid     - High when board search is complete and results are valid
-- found_done      - High when no new move has been found on the board
-- found_fromto    - Coordinate and target of the found move on the board
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_search is
	generic (
		ply_count_bits : integer;
		top_move_bits : integer;
		eval_score_bits : integer
	);
	port (
		clk : in std_logic;
		reset : in std_logic;

		search_start_color : in std_logic;
		search_start_trig : in std_logic;
		search_abort_trig : in std_logic;

		searching : out std_logic;
		search_trig : out std_logic;
		search_color : out std_logic;
		search_fromto : out unsigned(11 downto 0);
		found_valid : in std_logic;
		found_done : in std_logic;
		found_fromto : in unsigned(11 downto 0);

		move_trig : out std_logic;
		move_fromto : out unsigned(11 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_search is
	type state_t is (IDLE, SEARCH);

	signal searching_reg : std_logic := '0';
	signal search_trig_reg : std_logic := '0';
	signal search_color_reg : std_logic := '0';
	signal search_fromto_reg : unsigned(search_fromto'range) := (others => '0');

	signal move_trig_reg : std_logic := '0';
	signal move_fromto_reg : unsigned(move_fromto'range) := (others => '0');
begin
	searching <= searching_reg;
	search_trig <= search_trig_reg;
	search_color <= search_color_reg;
	search_fromto <= search_fromto_reg;

	move_trig <= move_trig_reg;
	move_fromto <= move_fromto_reg;

	process(clk)
	begin
		if rising_edge(clk) then
			search_trig_reg <= '0';
			move_trig_reg <= '0';
			if search_start_trig = '1' then
				searching_reg <= '1';
				search_color_reg <= search_start_color;
				search_trig_reg <= '1';
				search_fromto_reg <= (others => '0');
			end if;
			if (searching_reg = '1') and (found_valid = '1') then
				searching_reg <= '0';
				if (found_done = '0') then
					move_trig_reg <= '1';
					move_fromto_reg <= found_fromto;
				end if;
			end if;
		end if;
	end process;
end architecture;
