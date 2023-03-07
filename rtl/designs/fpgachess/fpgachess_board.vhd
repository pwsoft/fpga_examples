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
-- Keeps track of the board state
--
-- -----------------------------------------------------------------------
-- clk             - System clock input
--
-- search_req      - Toggle to start a move search on the board
-- search_ack      - Toggles when a search is complete
-- search_color    - Color to use when searching a move on the board
-- search_fromto   - Starting point when searching a move on the board
-- found_done      - High when no new move have been found on the board
-- found_fromto    - Coordinate and target of the found move on the board
--
-- vid_row   - Board row currently displayed by the video subsystem
-- vid_col   - Board column currently displayed by the video subsystem
-- vid_piece - Returns piece located on cell pointed to by vid_row and vid_col
-- -----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_board is
	port (
		clk : in std_logic;
		busy : out std_logic;

		new_game_trig : in std_logic;

		move_trig : in std_logic;
		move_fromto : in unsigned(11 downto 0);
		undo_trig : in std_logic;
		undo_fromto : in unsigned(11 downto 0);
		undo_captured : in piece_t;

		search_req : in std_logic;
		search_ack : out std_logic;
		search_color : in std_logic;
		search_fromto : in unsigned(11 downto 0);
		found_valid : out std_logic;
		found_done : out std_logic;
		found_fromto : out unsigned(11 downto 0);

		movelist_trig : out std_logic;
		movelist_fromto : out unsigned(11 downto 0);
		movelist_captured : out piece_t;

		vid_row : in unsigned(2 downto 0);
		vid_col : in unsigned(2 downto 0);
		vid_piece : out piece_t;

		vid_eval : out signed(11 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_board is
	constant eval_sum_bits : integer := 12;
	constant eval_part_bits : integer := 8;

	signal busy_reg : std_logic := '0';
	signal vid_piece_reg : piece_t := (others => '0');

	type board_t is array(0 to 63) of piece_t;
	type extboard_t is array(0 to 63) of extpiece_t;
	type eval_cells_t is array(0 to 63) of signed(eval_part_bits-1 downto 0);
	type eval_sum_t is array(0 to 7) of signed(eval_sum_bits-1 downto 0);

	constant init_board : extboard_t :=  (
			ext_wrook, ext_wknight, ext_wbishop, ext_wqueen, ext_wking, ext_wbishop, ext_wknight, ext_wrook,
			ext_wpawn, ext_wpawn, ext_wpawn, ext_wpawn, ext_wpawn, ext_wpawn, ext_wpawn, ext_wpawn,
			ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty,
			ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty,
			ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty,
			ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty, ext_empty,
			ext_bpawn, ext_bpawn, ext_bpawn, ext_bpawn, ext_bpawn, ext_bpawn, ext_bpawn, ext_bpawn,
			ext_brook, ext_bknight, ext_bbishop, ext_bqueen, ext_bking, ext_bbishop, ext_bknight, ext_brook
		);
	signal display_board_reg : board_t := (others => piece_empty);
	signal eval_board_reg : extboard_t := init_board;
	signal eval_cells_reg : eval_cells_t := (others => (others => '0'));
	signal eval_row_sum_reg : eval_sum_t := (others => (others => '0'));
	signal eval_sum_reg : signed(eval_sum_bits-1 downto 0) := (others => '0');

	signal move_piece_reg : extpiece_t := ext_empty;
	signal move_phase2_reg : std_logic := '0';
	signal undo_phase2_reg : std_logic := '0';
	signal update_display_reg : std_logic := '0';
begin
	busy <= busy_reg;
	vid_piece <= vid_piece_reg;
	vid_eval <= eval_sum_reg;

	eval_block : block
		-- Check if there are files with pawns of only one color
		signal wpawn_in_file_reg : unsigned(0 to 7) := (others => '0');
		signal bpawn_in_file_reg : unsigned(0 to 7) := (others => '0');
		signal wpawn_sum : unsigned(3 downto 0) := (others => '0');
		signal bpawn_sum : unsigned(3 downto 0) := (others => '0');
		signal pawn_sum_reg : signed(4 downto 0) := (others => '0');
	begin
		popcnt8_wpawn_inst : entity work.fpgachess_popcnt8
			port map (
				d => wpawn_in_file_reg,
				q => wpawn_sum
			);
		popcnt8_bpawn_inst : entity work.fpgachess_popcnt8
			port map (
				d => bpawn_in_file_reg,
				q => bpawn_sum
			);


		process(clk)
			variable row_sum : signed(eval_sum_bits-1 downto 0);
--			variable pawn_sum : signed(pawn_sum_reg'range);
			variable sum : signed(eval_sum_bits-1 downto 0);

		begin
			if rising_edge(clk) then
				wpawn_in_file_reg <= (others => '0');
				bpawn_in_file_reg <= (others => '0');
				for cell in 0 to 63 loop
					case to_piece(eval_board_reg(cell)) is
					when piece_white & piece_pawn =>
						eval_cells_reg(cell) <= to_signed(10, eval_part_bits);
						wpawn_in_file_reg(cell mod 8) <= '1';
					when piece_white & piece_bishop => eval_cells_reg(cell) <= to_signed(30, eval_part_bits);
					when piece_white & piece_knight => eval_cells_reg(cell) <= to_signed(30, eval_part_bits);
					when piece_white & piece_rook => eval_cells_reg(cell) <= to_signed(50, eval_part_bits);
					when piece_white & piece_queen => eval_cells_reg(cell) <= to_signed(70, eval_part_bits);
					when piece_white & piece_king => eval_cells_reg(cell) <= to_signed(100, eval_part_bits);
					when piece_black & piece_pawn =>
						eval_cells_reg(cell) <= to_signed(-10, eval_part_bits);
						bpawn_in_file_reg(cell mod 8) <= '1';
					when piece_black & piece_bishop => eval_cells_reg(cell) <= to_signed(-30, eval_part_bits);
					when piece_black & piece_knight => eval_cells_reg(cell) <= to_signed(-30, eval_part_bits);
					when piece_black & piece_rook => eval_cells_reg(cell) <= to_signed(-50, eval_part_bits);
					when piece_black & piece_queen => eval_cells_reg(cell) <= to_signed(-70, eval_part_bits);
					when piece_black & piece_king => eval_cells_reg(cell) <= to_signed(-100, eval_part_bits);
					when others =>
						eval_cells_reg(cell) <= (others => '0');
					end case;
				end loop;

				for row in 0 to 7 loop
					row_sum := (others => '0');
					for col in 0 to 7 loop
						row_sum := row_sum + resize(eval_cells_reg(row*8+col), eval_sum_bits);
					end loop;
					eval_row_sum_reg(row) <= row_sum;
				end loop;

				pawn_sum_reg <= "00000" + to_integer(wpawn_sum) - to_integer(bpawn_sum);

				sum := (others => '0');
				sum := sum + resize(pawn_sum_reg, eval_sum_bits);
				for row in 0 to 7 loop
					sum := sum + eval_row_sum_reg(row);
				end loop;
				eval_sum_reg <= sum;
			end if;
		end process;
	end block;

	move_blk : block
		signal fromto_reg : unsigned(11 downto 0);
		signal movelist_trig_reg : std_logic := '0';
		signal movelist_fromto_reg : unsigned(movelist_fromto'range) := (others => '0');
		signal movelist_captured_reg : unsigned(movelist_captured'range) := (others => '0');
	begin
		movelist_trig <= movelist_trig_reg;
		movelist_fromto <= movelist_fromto_reg;
		movelist_captured <= movelist_captured_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				move_phase2_reg <= '0';
				undo_phase2_reg <= '0';
				movelist_trig_reg <= '0';
				update_display_reg <= '0';

				if new_game_trig = '1' then
					eval_board_reg <= init_board;
					update_display_reg <= '1';
				end if;
				if move_trig = '1' then
					move_phase2_reg <= '1';
					fromto_reg <= move_fromto;
					movelist_trig_reg <= '1';
					movelist_fromto_reg <= move_fromto;
					movelist_captured_reg <= to_piece(eval_board_reg(to_integer(move_fromto(5 downto 0))));
					move_piece_reg <= eval_board_reg(to_integer(move_fromto(11 downto 6)));
				end if;
				if move_phase2_reg = '1' then
					eval_board_reg(to_integer(fromto_reg(5 downto 0))) <= move_piece_reg;
					eval_board_reg(to_integer(fromto_reg(11 downto 6))) <= piece_empty;
					update_display_reg <= '1';
				end if;
				if undo_trig = '1' then
					undo_phase2_reg <= '1';
					fromto_reg <= undo_fromto;
					move_piece_reg <= eval_board_reg(to_integer(undo_fromto(5 downto 0)));
				end if;
				if undo_phase2_reg = '1' then
					eval_board_reg(to_integer(fromto_reg(5 downto 0))) <= to_extpiece(undo_captured);
					eval_board_reg(to_integer(fromto_reg(11 downto 6))) <= move_piece_reg;
					update_display_reg <= '1';
				end if;
			end if;
		end process;
	end block;

	search_blk : block
		signal search_req_reg : std_logic := '0';
		signal search_ack_reg : std_logic := '0';
		signal found_valid_reg : std_logic := '0';
		signal search_fetch_reg : std_logic := '0';
		signal search_check_reg : std_logic := '0';
		signal search_piece_reg : extpiece_t := ext_empty;

		signal search_from_reg : unsigned(6 downto 0) := (others => '0');
		signal search_to_reg : unsigned(5 downto 0) := (others => '0');
		signal search_from_incr : unsigned(6 downto 0);
	begin
		search_ack <= search_ack_reg;
		search_from_incr <= search_from_reg + 1;
		found_valid <= found_valid_reg;
		found_done <= search_from_reg(6);
		found_fromto <= search_from_reg(5 downto 0) & search_to_reg;

		process(clk)
			variable valid : std_logic;
			variable skip : std_logic;
			variable col : integer range 0 to 7;
			variable row : integer range 0 to 7;
			variable cell : integer range 0 to 63;
			variable dest : integer range 0 to 63;
		begin
			if rising_edge(clk) then
				if search_from_reg(6) = '1' then
					-- Searched every cell
					search_ack_reg <= search_req_reg;
					found_valid_reg <= '1';
					search_fetch_reg <= '0';
					search_check_reg <= '0';
				elsif search_fetch_reg = '1' then
					search_fetch_reg <= '0';
					search_check_reg <= '1';
					search_piece_reg <= eval_board_reg(to_integer(search_from_reg(5 downto 0)));
				end if;

				if search_check_reg = '1' then
					valid := '0';
					skip := '0';
					col := to_integer(search_from_reg(2 downto 0));
					row := to_integer(search_from_reg(5 downto 3));
					cell := to_integer(search_from_reg(5 downto 0));
					dest := to_integer(search_to_reg);

					search_check_reg <= '0';
					if ((search_color = '0') and (search_piece_reg(4) = '0'))
					or ((search_color = '1') and (search_piece_reg(3) = '0')) then
						-- Cell doesn't have piece of matching color, so search next
						skip := '1';
					else
						case search_piece_reg(3 downto 0) is
						when piece_white & piece_pawn =>
							if search_to_reg = search_from_reg then
								-- Move forward once
								dest := cell+8;
								if eval_board_reg(dest)(4 downto 3) = "00" then
									valid := '1';
								end if;
							elsif search_to_reg = cell+8 then
								-- Capture left
								dest := cell+7;
								if (eval_board_reg(dest)(3) = '1') and (col /= 0) then
									valid := '1';
								end if;
							elsif search_to_reg = cell+7 then
								-- Capture right
								dest := cell+9;
								if (eval_board_reg(dest)(3) = '1') and (col /= 7) then
									valid := '1';
								end if;
							elsif (search_to_reg = cell+9) and (row = 1) then
								-- Two spaces forward on row one
								dest := cell+16;
								if (eval_board_reg(cell+8)(4 downto 3) = "00") and (eval_board_reg(dest)(4 downto 3) = "00") then
									valid := '1';
								end if;
							else
								skip := '1';
							end if;
						when piece_black & piece_pawn =>
							if search_to_reg = search_from_reg then
								-- Move forward once
								dest := cell-8;
								if eval_board_reg(dest)(4 downto 3) = "00" then
									valid := '1';
								end if;
							elsif search_to_reg = cell-8 then
								-- Capture right
								dest := cell-7;
								if (eval_board_reg(dest)(4) = '1') and (col /= 7) then
									valid := '1';
								end if;
							elsif search_to_reg = cell-7 then
								-- Capture left
								dest := cell-9;
								if (eval_board_reg(dest)(4) = '1') and (col /= 0) then
									valid := '1';
								end if;
							elsif (search_to_reg = cell-9) and (row = 6) then
								-- Two spaces forward on row six
								dest := cell-16;
								if (eval_board_reg(cell-8)(4 downto 3) = "00") and (eval_board_reg(dest)(4 downto 3) = "00") then
									valid := '1';
								end if;
							else
								skip := '1';
							end if;
						when others =>
							skip := '1';
						end case;
					end if;

					search_to_reg <= to_unsigned(dest, 6);
					if valid = '1' then
						search_ack_reg <= search_req_reg;
					else
						search_fetch_reg <= '1';
					end if;
					if skip = '1' then
						search_from_reg <= search_from_incr;
						search_to_reg <= search_from_incr(5 downto 0);
					end if;
				end if;

				if search_req /= search_req_reg then
					search_req_reg <= search_req;
					found_valid_reg <= '0';
					search_fetch_reg <= '1';
					search_check_reg <= '0';
					search_from_reg <= "0" & search_fromto(11 downto 6);
					search_to_reg <= search_fromto(5 downto 0);
				end if;
			end if;
		end process;
	end block;

	display_blk : block
		signal display_col0_reg : piece_t := piece_empty;
		signal display_col1_reg : piece_t := piece_empty;
		signal display_col2_reg : piece_t := piece_empty;
		signal display_col3_reg : piece_t := piece_empty;
		signal display_col4_reg : piece_t := piece_empty;
		signal display_col5_reg : piece_t := piece_empty;
		signal display_col6_reg : piece_t := piece_empty;
		signal display_col7_reg : piece_t := piece_empty;
	begin
		process(clk)
		begin
			if rising_edge(clk) then
				if update_display_reg = '1' then
					for i in 0 to 63 loop
						display_board_reg(i) <= to_piece(eval_board_reg(i));
					end loop;
				end if;
			end if;
		end process;

		process(clk)
		begin
			if rising_edge(clk) then
				-- Select a single cell from the display board and send it to the video logic.
				-- Multiplexing 64 squares into one output makes the logic large.
				-- So it is done in two separate steps. First for the current row all
				-- the columns are collected. Then the selection of a specific column is made.
				-- This reduces the mux sizes from 64 to 8 making it easier to meet timing.
				--
				display_col0_reg <= display_board_reg(to_integer(vid_row & "000"));
				display_col1_reg <= display_board_reg(to_integer(vid_row & "001"));
				display_col2_reg <= display_board_reg(to_integer(vid_row & "010"));
				display_col3_reg <= display_board_reg(to_integer(vid_row & "011"));
				display_col4_reg <= display_board_reg(to_integer(vid_row & "100"));
				display_col5_reg <= display_board_reg(to_integer(vid_row & "101"));
				display_col6_reg <= display_board_reg(to_integer(vid_row & "110"));
				display_col7_reg <= display_board_reg(to_integer(vid_row & "111"));

				case vid_col is
				when "000" => vid_piece_reg <= display_col0_reg;
				when "001" => vid_piece_reg <= display_col1_reg;
				when "010" => vid_piece_reg <= display_col2_reg;
				when "011" => vid_piece_reg <= display_col3_reg;
				when "100" => vid_piece_reg <= display_col4_reg;
				when "101" => vid_piece_reg <= display_col5_reg;
				when "110" => vid_piece_reg <= display_col6_reg;
				when others => vid_piece_reg <= display_col7_reg;
				end case;
			end if;
		end process;
	end block;
end architecture;
