-- -----------------------------------------------------------------------
--
-- Syntiac's generic VHDL support files.
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2011 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/vhdl_lib.html
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
-- gen_lfsr.vhd
--
-- -----------------------------------------------------------------------
--
-- LFSR - Linear Feedback Shift Register
--
-- -----------------------------------------------------------------------
-- bits  - number of bits in shift register (valid range 3 to 168)
-- -----------------------------------------------------------------------
-- clk   - clock input
-- reset - reset shift register to zero
-- stop  - stop shifting if set
-- load  - Load shift register from d input
-- d     - input for load
-- q     - LFSR output
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity gen_lfsr is
	generic (
		bits : integer := 8
	);
	port (
		clk : in std_logic;
		reset : in std_logic := '0';
		stop : in std_logic := '0';
		load : in std_logic := '0';

		d : in unsigned(bits-1 downto 0) := (others => '0');
		q : out unsigned(bits-1 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of gen_lfsr is
	signal shift_reg : unsigned(bits-1 downto 0) := (others => '0');
	
	function feedback return std_logic is
		variable result : std_logic;
	begin
		result := '0';
		-- Magic tap points following Xilinx application note XAPP052
		-- Take note the application note counts bits from 1. Here we count from 0, so all the indexes are 1 lower.
		case bits is
		when 3 | 4 | 6 | 7 | 15 | 22 | 60 | 63 | 127 =>
			result := shift_reg(bits-1) xnor shift_reg(bits-2);
		when 5 =>
			result := shift_reg(bits-1) xnor shift_reg(2);
		when 8 =>
			result := shift_reg(bits-1) xnor shift_reg(5) xnor shift_reg(4) xnor shift_reg(3);
		when 9 =>
			result := shift_reg(bits-1) xnor shift_reg(4);
		when 10 =>
			result := shift_reg(bits-1) xnor shift_reg(6);
		when 11 =>
			result := shift_reg(bits-1) xnor shift_reg(8);
		when 12 =>
			result := shift_reg(bits-1) xnor shift_reg(5) xnor shift_reg(3) xnor shift_reg(0);
		when 13 =>
			result := shift_reg(bits-1) xnor shift_reg(3) xnor shift_reg(2) xnor shift_reg(0);
		when 14 =>
			result := shift_reg(bits-1) xnor shift_reg(4) xnor shift_reg(2) xnor shift_reg(0);
		when 16 =>
			result := shift_reg(bits-1) xnor shift_reg(14) xnor shift_reg(12) xnor shift_reg(3);
		when 17 =>
			result := shift_reg(bits-1) xnor shift_reg(13);
		when 18 =>
			result := shift_reg(bits-1) xnor shift_reg(10);
		when others =>
			assert(false);
		end case;
		return result;
	end function;
begin
	q <= shift_reg;

	process(clk) is
	begin
		if rising_edge(clk) then
			if stop = '0' then
				shift_reg <= shift_reg(bits-2 downto 0) & feedback;
			end if;
			if load = '1' then
				shift_reg <= d;
			end if;
			if reset = '1' then
				shift_reg <= (others => '0');
			end if;
		end if;
	end process;
end architecture;




