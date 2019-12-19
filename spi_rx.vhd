library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_rx is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		spi_enable			: in std_logic;
		spi_clock			: in std_logic;
		spi_data			: in std_logic;
		ack_received		: in std_logic;
		data_received		: out std_logic_vector(15 downto 0);
		transfer_complete	: out std_logic
		-- Debug port
		--;debug_spi : out std_logic_vector(3 downto 0)
	);
end entity;

architecture bhv of spi_rx is

	--signal spi_clock_s 			: std_logic := '0';
	--signal spi_clock_rising 	: std_logic := '0';
	--signal bit_counter 			: unsigned(4 downto 0) := (others => '0');
	--signal data_received_s 		: std_logic_vector(15 downto 0) := (others => '0');
	--signal transfer_complete_s 	: std_logic := '0';

	signal transfer_reg 	: std_logic := '0';
	signal data_reg			: std_logic_vector(15 downto 0) := (others => '0');
	signal data_received_s 	: std_logic_vector(15 downto 0) := (others => '0');
	signal bit_counter 		: unsigned(4 downto 0) := (others => '0');
	signal transfer_complete_s, transfer_complete_old_s : std_logic := '0';

	signal transfer_sync_s : unsigned(10 downto 0) := (others => '0');


	signal data_temp : std_logic_vector(16 downto 0) := (others => '0');

	signal init_counter : unsigned(32 downto 0) := (others => '0');
	signal init_reset : std_logic := '1';
	signal reset_s : std_logic;

	signal data_debug : std_logic_vector(15 downto 0) := (others => '0');
begin

	reset_s <= init_reset or reset;
	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (init_counter >= 100000000) then
				init_reset <= '0';
			else
				init_counter <= init_counter + 1;
				init_reset <= '1';
			end if;
		end if;
	end process;


	transfer_complete 	<= transfer_reg;
	data_received 		<= data_reg;--data_debug;--"0000000000100000";--data_reg;

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset_s = '1' or spi_enable = '0') then
				data_reg		<= (others => '0');
				transfer_reg 	<= '0';
				transfer_sync_s	<= (others => '0');
				--transfer_complete_old_s <= '0'; 
			else
			--if (clock = '1' and clock'event) then
				if (ack_received = '1') then 
					transfer_reg <= '0';
				end if;

				--if (data_temp(16) = '1') then
				if (transfer_complete_s = '1') then
					if (transfer_sync_s = 4) then
						--data_reg <= data_temp(15 downto 0);
						data_reg 		<= data_received_s;
						transfer_reg <= '1';


					data_debug <= std_logic_vector( unsigned(data_debug) + 1);
					if (unsigned(data_debug) = 512) then
						data_debug <= (others => '0');
					end if;


					end if;
					if (transfer_sync_s <= 4) then
						transfer_sync_s <= transfer_sync_s + 1;
					end if;
				else
					transfer_sync_s <= to_unsigned(0, transfer_sync_s'length);
				end if;


				--if (transfer_complete_s = '1') then
				--	if (transfer_sync_s = 50) then
				--		data_reg 		<= data_received_s;						
				--		transfer_reg 	<= '1';
				--	end if;
				--	if (transfer_sync_s <= 50) then
				--		transfer_sync_s <= transfer_sync_s + 1;
				--	end if;
				--else 
				--	transfer_sync_s <= (others => '0');
				--end if;


				
				--transfer_complete_old_s <= transfer_complete_s;
				--if (transfer_complete_old_s = '0' and transfer_complete_s = '1') then
				--	transfer_reg <= '1';
				--	data_reg <= data_received_s;
				--end if;
			end if;
		end if;
	end process;


			--debug_spi(1) <= debug_reference_clock;
			
			--debug_spi(1) <= transfer_complete_s;
			--debug_spi(0) <= spi_data;

	process(spi_clock)--, spi_enable, reset)
	begin
		--if (spi_enable = '0' or reset = '1') then
		--	bit_counter 		<= to_unsigned(0, bit_counter'length);
		--	data_received_s		<= (others => '0');
		--	transfer_complete_s <= '0';
		--elsif (spi_clock = '1' and spi_clock'event) then

			--data_temp(16) <= '0';

		if (spi_clock = '1' and spi_clock'event) then
			if (reset_s = '1' or spi_enable = '0') then
				bit_counter 		<= to_unsigned(0, bit_counter'length);
				data_received_s		<= (others => '0');
				transfer_complete_s <= '0';
			else
				transfer_complete_s <= '0';
				bit_counter 		<= bit_counter + 1;
				data_received_s 	<= data_received_s(14 downto 0) & spi_data;

				--debug_spi(1) <= transfer_complete_s;
				
				--debug_spi(0) <= spi_data;
				--debug_reference_clock <= not debug_reference_clock;

				if (bit_counter = 15) then

					--data_temp <= '1' & data_received_s(14 downto 0) & spi_data;

					bit_counter 		<= (others => '0');
					transfer_complete_s	<= '1';
				end if;
			end if;
		end if;
	end process;






	--process(clock, reset)
	--begin
	--	if (reset = '1') then
	--		spi_clock_rising <= '0';
	--		spi_clock_s <= '0';
	--	elsif (clock = '1' and clock'event and spi_enable = '1') then
	--		spi_clock_s <= spi_clock;
	--		if (spi_clock_s = '0' and spi_clock = '1') then
	--			spi_clock_rising <= '1';
	--		else
	--			spi_clock_rising <= '0';
	--		end if;
	--	end if;
	--end process;

	--process(clock, reset)
	--begin
	--	if (reset = '1') then
	--		bit_counter <= (others => '0');
	--		transfer_complete_s <= '0';
	--	elsif (clock = '1' and clock'event) then
	--		if (ack_received = '1') then 
	--			transfer_complete_s	<= '0';
	--		end if;
	--		if (spi_enable = '0') then
	--			bit_counter 		<= to_unsigned(0, bit_counter'length);
	--			data_received_s		<= (others => '0');
	--		elsif (spi_clock_rising = '1') then
	--			bit_counter 		<= bit_counter + 1;
	--			data_received_s 	<= data_received_s(14 downto 0) & spi_data;

	--			--debug_spi <= "000" & spi_data;
	--			debug_spi <= "0" & data_received_s(1 downto 0) & spi_data;
				
	--			if (bit_counter = 15) then
	--				bit_counter 		<= (others => '0');
	--				transfer_complete_s	<= '1';

	--				debug_spi(3) <= '1';
	--				--data_received_s(2 downto 0) & spi_data;

	--			end if;
	--		end if;
	--	end if;
	--end process;

	--data_received <= data_received_s;
	--transfer_complete <= transfer_complete_s;

end architecture;