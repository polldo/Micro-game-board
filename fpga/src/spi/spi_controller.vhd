--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--	Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_controller is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		-- Spi port
		data_received		: in std_logic_vector(15 downto 0);
		transfer_complete	: in std_logic;
		-- Fifo port
		fifo_w_req			: out std_logic;
		fifo_w_data			: out std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of spi_controller is

	-- CONTROLLER control logic
	type state_type is (FETCH_STATE, DECODE_STATE, --CONFIG_FETCH_STATE, CONFIG_WRITE_STATE,  
						IMAGE_FETCH_STATE, IMAGE_WRITE_STATE);
	signal state_reg, state_next: state_type := FETCH_STATE; 
	signal fifo_w_req_s 							: std_logic := '0';
	signal fifo_w_data_s 							: std_logic_vector(15 downto 0) := (others => '0');
	signal cmd_reg, cmd_next 						: std_logic_vector(15 downto 0);
	signal image_counter_reg, image_counter_next	: unsigned(15 downto 0) := (others => '0');

--	-- Configuration memory   NOT implemented yet
--	constant HORIZ_SIZE_REG		: integer := 0;
--	constant VERT_SIZE_REG		: integer := 0;
--	constant HORIZ_OFFSET_REG	: integer := 0;
--	constant HORIZ_OFFSET_REG	: integer := 0;
--	constant ZOOM_LEVEL_REG		: integer := 0;
--	type config_memory_type is array(0 to 4) of std_logic_vector(15 downto 0);
--	signal config_memory: config_memory_type := 
--	(
--		std_logic_vector( to_unsigned (128, 16) ),
--		std_logic_vector( to_unsigned (64, 16) ),  
--		std_logic_vector( to_unsigned (100, 16) ),
--		std_logic_vector( to_unsigned (0, 16) )
--	);
--
--	signal image_size 	: std_logic_vector(15 downto 0);
--	signal zoom_factor 	: std_logic_vector(7 downto 0);
--	signal pixel_buffer	: std_logic_vector(15 downto 0);

	-- fsm states: idle, decode, receive, end transaction
	--signal byte_counter : unsigned(15 downto 0);

begin

	fifo_w_req 		<= fifo_w_req_s;
	fifo_w_data 	<= fifo_w_data_s;

	process(clock)
	begin
		if (clock = '1' and clock'event) then		
			if (reset = '1') then
				state_reg 			<= FETCH_STATE;
				cmd_reg				<= (others => '0');
				image_counter_reg	<= (others => '0');
			else
				state_reg			<= state_next;
				cmd_reg				<= cmd_next;
				image_counter_reg	<= image_counter_next;
			end if;
		end if;
	end process;

	process(state_reg, cmd_reg, data_received, transfer_complete, image_counter_reg)
	begin
		state_next			<= state_reg;
		cmd_next 			<= cmd_reg;
		image_counter_next	<= image_counter_reg;
		fifo_w_req_s 		<= '0';
		fifo_w_data_s		<= (others => '0');
		case state_reg is

			when FETCH_STATE => 
				if (transfer_complete = '1') then
					cmd_next 	<= data_received;
					state_next 	<= DECODE_STATE;
				end if;

			-- This will be useful when a configuration memory will be implemented
			when DECODE_STATE => 
				if (cmd_reg = "0000000000000001") then
					state_next <= IMAGE_FETCH_STATE;
				else
					state_next <= IMAGE_FETCH_STATE;
				end if;

			when IMAGE_FETCH_STATE => 
				if (transfer_complete = '1') then
					fifo_w_req_s		<= '1';
					fifo_w_data_s		<= data_received;
					state_next 			<= IMAGE_WRITE_STATE;
					image_counter_next 	<= image_counter_reg + 1;
				end if;

			when IMAGE_WRITE_STATE => 
				if (image_counter_reg = 512) then
					state_next <= FETCH_STATE;
					image_counter_next <= (others => '0');
				else
					state_next <= IMAGE_FETCH_STATE;
				end if;

		end case;
	end process;

end architecture;