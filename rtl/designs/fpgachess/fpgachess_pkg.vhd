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
-- Global definitions shared between the various building blocks.
--
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fpgachess_pkg is
	subtype piece_t is unsigned(3 downto 0);
	constant piece_white  : std_logic := '0';
	constant piece_black  : std_logic := '1';
	constant piece_empty  : unsigned(3 downto 0) := "0000";
	constant piece_none   : unsigned(2 downto 0) := "000";
	constant piece_pawn   : unsigned(2 downto 0) := "001";
	constant piece_bishop : unsigned(2 downto 0) := "010";
	constant piece_knight : unsigned(2 downto 0) := "011";
	constant piece_rook   : unsigned(2 downto 0) := "100";
	constant piece_queen  : unsigned(2 downto 0) := "101";
	constant piece_king   : unsigned(2 downto 0) := "110";
end package;

package body fpgachess_pkg is
end package body;