library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_video is
	generic (
		board_xpos : integer := 16;
		board_ypos : integer := 16
	);
	port (
		clk : in std_logic;
		white_top : in std_logic;

		cursor_col : in unsigned(2 downto 0);
		cursor_row : in unsigned(2 downto 0);

		row : out unsigned(2 downto 0);
		col : out unsigned(2 downto 0);
		piece : in piece_t;

		red : out unsigned(7 downto 0);
		grn : out unsigned(7 downto 0);
		blu : out unsigned(7 downto 0);
		hsync : out std_logic;
		vsync : out std_logic
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_video is
-- Colors
	type color_t is (
			C_BLANK, C_BACKGROUND, C_BORDER,
			C_CHARACTER,
			C_BOARD_CURSOR, C_BOARD_LIGHT, C_BOARD_DARK,
			C_PIECE_BLACK, C_PIECE_WHITE
		);
	signal current_color : color_t;

-- Video pipeline
	signal end_of_line : std_logic;
	signal end_of_frame : std_logic;
	type vid_stage_t is record
			ena_pixel : std_logic;
			hsync : std_logic;
			vsync : std_logic;
			x : unsigned(11 downto 0);
			y : unsigned(11 downto 0);

			board : std_logic;
			-- Selects the chess cell currently rendered, only valid if "board" is set
			board_col : unsigned(2 downto 0);
			board_row : unsigned(2 downto 0);
			-- Coordinates within a chess cell, only valid if "board" is set
			board_colx : unsigned(5 downto 0);
			board_rowy : unsigned(5 downto 0);
		end record;
	signal vga_master : vid_stage_t;
	signal vga_coords : vid_stage_t;
	signal vga_matrix : vid_stage_t;
	signal vga_character : vid_stage_t;
	signal vga_color : vid_stage_t;
	signal current_char : unsigned(7 downto 0);
	signal current_pixels : unsigned(7 downto 0);
	signal piece_pixels : unsigned(47 downto 0);
begin
-- -----------------------------------------------------------------------
-- Video timing 640x480
-- -----------------------------------------------------------------------
	vga_master_inst : entity work.video_vga_master
		generic map (
			clkDivBits => 4
		)
		port map (
			clk => clk,
			-- 100 Mhz / (3+1) = 25 Mhz
			clkDiv => X"3",

			hSync => vga_master.hsync,
			vSync => vga_master.vsync,

			endOfPixel => vga_master.ena_pixel,
			endOfLine => end_of_line,
			endOfFrame => end_of_frame,
			currentX => vga_master.x,
			currentY => vga_master.y,

			-- Setup 640x480@60hz needs ~25 Mhz
			hSyncPol => '0',
			vSyncPol => '0',
			xSize => to_unsigned(800, 12),
			ySize => to_unsigned(525, 12),
			xSyncFr => to_unsigned(656, 12), -- Sync pulse 96
			xSyncTo => to_unsigned(752, 12),
			ySyncFr => to_unsigned(500, 12), -- Sync pulse 2
			ySyncTo => to_unsigned(502, 12)
		);

	vga_master.board <= '0';
	vga_master.board_col <= "000";
	vga_master.board_row <= "000";
	vga_master.board_colx <= (others => '0');
	vga_master.board_rowy <= (others => '0');

-- -----------------------------------------------------------------------
-- Coordinates
-- -----------------------------------------------------------------------
	coords_blk : block
		signal vga_coords_reg : vid_stage_t;
		signal board_xrun_reg : std_logic := '0';
		signal board_yrun_reg : std_logic := '0';
		signal board_xcnt_reg : unsigned(5 downto 0) := (others => '0');
		signal board_ycnt_reg : unsigned(5 downto 0) := (others => '0');
		signal board_col_reg : unsigned(2 downto 0) := (others => '0');
		signal board_row_reg : unsigned(2 downto 0) := (others => '0');
	begin
		vga_coords <= vga_coords_reg;
		col <= board_col_reg;
		row <= not board_row_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				vga_coords_reg <= vga_master;

				if vga_master.ena_pixel = '1' then
					if vga_master.x = board_xpos-1 then
						board_xrun_reg <= '1';
					end if;
					if board_xrun_reg = '1' then
						board_xcnt_reg <= board_xcnt_reg + 1;
					end if;
					if board_xcnt_reg = 47 then
						board_xcnt_reg <= (others => '0');
						board_col_reg <= board_col_reg + 1;
						if board_col_reg = 7 then
							board_xrun_reg <= '0';
						end if;
					end if;
				end if;

				if end_of_line = '1' then
					if vga_master.y = board_ypos then
						board_yrun_reg <= '1';
					end if;
					if board_yrun_reg = '1' then
						board_ycnt_reg <= board_ycnt_reg + 1;
					end if;
					if board_ycnt_reg = 47 then
						board_ycnt_reg <= (others => '0');
						board_row_reg <= board_row_reg + 1;
						if board_row_reg = 7 then
							board_yrun_reg <= '0';
						end if;
					end if;
				end if;

				vga_coords_reg.board <= board_xrun_reg and board_yrun_reg;
				vga_coords_reg.board_col <= board_col_reg;
				vga_coords_reg.board_row <= board_row_reg;
				vga_coords_reg.board_colx <= board_xcnt_reg;
				vga_coords_reg.board_rowy <= board_ycnt_reg;
			end if;
		end process;
	end block;

-- -----------------------------------------------------------------------
-- Screen matrix
-- -----------------------------------------------------------------------
	matrix_blk : block
		signal vga_matrix_reg : vid_stage_t;
		signal current_char_reg : unsigned(7 downto 0);
	begin
		vga_matrix <= vga_matrix_reg;
		current_char <= current_char_reg;
		process(clk)
		begin
			if rising_edge(clk) then
				vga_matrix_reg <= vga_coords;
				current_char_reg <= X"20";
				--current_char_reg <= vga_coords.x(8 downto 4) & vga_coords.y(6 downto 4);

--				if vga_coords.board = '1' then
--					case piece is
--					when piece_white & piece_pawn => current_char_reg <= X"50";   -- P
--					when piece_white & piece_bishop => current_char_reg <= X"42"; -- B
--					when piece_white & piece_knight => current_char_reg <= X"4E"; -- N
--					when piece_white & piece_rook => current_char_reg <= X"52"; -- R
--					when piece_white & piece_queen => current_char_reg <= X"51"; -- Q
--					when piece_white & piece_king => current_char_reg <= X"4B"; -- K
--					when piece_black & piece_pawn => current_char_reg <= X"70";
--					when piece_black & piece_bishop => current_char_reg <= X"62";
--					when piece_black & piece_knight => current_char_reg <= X"6E";
--					when piece_black & piece_rook => current_char_reg <= X"72"; -- R
--					when piece_black & piece_queen => current_char_reg <= X"71"; -- Q
--					when piece_black & piece_king => current_char_reg <= X"6B"; -- K
--					when others =>
--						null;
--					end case;
--				end if;

				case vga_coords.y(8 downto 4) is
				when "00010" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"38";
					when others =>
						null;
					end case;
				when "00101" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"37";
					when others =>
						null;
					end case;
				when "01000" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"36";
					when others =>
						null;
					end case;
				when "01011" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"35";
					when others =>
						null;
					end case;
				when "01110" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"34";
					when others =>
						null;
					end case;
				when "10001" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"33";
					when others =>
						null;
					end case;
				when "10100" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"32";
					when others =>
						null;
					end case;
				when "10111" =>
					case vga_coords.x(9 downto 4) is
					when "000000" => current_char_reg <= X"31";
					when others =>
						null;
					end case;
				when "11001" =>
					case vga_coords.x(9 downto 4) is
					when "000010" => current_char_reg <= X"61";
					when "000101" => current_char_reg <= X"62";
					when "001000" => current_char_reg <= X"63";
					when "001011" => current_char_reg <= X"64";
					when "001110" => current_char_reg <= X"65";
					when "010001" => current_char_reg <= X"66";
					when "010100" => current_char_reg <= X"67";
					when "010111" => current_char_reg <= X"68";
					when others =>
						null;
					end case;
				when "11101" =>
					case vga_coords.x(9 downto 4) is
					when "011111" => current_char_reg <= X"46"; -- F
					when "100000" => current_char_reg <= X"50"; -- P
					when "100001" => current_char_reg <= X"47"; -- G
					when "100010" => current_char_reg <= X"41"; -- A
					when "100011" => current_char_reg <= X"43"; -- C
					when "100100" => current_char_reg <= X"48"; -- H
					when "100101" => current_char_reg <= X"45"; -- E
					when "100110" => current_char_reg <= X"53"; -- S
					when "100111" => current_char_reg <= X"53"; -- S
					when others =>
						null;
					end case;
				when others =>
					null;
				end case;
			end if;
		end process;
	end block;

-- -----------------------------------------------------------------------
-- Character generator
-- -----------------------------------------------------------------------
	character_blk : block
		type charrom_t is array(0 to 1023) of unsigned(7 downto 0);
		constant charrom_init : charrom_t := (
			X"AA", X"55", X"AA", X"55", X"AA", X"55", X"AA", X"55",
			X"60", X"60", X"60", X"60", X"7F", X"7F", X"00", X"00",
			X"00", X"00", X"00", X"00", X"C0", X"C0", X"00", X"00",
			X"03", X"03", X"03", X"03", X"03", X"03", X"00", X"00",
			X"18", X"0C", X"06", X"03", X"03", X"01", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"80", X"00", X"00",
			X"00", X"00", X"0C", X"0C", X"07", X"03", X"00", X"00",
			X"38", X"0C", X"0C", X"0C", X"38", X"F0", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
			X"08", X"08", X"08", X"08", X"08", X"00", X"08", X"00", -- !
			X"14", X"14", X"00", X"00", X"00", X"00", X"00", X"00", -- "
			X"14", X"14", X"7F", X"14", X"7F", X"14", X"14", X"00", -- #
			X"08", X"1E", X"28", X"1C", X"0A", X"3C", X"08", X"00", -- $
			X"00", X"32", X"34", X"08", X"16", X"26", X"00", X"00", -- %
			X"18", X"28", X"10", X"28", X"46", X"44", X"3A", X"00", -- &
			X"08", X"08", X"00", X"00", X"00", X"00", X"00", X"00", -- '
			X"04", X"08", X"10", X"10", X"10", X"08", X"04", X"00", -- (
			X"10", X"08", X"04", X"04", X"04", X"08", X"10", X"00", -- )
			X"08", X"49", X"2A", X"1C", X"2A", X"49", X"08", X"00", -- *
			X"08", X"08", X"08", X"7F", X"08", X"08", X"08", X"00", -- +
			X"00", X"00", X"00", X"00", X"0C", X"0C", X"04", X"08", -- ,
			X"00", X"00", X"00", X"7F", X"00", X"00", X"00", X"00", -- -
			X"00", X"00", X"00", X"00", X"00", X"0C", X"0C", X"00", -- .
			X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"00", -- /
			X"1C", X"22", X"22", X"2A", X"22", X"22", X"1C", X"00", -- 0
			X"08", X"18", X"08", X"08", X"08", X"08", X"1C", X"00", -- 1
			X"1C", X"22", X"02", X"04", X"08", X"10", X"3E", X"00", -- 2
			X"1C", X"22", X"02", X"0C", X"02", X"22", X"1C", X"00", -- 3
			X"0C", X"14", X"24", X"3E", X"04", X"04", X"0E", X"00", -- 4
			X"3E", X"20", X"3C", X"02", X"02", X"22", X"1C", X"00", -- 5
			X"1C", X"20", X"20", X"3C", X"22", X"22", X"1C", X"00", -- 6
			X"3E", X"02", X"04", X"08", X"10", X"10", X"10", X"00", -- 7
			X"1C", X"22", X"22", X"1C", X"22", X"22", X"1C", X"00", -- 8
			X"1C", X"22", X"22", X"1E", X"02", X"02", X"1C", X"00", -- 9
			X"00", X"0C", X"0C", X"00", X"0C", X"0C", X"00", X"00", -- :
			X"00", X"0C", X"0C", X"00", X"0C", X"0C", X"04", X"08", -- ;
			X"04", X"08", X"10", X"20", X"10", X"08", X"04", X"00", -- <
			X"00", X"00", X"7F", X"00", X"7F", X"00", X"00", X"00", -- =
			X"20", X"10", X"08", X"04", X"08", X"10", X"20", X"00", -- >
			X"1C", X"22", X"02", X"04", X"08", X"00", X"08", X"00", -- ?
			X"1C", X"22", X"2E", X"2A", X"2E", X"20", X"1C", X"00", -- @
			X"1C", X"22", X"22", X"3E", X"22", X"22", X"22", X"00", -- A
			X"3C", X"22", X"22", X"3C", X"22", X"22", X"3C", X"00", -- B
			X"1C", X"22", X"20", X"20", X"20", X"22", X"1C", X"00", -- C
			X"38", X"24", X"22", X"22", X"22", X"24", X"38", X"00", -- D
			X"3E", X"20", X"20", X"3C", X"20", X"20", X"3E", X"00", -- E
			X"3E", X"20", X"20", X"3C", X"20", X"20", X"20", X"00", -- F
			X"1C", X"22", X"20", X"2E", X"22", X"22", X"1C", X"00", -- G
			X"22", X"22", X"22", X"3E", X"22", X"22", X"22", X"00", -- H
			X"1C", X"08", X"08", X"08", X"08", X"08", X"1C", X"00", -- I
			X"0E", X"04", X"04", X"04", X"24", X"24", X"18", X"00", -- J
			X"22", X"22", X"24", X"38", X"24", X"22", X"22", X"00", -- K
			X"10", X"10", X"10", X"10", X"10", X"10", X"1E", X"00", -- L
			X"41", X"63", X"55", X"49", X"41", X"41", X"41", X"00", -- M
			X"22", X"32", X"2A", X"2A", X"26", X"22", X"22", X"00", -- N
			X"1C", X"22", X"22", X"22", X"22", X"22", X"1C", X"00", -- O
			X"1C", X"12", X"12", X"1C", X"10", X"10", X"10", X"00", -- P
			X"1C", X"22", X"22", X"22", X"22", X"22", X"1C", X"06", -- Q
			X"3C", X"22", X"22", X"3C", X"28", X"24", X"22", X"00", -- R
			X"1C", X"22", X"20", X"1C", X"02", X"22", X"1C", X"00", -- S
			X"3E", X"08", X"08", X"08", X"08", X"08", X"08", X"00", -- T
			X"22", X"22", X"22", X"22", X"22", X"22", X"1C", X"00", -- U
			X"22", X"22", X"22", X"14", X"14", X"08", X"08", X"00", -- V
			X"41", X"41", X"41", X"2A", X"2A", X"14", X"14", X"00", -- W
			X"22", X"22", X"14", X"08", X"14", X"22", X"22", X"00", -- X
			X"22", X"22", X"14", X"08", X"08", X"08", X"08", X"00", -- Y
			X"3E", X"02", X"04", X"08", X"10", X"20", X"3E", X"00", -- Z
			X"1C", X"10", X"10", X"10", X"10", X"10", X"1C", X"00", -- [
			X"40", X"20", X"10", X"08", X"04", X"02", X"01", X"00", -- \
			X"1C", X"04", X"04", X"04", X"04", X"04", X"1C", X"00", -- ]
			X"08", X"14", X"22", X"00", X"00", X"00", X"00", X"00", -- ^
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"7F", -- _
			X"10", X"08", X"00", X"00", X"00", X"00", X"00", X"00", -- `
			X"00", X"1C", X"02", X"1E", X"22", X"22", X"1D", X"00", -- a
			X"10", X"10", X"1C", X"12", X"12", X"12", X"2C", X"00", -- b
			X"00", X"00", X"1C", X"20", X"20", X"20", X"1C", X"00", -- c
			X"02", X"02", X"0E", X"12", X"12", X"12", X"0D", X"00", -- d
			X"00", X"00", X"1C", X"22", X"3E", X"20", X"1C", X"00", -- e
			X"0C", X"12", X"10", X"38", X"10", X"10", X"10", X"00", -- f
			X"00", X"00", X"1D", X"22", X"22", X"1E", X"02", X"1C", -- g
			X"20", X"20", X"2C", X"32", X"22", X"22", X"22", X"00", -- h
			X"00", X"08", X"00", X"08", X"08", X"08", X"08", X"00", -- i
			X"00", X"08", X"00", X"08", X"08", X"08", X"08", X"30", -- j
			X"20", X"20", X"24", X"28", X"30", X"28", X"24", X"00", -- k
			X"18", X"08", X"08", X"08", X"08", X"08", X"08", X"00", -- l
			X"00", X"00", X"B6", X"49", X"49", X"41", X"41", X"00", -- m
			X"00", X"00", X"2C", X"12", X"12", X"12", X"12", X"00", -- n
			X"00", X"00", X"1C", X"22", X"22", X"22", X"1C", X"00", -- o
			X"00", X"00", X"2C", X"12", X"12", X"1C", X"10", X"10", -- p
			X"00", X"00", X"1A", X"24", X"24", X"1C", X"04", X"04", -- q
			X"00", X"00", X"2C", X"30", X"20", X"20", X"20", X"00", -- r
			X"00", X"00", X"1C", X"20", X"18", X"04", X"38", X"00", -- s
			X"00", X"08", X"1C", X"08", X"08", X"08", X"08", X"00", -- t
			X"00", X"00", X"24", X"24", X"24", X"24", X"1A", X"00", -- u
			X"00", X"00", X"22", X"22", X"22", X"14", X"08", X"00", -- v
			X"00", X"00", X"41", X"41", X"49", X"55", X"22", X"00", -- w
			X"00", X"00", X"22", X"14", X"08", X"14", X"22", X"00", -- x
			X"00", X"00", X"12", X"12", X"12", X"0E", X"02", X"1C", -- y
			X"00", X"00", X"3C", X"04", X"08", X"10", X"3C", X"00", -- z
			X"0C", X"10", X"10", X"20", X"10", X"10", X"0C", X"00", -- {
			X"08", X"08", X"08", X"08", X"08", X"08", X"08", X"00", -- |
			X"30", X"08", X"08", X"04", X"08", X"08", X"30", X"00", -- }
			X"00", X"00", X"30", X"49", X"06", X"00", X"00", X"00", -- ~
			X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00");
		signal charrom : charrom_t := charrom_init;
		signal vga_char_reg : vid_stage_t;
		signal pixels_reg : unsigned(7 downto 0);
	begin
		vga_character <= vga_char_reg;
		current_pixels <= pixels_reg;
		process(clk)
		begin
			if rising_edge(clk) then
				vga_char_reg <= vga_matrix;
				pixels_reg <= charrom(to_integer(current_char(6 downto 0) & vga_matrix.y(3 downto 1)));
			end if;
		end process;
	end block;

	piece_blk : block
		signal piece_pixels_reg : unsigned(piece_pixels'range) := (others => '0');
	begin
		piece_pixels <= piece_pixels_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				piece_pixels_reg <= (others => '0');

				case piece(2 downto 0) is
				when piece_pawn =>
					case vga_matrix.board_rowy is     --  0       1       2       3       4       5       X
					when "001000" => piece_pixels_reg <= "000000000000000000000111111000000000000000000000";
					when "001001" => piece_pixels_reg <= "000000000000000000011111111110000000000000000000";
					when "001010" => piece_pixels_reg <= "000000000000000000111111111111000000000000000000";
					when "001011" => piece_pixels_reg <= "000000000000000001111111111111100000000000000000";
					when "001100" => piece_pixels_reg <= "000000000000000011111111111111110000000000000000";
					when "001101" => piece_pixels_reg <= "000000000000000011111111111111110000000000000000";
					when "001110" => piece_pixels_reg <= "000000000000000001111111111111100000000000000000";
					when "001111" => piece_pixels_reg <= "000000000000000000111111111111000000000000000000";
					when "010000" => piece_pixels_reg <= "000000000000000000011111111110000000000000000000";
					when "010001" => piece_pixels_reg <= "000000000000000000000111111000000000000000000000";
					when "010010" => piece_pixels_reg <= "000000000000000000111111111111000000000000000000";
					when "010011" => piece_pixels_reg <= "000000000000000011111111111111110000000000000000";
					when "010100" => piece_pixels_reg <= "000000000000001111111111111111111100000000000000";
					when "010101" => piece_pixels_reg <= "000000000000000000001111111100000000000000000000";
					when "010110" => piece_pixels_reg <= "000000000000000000001111111100000000000000000000";
					when "010111" => piece_pixels_reg <= "000000000000000000011111111110000000000000000000";
					when "011000" => piece_pixels_reg <= "000000000000000000011111111110000000000000000000";
					when "011001" => piece_pixels_reg <= "000000000000000000111111111111000000000000000000";
					when "011010" => piece_pixels_reg <= "000000000000000000111111111111000000000000000000";
					when "011011" => piece_pixels_reg <= "000000000000000001111111111111100000000000000000";
					when "011100" => piece_pixels_reg <= "000000000000000011111111111111110000000000000000";
					when "011101" => piece_pixels_reg <= "000000000000000111111111111111111000000000000000";
					when "011110" => piece_pixels_reg <= "000000000000001111111111111111111100000000000000";
					when "011111" => piece_pixels_reg <= "000000000000011111111111111111111110000000000000";
					when "100000" => piece_pixels_reg <= "000000000000111111111111111111111111000000000000";
					when "100001" => piece_pixels_reg <= "000000000001111111111111111111111111100000000000";
					when others =>
						null;
					end case;
				when piece_knight =>
					case vga_matrix.board_rowy is     --  0       1       2       3       4       5       X
					when "001000" => piece_pixels_reg <= "000000000000000000000000000000000000000000000011";
					when "001001" => piece_pixels_reg <= "000000000000000000000000000000000000000000000000";
					when "001010" => piece_pixels_reg <= "000000000000000000000000000000000000000000000000";
					when "001011" => piece_pixels_reg <= "000000000000000000011111111000000000000000000000";
					when "001100" => piece_pixels_reg <= "000000000000000000101111111100000000000000000000";
					when "001101" => piece_pixels_reg <= "000000000000000001001111111110000000000000000000";
					when "001110" => piece_pixels_reg <= "000000000000000010001111111111000000000000000000";
					when "001111" => piece_pixels_reg <= "000000000000000111111111111111100000000000000000";
					when "010000" => piece_pixels_reg <= "000000000000001111111111111111110000000000000000";
					when "010001" => piece_pixels_reg <= "000000000000111111111111111111110000000000000000";
					when "010010" => piece_pixels_reg <= "000000000001111111111111111111111000000000000000";
					when "010011" => piece_pixels_reg <= "000000000011111111111111111111111000000000000000";
					when "010100" => piece_pixels_reg <= "000000000011111111111111111111111100000000000000";
					when "010101" => piece_pixels_reg <= "000000000011111111111111111111111100000000000000";
					when "010110" => piece_pixels_reg <= "000000000011111111111111111111111110000000000000";
					when "010111" => piece_pixels_reg <= "000000000011111110000001111111111110000000000000";
					when "011000" => piece_pixels_reg <= "000000000011111100000001111111111111000000000000";
					when "011001" => piece_pixels_reg <= "000000000011110000000011111111111111000000000000";
					when "011010" => piece_pixels_reg <= "000000000011110000011111111111111111000000000000";
					when "011011" => piece_pixels_reg <= "000000000011110001111111111111111111100000000000";
					when "011100" => piece_pixels_reg <= "000000000000000111111111111111111111100000000000";
					when "011101" => piece_pixels_reg <= "000000000000011111111111111111111111100000000000";
					when "011110" => piece_pixels_reg <= "000000000000111111111111111111111111110000000000";
					when "011111" => piece_pixels_reg <= "000000000001111111111111111111111111110000000000";
					when "100000" => piece_pixels_reg <= "000000000011111111111111111111111111110000000000";
					when "100001" => piece_pixels_reg <= "000000000011111111111111111111111111110000000000";
					when others =>
						null;
					end case;
				when piece_rook =>
					case vga_matrix.board_rowy is     --  0       1       2       3       4       5       X
					when "001000" => piece_pixels_reg <= "000000001111110000111100001111000011111100000000";
					when "001001" => piece_pixels_reg <= "000000001111110000111100001111000011111100000000";
					when "001010" => piece_pixels_reg <= "000000001111110000111100001111000011111100000000";
					when "001011" => piece_pixels_reg <= "000000001111110000111100001111000011111100000000";
					when "001100" => piece_pixels_reg <= "000000001111110000111100001111000011111100000000";
					when "001101" => piece_pixels_reg <= "000000000111111111111111111111111111111000000000";
					when "001110" => piece_pixels_reg <= "000000000011111111111111111111111111110000000000";
					when "001111" => piece_pixels_reg <= "000000000011100111111111111111111001110000000000";
					when "010000" => piece_pixels_reg <= "000000000011100111111111111111111001110000000000";
					when "010001" => piece_pixels_reg <= "000000000011100111111100111111111001110000000000";
					when "010010" => piece_pixels_reg <= "000000000011100111111100111111111001110000000000";
					when "010011" => piece_pixels_reg <= "000000000011111111111100111111111111110000000000";
					when "010100" => piece_pixels_reg <= "000000000011111111111100111111111111110000000000";
					when "010101" => piece_pixels_reg <= "000000000011111111111111111111001111110000000000";
					when "010110" => piece_pixels_reg <= "000000000011111111111111111111001111110000000000";
					when "010111" => piece_pixels_reg <= "000000000011111111111111111111001111110000000000";
					when "011000" => piece_pixels_reg <= "000000000011111111111111111111001111110000000000";
					when "011001" => piece_pixels_reg <= "000000000011111111111111111111111111110000000000";
					when "011010" => piece_pixels_reg <= "000000000011111110011111111111111111110000000000";
					when "011011" => piece_pixels_reg <= "000000000011111110011111111111111111110000000000";
					when "011100" => piece_pixels_reg <= "000000000011111110011111110001111111110000000000";
					when "011101" => piece_pixels_reg <= "000000000011111110011111100000111111110000000000";
					when "011110" => piece_pixels_reg <= "000000000011111111111111100000111111110000000000";
					when "011111" => piece_pixels_reg <= "000000000011111111111111100000111111110000000000";
					when "100000" => piece_pixels_reg <= "000000000011111111111111100000111111110000000000";
					when "100001" => piece_pixels_reg <= "000000000011111111111111100000111111110000000000";
					when others =>
						null;
					end case;
				when others =>
					null;
				end case;

				if piece(2 downto 0) /= piece_none then
					case vga_matrix.board_rowy is     --  0       1       2       3       4       5       X
					when "100010" => piece_pixels_reg <= "000000000011111111111111111111111111110000000000";
					when "100011" => piece_pixels_reg <= "000000000011000000000000000000000000110000000000";
					when "100100" => piece_pixels_reg <= "000000000111111111111111111111111111111000000000";
					when "100101" => piece_pixels_reg <= "000000000111111111111111111111111111111000000000";
					when "100110" => piece_pixels_reg <= "000000001111111111111111111111111111111100000000";
					when "100111" => piece_pixels_reg <= "000000001111111111111111111111111111111100000000";
					when others =>
						null;
					end case;
				end if;
			end if;
		end process;

	end block;

-- -----------------------------------------------------------------------
-- Combining, mixing and color selection
-- -----------------------------------------------------------------------
	color_blk : block
		signal vga_color_reg : vid_stage_t;
		signal color_reg : color_t := C_BLANK;
	begin
		vga_color <= vga_color_reg;
		current_color <= color_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				vga_color_reg <= vga_character;

				color_reg <= C_BACKGROUND;

				if vga_character.board = '1' then
					color_reg <= C_BOARD_LIGHT;
					if (vga_character.board_col(0) xor vga_character.board_row(0)) = '1' then
						color_reg <= C_BOARD_DARK;
					end if;
					if (cursor_row = vga_character.board_row) and (cursor_col = vga_character.board_col) then
						if (vga_character.board_colx = 0) or (vga_character.board_colx = 1) or (vga_character.board_colx = 46) or (vga_character.board_colx = 47)
						or (vga_character.board_rowy = 0) or (vga_character.board_rowy = 1) or (vga_character.board_rowy = 46) or (vga_character.board_rowy = 47) then
							color_reg <= C_BOARD_CURSOR;
						end if;
					end if;

					if piece_pixels(to_integer(47-vga_character.board_colx)) = '1' then
						color_reg <= C_PIECE_BLACK;
						if piece(3) = piece_white then
							color_reg <= C_PIECE_WHITE;
						end if;
					end if;
				end if;
				if current_pixels(to_integer(7-vga_character.x(3 downto 1))) = '1' then
					color_reg <= C_CHARACTER;
				end if;
				if ((vga_character.x < 2) or (vga_character.x >= 638 and vga_character.x < 640)) and (vga_character.y < 480) then
					color_reg <= C_BORDER;
				end if;
				if ((vga_character.y < 2) or (vga_character.y >= 478 and vga_character.y < 480)) and (vga_character.x < 640) then
					color_reg <= C_BORDER;
				end if;

				-- Never output pixels outside visible area
				if (vga_character.x > 639) or (vga_character.y > 479) then
					color_reg <= C_BLANK;
				end if;
			end if;
		end process;
	end block;

-- -----------------------------------------------------------------------
-- Output stage
-- -----------------------------------------------------------------------
	output_blk : block
		signal red_reg : unsigned(red'range) := (others => '0');
		signal grn_reg : unsigned(red'range) := (others => '0');
		signal blu_reg : unsigned(red'range) := (others => '0');
		signal output_reg : vid_stage_t;
	begin
		red <= red_reg;
		grn <= grn_reg;
		blu <= blu_reg;
		hsync <= output_reg.hsync;
		vsync <= output_reg.vsync;

		process(clk)
		begin
			if rising_edge(clk) then
				if vga_character.ena_pixel = '1' then
					output_reg <= vga_character;

					red_reg <= (others => '0');
					grn_reg <= (others => '0');
					blu_reg <= (others => '0');
					case current_color is
					when C_BLANK =>
						null;
					when C_BACKGROUND =>
						red_reg <= X"20";
					when C_BORDER =>
						red_reg <= (others => '1');
						grn_reg <= (others => '1');
						blu_reg <= (others => '1');
					when C_CHARACTER =>
						red_reg <= (others => '0');
						grn_reg <= (others => '1');
						blu_reg <= (others => '1');
					when C_BOARD_CURSOR =>
						red_reg <= X"FF";
						grn_reg <= X"FF";
					when C_BOARD_LIGHT =>
						grn_reg <= X"60";
					when C_BOARD_DARK =>
						grn_reg <= X"40";
					when C_PIECE_BLACK =>
						red_reg <= (others => '0');
						grn_reg <= (others => '0');
						blu_reg <= (others => '0');
					when C_PIECE_WHITE =>
						red_reg <= (others => '1');
						grn_reg <= (others => '1');
						blu_reg <= (others => '1');
					end case;
				end if;
			end if;
		end process;
	end block;

end architecture;
