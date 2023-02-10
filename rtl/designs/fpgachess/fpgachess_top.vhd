library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_top is
	port (
		clk : in std_logic;

		red : out unsigned(7 downto 0);
		grn : out unsigned(7 downto 0);
		blu : out unsigned(7 downto 0);
		hsync : out std_logic;
		vsync : out std_logic
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_top is
	signal vid_col : unsigned(2 downto 0);
	signal vid_row : unsigned(2 downto 0);
	signal vid_piece : piece_t;
begin
	board_inst : entity work.fpgachess_board
		port map (
			clk => clk,

			vid_col => vid_col,
			vid_row => vid_row,
			vid_piece => vid_piece
		);

	video_inst : entity work.fpgachess_video
		port map (
			clk => clk,
			white_top => '0',

			col => vid_col,
			row => vid_row,
			piece => vid_piece,

			red => red,
			grn => grn,
			blu => blu,
			hsync => hsync,
			vsync => vsync
		);
end architecture;
