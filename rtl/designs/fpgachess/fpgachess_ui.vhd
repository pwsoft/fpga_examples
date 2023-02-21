library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_pkg.all;
use work.fpgachess_pkg.all;

-- -----------------------------------------------------------------------

entity fpgachess_ui is
	port (
		clk : in std_logic;
		ena_1khz : in std_logic;

		cursor_up : in std_logic;
		cursor_down : in std_logic;
		cursor_left : in std_logic;
		cursor_right : in std_logic;
		cursor_enter : in std_logic;

		cursor_row : out unsigned(2 downto 0);
		cursor_col : out unsigned(3 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of fpgachess_ui is
	signal ena_cursor : std_logic;
	signal cursor_up_trig : std_logic;
	signal cursor_down_trig : std_logic;
	signal cursor_left_trig : std_logic;
	signal cursor_right_trig : std_logic;
	signal cursor_enter_trig : std_logic;
begin
	clk_blk : block
		signal ena_cnt_reg : unsigned(3 downto 0) := (others => '0');
		signal ena_reg : std_logic := '0';
	begin
		ena_cursor <= ena_reg;

		-- Divide 1khz clock to get enable signal for debounching the cursor control inputs
		process(clk)
		begin
			if rising_edge(clk) then
				ena_reg <= '0';
				if ena_1khz = '1' then
					ena_cnt_reg <= ena_cnt_reg + 1;
					if ena_cnt_reg = 0 then
						ena_reg <= '1';
					end if;
				end if;
			end if;
		end process;
	end block;

	debounch_blk : block
		signal cursor_up_prev_reg : std_logic := '0';
		signal cursor_down_prev_reg : std_logic := '0';
		signal cursor_left_prev_reg : std_logic := '0';
		signal cursor_right_prev_reg : std_logic := '0';
		signal cursor_enter_prev_reg : std_logic := '0';
		signal cursor_up_trig_reg : std_logic := '0';
		signal cursor_down_trig_reg : std_logic := '0';
		signal cursor_left_trig_reg : std_logic := '0';
		signal cursor_right_trig_reg : std_logic := '0';
		signal cursor_enter_trig_reg : std_logic := '0';
	begin
		cursor_up_trig <= cursor_up_trig_reg;
		cursor_down_trig <= cursor_down_trig_reg;
		cursor_left_trig <= cursor_left_trig_reg;
		cursor_right_trig <= cursor_right_trig_reg;
		cursor_enter_trig <= cursor_enter_trig_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				cursor_up_trig_reg <= '0';
				cursor_down_trig_reg <= '0';
				cursor_left_trig_reg <= '0';
				cursor_right_trig_reg <= '0';
				cursor_enter_trig_reg <= '0';
				if ena_cursor = '1' then
					cursor_up_prev_reg <= cursor_up;
					cursor_down_prev_reg <= cursor_down;
					cursor_left_prev_reg <= cursor_left;
					cursor_right_prev_reg <= cursor_right;
					cursor_enter_prev_reg <= cursor_enter;
					if cursor_up > cursor_up_prev_reg  then
						cursor_up_trig_reg <= '1';
					end if;
					if cursor_down > cursor_down_prev_reg  then
						cursor_down_trig_reg <= '1';
					end if;
					if cursor_left > cursor_left_prev_reg  then
						cursor_left_trig_reg <= '1';
					end if;
					if cursor_right > cursor_right_prev_reg  then
						cursor_right_trig_reg <= '1';
					end if;
					if cursor_enter > cursor_enter_prev_reg  then
						cursor_enter_trig_reg <= '1';
					end if;
				end if;
			end if;
		end process;
	end block;

	menu_blk : block
		signal cursor_row_reg : unsigned(2 downto 0) := (others => '0');
		signal cursor_col_reg : unsigned(3 downto 0) := (others => '0');
	begin
		cursor_row <= cursor_row_reg;
		cursor_col <= cursor_col_reg;

		process(clk)
		begin
			if rising_edge(clk) then
				if (cursor_up_trig = '1') and (cursor_row_reg /= 0) then
					cursor_row_reg <= cursor_row_reg - 1;
				end if;
				if (cursor_down_trig = '1') and (cursor_row_reg /= 7) then
					cursor_row_reg <= cursor_row_reg + 1;
				end if;
				if (cursor_left_trig = '1') and (cursor_col_reg /= 0) then
					cursor_col_reg <= cursor_col_reg - 1;
				end if;
				if (cursor_right_trig = '1') and (cursor_col_reg /= 8) then
					cursor_col_reg <= cursor_col_reg + 1;
				end if;
			end if;
		end process;
	end block;
end architecture;