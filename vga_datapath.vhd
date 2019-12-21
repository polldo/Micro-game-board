library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_datapath is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		-- Vga interface
		display_enable		: in std_logic;
		r_out, g_out, b_out	: out std_logic_vector(2 downto 0);
		-- Image buffer interface
		fifo_r_data			: in std_logic_vector(15 downto 0);
		fifo_r_req 			: out std_logic
	);
end entity;

architecture bhv of vga_datapath is
	signal r_s, g_s, b_s : std_logic_vector(2 downto 0);
	signal color_vector : std_logic_vector(2 downto 0);
	signal color_counter : unsigned(8 downto 0);
	-- Pixel register signals
	signal pixel_reg, pixel_next : std_logic_vector(15 downto 0) := (others => '0');
	signal pixel_counter_reg, pixel_counter_next : unsigned(3 downto 0) := (others => '0');

	signal zoom_counter_reg : unsigned(3 downto 0) := (others => '0');

	signal display_enable_reg : std_logic := '0';

	--signal pixel_debug : std_logic_vector(15 downto 0) := "0000000010000000";
begin

	-- Pixel management processes
	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset = '1') then
				pixel_reg 			<= (others => '0');
				pixel_counter_reg 	<= (others => '0');

				zoom_counter_reg	<= (others => '0');
			else
				display_enable_reg <= display_enable;

				fifo_r_req 	<= '0';
				--pixel_reg 	<= fifo_r_data;

				if (display_enable = '1') then			
					

					zoom_counter_reg <= zoom_counter_reg + 1;
					if (zoom_counter_reg = 0) then 

	-----------------------------
						pixel_counter_reg 	<= pixel_counter_reg + 1;
						if (pixel_counter_reg = 0) then
							pixel_reg 			<= fifo_r_data;
							fifo_r_req 	 		<= '1';
						elsif (pixel_counter_reg = 15) then
							pixel_counter_reg 	<= (others => '0');
							pixel_reg 			<= pixel_reg(14 downto 0) & '0';
						else
							pixel_reg 			<= pixel_reg(14 downto 0) & '0';
						end if;
	------------------------------

					elsif (zoom_counter_reg = 7) then 
						zoom_counter_reg <= (others => '0');
					end if;

				else
					zoom_counter_reg 	<= (others => '0');
					pixel_reg 			<= (others => '0');
					pixel_counter_reg 	<= (others => '0');
				end if;
			end if;
		end if;
	end process;

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (display_enable_reg = '1' and display_enable = '0' ) then
				if (color_counter = 8) then
					color_counter <= to_unsigned(1, color_counter'length);
				else
					color_counter <= color_counter + 1;
				end if;
			end if;
		end if;
	end process;
	color_vector <= std_logic_vector(color_counter(2 downto 0));
		
	r_s <= color_vector when pixel_reg(15) = '1' else "000";
	g_s <= color_vector when pixel_reg(15) = '1' else "000";
	b_s <= color_vector when pixel_reg(15) = '1' else "000";

	r_out <= r_s when (display_enable_reg = '1') else "000";
	g_out <= g_s when (display_enable_reg = '1') else "000";
	b_out <= b_s when (display_enable_reg = '1') else "000";

end architecture;
