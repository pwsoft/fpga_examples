-- -----------------------------------------------------------------------
--
-- Syntiac's generic VHDL support files.
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- gen_register.vhd
--
-- -----------------------------------------------------------------------
--
-- D register
--
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity gen_register is
	generic (
		width : integer := 8
	);
	port (
		clk : in std_logic;
		rst : in std_logic := '0';
		ena : in std_logic;
		d : in unsigned(width-1 downto 0);
		q : out unsigned(width-1 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of gen_register is
	signal qReg : unsigned(d'range);
begin
	q <= qReg;

	process(clk) is
	begin
		if rising_edge(clk) then
			if ena = '1' then
				qReg <= d;
			end if;
			if rst = '1' then
				qReg <= (others => '0');
			end if;
		end if;
	end process;
end architecture;

