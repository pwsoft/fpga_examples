library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_board is
	port (
		clk : in std_logic;

		vid_col : in unsigned(2 downto 0);
		vid_row : in unsigned(2 downto 0);
		vid_piece : out piece_t
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_board is
	signal vid_piece_reg : piece_t := (others => '0');
begin
	vid_piece <= vid_piece_reg;

	process(clk)
	begin
		if rising_edge(clk) then
			case vid_row & vid_col is
			when "000000" => vid_piece_reg <= piece_white & piece_rook;
			when "000001" => vid_piece_reg <= piece_white & piece_knight;
			when "000010" => vid_piece_reg <= piece_white & piece_bishop;
			when "000011" => vid_piece_reg <= piece_white & piece_queen;
			when "000100" => vid_piece_reg <= piece_white & piece_king;
			when "000101" => vid_piece_reg <= piece_white & piece_bishop;
			when "000110" => vid_piece_reg <= piece_white & piece_knight;
			when "000111" => vid_piece_reg <= piece_white & piece_rook;
			when "001000" => vid_piece_reg <= piece_white & piece_pawn;
			when "001001" => vid_piece_reg <= piece_white & piece_pawn;
			when "001010" => vid_piece_reg <= piece_white & piece_pawn;
			when "001011" => vid_piece_reg <= piece_white & piece_pawn;
			when "001100" => vid_piece_reg <= piece_white & piece_pawn;
			when "001101" => vid_piece_reg <= piece_white & piece_pawn;
			when "001110" => vid_piece_reg <= piece_white & piece_pawn;
			when "001111" => vid_piece_reg <= piece_white & piece_pawn;

			when "110000" => vid_piece_reg <= piece_black & piece_pawn;
			when "110001" => vid_piece_reg <= piece_black & piece_pawn;
			when "110010" => vid_piece_reg <= piece_black & piece_pawn;
			when "110011" => vid_piece_reg <= piece_black & piece_pawn;
			when "110100" => vid_piece_reg <= piece_black & piece_pawn;
			when "110101" => vid_piece_reg <= piece_black & piece_pawn;
			when "110110" => vid_piece_reg <= piece_black & piece_pawn;
			when "110111" => vid_piece_reg <= piece_black & piece_pawn;
			when "111000" => vid_piece_reg <= piece_black & piece_rook;
			when "111001" => vid_piece_reg <= piece_black & piece_knight;
			when "111010" => vid_piece_reg <= piece_black & piece_bishop;
			when "111011" => vid_piece_reg <= piece_black & piece_queen;
			when "111100" => vid_piece_reg <= piece_black & piece_king;
			when "111101" => vid_piece_reg <= piece_black & piece_bishop;
			when "111110" => vid_piece_reg <= piece_black & piece_knight;
			when "111111" => vid_piece_reg <= piece_black & piece_rook;
			when others =>
				vid_piece_reg <= piece_white & piece_none;
			end case;
		end if;
	end process;
end architecture;
