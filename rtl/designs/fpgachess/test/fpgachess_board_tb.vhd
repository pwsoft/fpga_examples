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
-- Test for fpgachess_board
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.test_bench_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_board_tb is
end entity;

-- -----------------------------------------------------------------------

architecture tb of fpgachess_board_tb is
	signal clk : std_logic := '0';
	signal stop : std_logic := '0';
	signal new_game_trig : std_logic := '0';
	signal eval : signed(11 downto 0);
	type test_t is record
			name : string(1 to 16);
			search_trig : std_logic;
			search_color : std_logic;
			search_fromto : unsigned(11 downto 0);
		end record;

	signal t : test_t := (
			(others => ' '),
			'0',
			'0',
			(others => '0')
		);

	signal search_valid : std_logic;
	signal search_done : std_logic;
	signal search_next : unsigned(11 downto 0);

	procedure waitclk is
	begin
		wait until clk = '0';
		wait until clk = '1';
		-- make sure we don't stand on edge of signal
		wait for 0.1 ns;
	end procedure;

	-- Wait enough time that all processing has been completed
	procedure wait_clocks is
	begin
		waitclk;
		waitclk;
		waitclk;
	end procedure;

	procedure wait_search_valid is
		variable timeout : integer := 0;
	begin
		timeout := 0;
		while (search_valid = '0') and (timeout < 128) loop
			waitclk;
			timeout := timeout + 1;
			assert(timeout < 128) report "Search next has taken too long";
		end loop;
		if search_done = '0' then
			report "Found next move " & tohex(search_next);
		else
			report "Search done";
		end if;
	end procedure;

	procedure search_trig(signal t : inout test_t) is
	begin
		t.search_trig <= '1';
		waitclk;
		t.search_trig <= '0';
		waitclk;
	end procedure;

	procedure set_defaults(signal t : inout test_t; name : in string(1 to 16)) is
	begin
		t.name <= name;
	end procedure;

	procedure search(signal t : inout test_t; color : in std_logic) is
	begin
		if color = '0' then
			set_defaults(t, "search white    ");
		else
			set_defaults(t, "search black    ");
		end if;
		t.search_color <= color;
		t.search_fromto <= (others => '0');
		search_trig(t);
		wait_search_valid;
		while (search_valid = '1') and (search_done = '0') loop
			t.search_fromto <= search_next;
			search_trig(t);
			wait_search_valid;
		end loop;
	end procedure;
begin
	clk <= (not stop) and (not clk) after 5 ns;

	dut_inst : entity work.fpgachess_board
		port map (
			clk => clk,

			new_game_trig => new_game_trig,

			move_trig => '0',
			move_fromto => (others => '0'),
			move_captured => open,
			undo_trig => '0',
			undo_fromto => (others => '0'),
			undo_captured => piece_empty,

			search_trig => t.search_trig,
			search_color => t.search_color,
			search_fromto => t.search_fromto,
			search_valid => search_valid,
			search_done => search_done,
			search_next => search_next,

			vid_row => "000",
			vid_col => "000",
			vid_piece => open,

			vid_eval => eval
		);

	process
	begin
		waitclk;
		new_game_trig <= '1';
		waitclk;
		new_game_trig <= '0';
		waitclk;

		search(t, '0');
		search(t, '1');

		stop <= '1';
		wait;
	end process;
end architecture;
