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
		r_out, g_out, b_out	: out std_logic;
		-- Image buffer interface
		fifo_r_data			: in std_logic_vector(15 downto 0);
		fifo_r_req 			: out std_logic
	);
end entity;

architecture bhv of vga_datapath is
	signal r_s, g_s, b_s : std_logic;
	-- Pixel register signals
	signal pixel_reg, pixel_next : std_logic_vector(15 downto 0) := (others => '0');
	signal pixel_counter_reg, pixel_counter_next : unsigned(3 downto 0) := (others => '0');

	signal zoom_counter_reg : unsigned(3 downto 0) := (others => '0');

	--signal pixel_debug : std_logic_vector(15 downto 0) := "0000000010000000";
begin

	-- Pixel management processes
	process(clock, reset)
	begin
		if (reset = '1') then
			pixel_reg 			<= (others => '0');
			pixel_counter_reg 	<= (others => '0');

			zoom_counter_reg	<= (others => '0');
		
		elsif (clock = '1' and clock'event) then
			fifo_r_req 	<= '0';
			--pixel_reg 	<= fifo_r_data;

			zoom_counter_reg <= zoom_counter_reg + 1;
			if (zoom_counter_reg = 0) then 

-----------------------------
			if (display_enable = '1') then			
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
			end if;
------------------------------

			elsif (zoom_counter_reg = 7) then 
				zoom_counter_reg <= (others => '0');
			end if;

		end if;
	end process;
		
	r_s <= pixel_reg(15);
	g_s <= pixel_reg(15);
	b_s <= pixel_reg(15);-- xor pixel_in(3);

	r_out <= r_s when (display_enable = '1') else '0';
	g_out <= g_s when (display_enable = '1') else '0';
	b_out <= b_s when (display_enable = '1') else '0';

end architecture;
