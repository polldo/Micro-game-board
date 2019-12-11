library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_mem is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		spi_enable			: in std_logic;
		spi_clock			: in std_logic;
		spi_data			: in std_logic;
		mem_write_ready		: in std_logic;
		mem_write_done		: in std_logic;
		mem_write_req		: out std_logic;
		mem_write_address	: out std_logic_vector(23 downto 0);
		mem_write_data		: out std_logic_vector(15 downto 0)
				;debug_spi : out std_logic_vector(3 downto 0)
	);
end entity;

architecture bhv of spi_mem is
	-- Spi receiver signals
	signal transfer_reg 	: std_logic := '0';
	signal data_reg			: std_logic_vector(15 downto 0) := (others => '0');
	signal data_received_s 	: std_logic_vector(15 downto 0) := (others => '0');
	signal bit_counter 		: unsigned(4 downto 0) := (others => '0');
	signal transfer_complete_s : std_logic := '0';
	--signal transfer_complete_old_s : std_logic := '0';
	-- Spi controller signals
	type state_type is (WRITE_STATE, WRITE_WAIT_STATE);
	signal state_reg, state_next : state_type := WRITE_STATE;
	signal ack_received : std_logic := '0';
	signal write_address_reg, write_address_next : std_logic_vector(23 downto 0) := (others => '0');
	signal write_counter_reg, write_counter_next : unsigned(3 downto 0) := to_unsigned(0, 4);

	signal debug_reference_clock: std_logic := '0';
	signal transfer_sync_s : unsigned(4 downto 0) := (others => '0');

begin

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			state_reg <= state_next;
			write_address_reg <= write_address_next;
			write_counter_reg <= write_counter_next;
		end if;
	end process;
	process(state_reg, mem_write_ready, transfer_reg, data_reg, write_address_reg, write_counter_reg, mem_write_done)
	begin
		mem_write_req <= '0';
		ack_received <= '0';
		state_next <= state_reg;
		write_address_next <= write_address_reg;
		write_counter_next <= write_counter_reg;

				debug_spi(3) <= '0';

		case state_reg is
		-- write a specific memory location
		when WRITE_STATE =>
			if (mem_write_ready = '1' and transfer_reg = '1') then
				mem_write_req 			<= '1';
				mem_write_address 		<= write_address_reg;
				mem_write_data 			<= data_reg;
				state_next	 			<= WRITE_WAIT_STATE;
				ack_received			<= '1';

				debug_spi(2 downto 0) <= data_reg(2 downto 0);
				debug_spi(3) <= '1';

			end if; 
		
		when WRITE_WAIT_STATE =>
			if (mem_write_done = '1') then
				state_next <= WRITE_STATE;
				write_address_next	<= std_logic_vector( unsigned(write_address_reg) + 1);
				write_counter_next	<= write_counter_reg + 1;
				if (write_counter_reg = 7) then 
					write_counter_next <= (others => '0');
					write_address_next <= (others => '0');
				end if;
			end if;
		end case;
	end process;
	
	process(clock, reset)
	begin
		if (reset = '1') then
			data_reg		<= (others => '0');
			transfer_reg 	<= '0';
			transfer_sync_s	<= (others => '0');
			--transfer_complete_old_s <= '0'; 
		elsif (clock = '1' and clock'event) then
		--if (clock = '1' and clock'event) then
			if (ack_received = '1') then 
				transfer_reg <= '0';
			end if;

			if (transfer_complete_s = '1') then
				if (transfer_sync_s = 10) then
					data_reg 		<= data_received_s;						
					transfer_reg 	<= '1';
				end if;
				if (transfer_sync_s <= 10) then
					transfer_sync_s <= transfer_sync_s + 1;
				end if;
			else 
				transfer_sync_s <= (others => '0');
			end if;
			
			--transfer_complete_old_s <= transfer_complete_s;
			--if (transfer_complete_old_s = '0' and transfer_complete_s = '1') then
			--	transfer_reg <= '1';
			--	data_reg <= data_received_s;
			--end if;
		end if;
	end process;


			--debug_spi(1) <= debug_reference_clock;
			
			--debug_spi(1) <= transfer_complete_s;
			--debug_spi(0) <= spi_data;

	process(spi_clock, spi_enable)
	begin
		if (spi_enable = '0' or reset = '1') then
			bit_counter 		<= to_unsigned(0, bit_counter'length);
			data_received_s		<= (others => '0');
			transfer_complete_s <= '0';
		elsif (spi_clock = '1' and spi_clock'event) then
		--if (spi_clock = '1' and spi_clock'event) then
			transfer_complete_s <= '0';
			bit_counter 		<= bit_counter + 1;
			data_received_s 	<= data_received_s(14 downto 0) & spi_data;

			--debug_spi(1) <= transfer_complete_s;
			
			--debug_spi(0) <= spi_data;
			--debug_reference_clock <= not debug_reference_clock;

			if (bit_counter = 15) then
				bit_counter 		<= (others => '0');
				transfer_complete_s	<= '1';
			end if;
		end if;
	end process;

end architecture;