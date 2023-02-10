library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fpgachess_pkg is
	subtype piece_t is unsigned(3 downto 0);
	constant piece_white  : std_logic := '0';
	constant piece_black  : std_logic := '1';
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