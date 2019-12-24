--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--	Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_controller is
	port
	(
		clock 		 		: in 	std_logic;
		new_pixel, new_page : in 	std_logic;
		read_data			: in 	std_logic_vector(7 downto 0);
		read_address		: out	integer range 0 to 80000;--std_logic_vector(31 downto 0); 	 	
		pixel_out			: out 	std_logic_vector(3 downto 0)
	);
end entity;

architecture bhv of display_controller is
	--type buff is array(0 to 799) of std_logic_vector(3 downto 0);
	type buff is array(0 to 2000) of std_logic_vector(3 downto 0);
	signal display_buff 	: buff;
	signal first_index 		: integer range 0 to 799 := 0;
	signal last_index 		: integer range 0 to 799 := 0;
	signal read_index 		: integer range 0 to 799 := 0;
	signal full, empty		: std_logic;
	signal img_address		: integer range 0 to 80000 := 0;
	signal img_offset	 	: integer range 0 to 799 := 0;
	signal read_request		: std_logic := '0';

	signal new_page_s		: std_logic_vector(1 downto 0);
begin
	
	--full	<= (last_index >= first_index - 2 and last_index <= first_index - 1);
	--empty	<= (first_index = last_index); 
	process(last_index, first_index)
	begin
		if (last_index >= first_index - 2 and last_index <= first_index - 1) then
			full <= '1';
		else	
			full <= '0';
		end if;
		if (first_index = last_index) then
			empty <= '1';
		else
			empty <= '0';
		end if;
	end process;

	pixel_out <= display_buff(first_index);
	
	process(clock, new_page)
	begin
		if (clock = '1' and clock'event) then
			-- READ RAM REQUEST. If the buffer is not full, it is filled with ram contents.
			if (full = '0') then
				--read_address	<= std_logic_vector(to_unsigned(img_address + img_offset, 32));
				--read_address	<= std_logic_vector(to_unsigned(img_address, 32));
				read_address	<= img_address + img_offset;
				img_offset	 	<= img_offset + 1;
				if (last_index >= 799 - 1) then
					last_index 	<= 0;
				else
					last_index	<= last_index + 2;
				end if;
				read_request	<= '1';
			else
				read_request	<= '0';
			end if;
			-- READ RAM PROCESS. Read ram content if in the previous cycle there was a read memory request.
			if (read_request = '1') then
				display_buff(read_index)		<= read_data(7 downto 4);
				display_buff(read_index + 1)	<= read_data(3 downto 0);
				if (read_index >= 799 - 1) then
					read_index 	<= 0;
				else
					read_index	<= read_index + 2;
				end if;
			end if;
			-- PIXEL OUT
			if (new_pixel = '1') then
				first_index <= first_index + 1;
			end if;

			-- REFRESH PAGE
			new_page_s(1) <= new_page_s(0);
			new_page_s(0) <= new_page;
			if (new_page_s(0) = '1' and new_page_s(1) = '0') then
				img_offset 		<= 0;
				last_index	 	<= first_index;
				read_index 		<= first_index;
				read_request 	<= '0';
			end if;
		end if;
	end process;

end architecture;