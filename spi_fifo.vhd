library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_fifo is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		-- Fifo write port  
		fifo_w_req			: in std_logic;
		fifo_w_data			: in std_logic_vector(15 downto 0);
		-- Fifo read port
		--fifo_r_req			: in std_logic;
		--fifo_r_data			: out std_logic_vector(15 downto 0);
		-- Fifo to Memory write port
		mem_write_ready		: in std_logic;
		mem_write_done		: in std_logic;
		mem_write_req		: out std_logic;
		mem_write_address	: out std_logic_vector(23 downto 0);
		mem_write_data		: out std_logic_vector(15 downto 0)
		-- Debug port
		;debug_spi : out std_logic_vector(3 downto 0)
	);
end entity;

architecture bhv of spi_fifo is
	type buffer_type is array(0 to 200) of std_logic_vector(15 downto 0);
	signal buffer_s: buffer_type := (others => (others => '0'));
	signal discharge_buffer_s	: std_logic := '0';
	-- Fifo write signals
	signal first_index_s 		: integer range 0 to 200 := 0;--(8 downto 0) := 0;
	signal last_index_s 		: integer range 0 to 200 := 0;--(8 downto 0) := 0;
	signal element_counter_s 	: unsigned(8 downto 0) := to_unsigned(0, 9);
	-- Fifo read signals
	type state_type is (WAIT_STATE, DISCHARGE_STATE, WRITE_REQ_STATE);
	signal state_reg, state_next: state_type := WAIT_STATE; 
	signal discharge_counter_reg, discharge_counter_next	: unsigned(8 downto 0) := to_unsigned(0, 9);
	signal transfer_counter_reg, transfer_counter_next	: unsigned(8 downto 0) := to_unsigned(0, 9);
	--signal memory_address_s		: unsigned(23 downto 0) := (others => '0');
	signal memory_address_reg, memory_address_next : unsigned(23 downto 0) := (others => '0');
	signal fifo_r_req			: std_logic := '0';
	signal fifo_r_data			: std_logic_vector(15 downto 0);
	signal memory_req_done_s	: std_logic := '0';
	signal mem_write_req_s		: std_logic := '0';
begin

	fifo_r_data <= buffer_s(first_index_s);
	mem_write_address	<= std_logic_vector(memory_address_reg);
	mem_write_data		<= fifo_r_data;
	mem_write_req		<= mem_write_req_s;

	process(clock, reset)
	begin
		if (reset = '1') then
			first_index_s			<= 0;
			last_index_s			<= 0;
			element_counter_s	 	<= to_unsigned(0, element_counter_s'length);
		elsif (clock = '1' and clock'event) then
			-- Fifo loading process
			if (fifo_w_req = '1') then
				buffer_s(last_index_s) <= fifo_w_data;
				last_index_s <= last_index_s + 1;
				element_counter_s <= element_counter_s + 1;
				if (last_index_s = 200) then
					last_index_s <= 0;
				end if;
			end if;
			if (fifo_r_req = '1') then
				element_counter_s <= element_counter_s - 1;
				first_index_s <= first_index_s + 1;
				if (first_index_s = 200) then
					first_index_s <= 0;
				end if;
			end if;
			-- Update element counter
			if (fifo_w_req = '1' and fifo_r_req = '1') then
				element_counter_s <= element_counter_s;
			end if;
		end if;
	end process;

	process(clock, reset)
	begin
		if (reset = '1') then
			state_reg				<= WAIT_STATE;
			transfer_counter_reg	<= (others => '0');
			discharge_counter_reg	<= (others => '0');
			memory_address_reg		<= (others => '0');
		elsif (clock = '1' and clock'event) then
			state_reg				<= state_next;
			transfer_counter_reg	<= transfer_counter_next;
			discharge_counter_reg	<= discharge_counter_next;
			memory_address_reg		<= memory_address_next;
		end if;
	end process;

	process(state_reg, fifo_r_data, element_counter_s, transfer_counter_reg, discharge_counter_reg, mem_write_ready, mem_write_done, memory_address_reg)
	begin
		state_next 				<= state_reg;
		transfer_counter_next	<= transfer_counter_reg;
		discharge_counter_next 	<= discharge_counter_reg;
		memory_address_next		<= memory_address_reg;
		fifo_r_req				<= '0';
		mem_write_req_s			<= '0';
		case state_reg is
		
			when WAIT_STATE =>
				if (element_counter_s >= 128) then -- 5 for debug. 128 for real cases
					state_next <= DISCHARGE_STATE;
				end if;
				if (discharge_counter_reg = 4) then--64) then
					memory_address_next		<= (others => '0');
					discharge_counter_next 	<= (others => '0');
				end if;

			when DISCHARGE_STATE =>
				if (transfer_counter_reg = 128) then--128) then --for debug--128) then 
					discharge_counter_next 	<= discharge_counter_reg + 1;
					transfer_counter_next	<= (others => '0');
					state_next				<= WAIT_STATE;
				elsif (mem_write_ready = '1') then
					mem_write_req_s	<= '1';
					state_next		<= WRITE_REQ_STATE;
					debug_spi <= fifo_r_data(3 downto 0);
				end if;

			when WRITE_REQ_STATE =>
				if (mem_write_done = '1') then
					state_next 				<= DISCHARGE_STATE;
					transfer_counter_next 	<= transfer_counter_reg + 1;
					fifo_r_req				<= '1';
					memory_address_next	 	<= memory_address_reg + 1;
				end if;

		end case;
	end process;


	--	if (reset = '1') then
	--		discharge_counter_s		<= to_unsigned(0, discharge_counter_s'length);
	--		transfer_counter_s 		<= to_unsigned(0, transfer_counter_s'length);
	--		memory_address_s		<= to_unsigned(0, memory_address_s'length);
	--		fifo_r_req				<= '0';
	--		memory_req_done_s		<= '0';
	--		mem_write_req_s			<= '0';
	--	elsif (clock = '1' and clock'event) then
	--		-- Fifo discharging process
	--		if (element_counter_s = 5) then -- 5 for debug. 128 for real cases
	--			discharge_buffer_s <= '1';
	--		end if;
	--		if (discharge_counter_s = 3) then--64) then
	--			memory_address_s 	<= (others => '0');
	--			discharge_counter_s <= (others => '0');
	--		end if;
	--		if (discharge_buffer_s = '1') then
	--			if (memory_req_done_s = '1') then
	--				mem_write_req_s <= '0';
	--				if (mem_write_done = '1') then
	--					fifo_r_req			<= '1';
	--					memory_address_s 	<= memory_address_s + 1;
	--					memory_req_done_s 	<= '0';
	--					if (transfer_counter_s = 4) then --for debug--127) then 
	--						discharge_buffer_s 	<= '0';
	--						transfer_counter_s 	<= (others => '0');
	--						discharge_counter_s <= discharge_counter_s + 1;
	--					end if;
	--					transfer_counter_s <= transfer_counter_s + 1;
	--				end if;
	--			else
	--				if (mem_write_ready = '1') then
	--					mem_write_req_s		<= '1';
	--					memory_req_done_s	<= '1';
	--				end if;
	--			end if;
	--		end if;
	--	end if;
	--end process;

end architecture;