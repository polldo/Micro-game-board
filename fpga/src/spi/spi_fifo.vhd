--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--	Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

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
		-- Fifo to Memory write port
		mem_write_ready		: in std_logic;
		mem_write_done		: in std_logic;
		mem_write_req		: out std_logic;
		mem_write_address	: out std_logic_vector(23 downto 0);
		mem_write_data		: out std_logic_vector(15 downto 0)
	);
end entity;

architecture bhv of spi_fifo is
	-- at least double of 128 (discharging time <= recharging time)
	type buffer_type is array(0 to 150) of std_logic_vector(15 downto 0); 
	signal buffer_s: buffer_type := (others => (others => '0'));
	signal discharge_buffer_s	: std_logic := '0';
	-- Fifo write signals
	signal first_index_s 		: integer range 0 to 150 := 0;
	signal last_index_s 		: integer range 0 to 150 := 0;
	signal element_counter_s 	: unsigned(9 downto 0) := to_unsigned(0, 10);
	-- Fifo read signals
	type state_type is (WAIT_STATE, INIT_STATE, PREPARATION_STATE, ELABORATION_STATE, DISCHARGE_STATE, WRITE_REQ_STATE, WRITE_WAIT);
	signal state_reg, state_next: state_type := WAIT_STATE; 
	signal discharge_counter_reg, discharge_counter_next	: unsigned(8 downto 0) := to_unsigned(0, 9);
	signal tot_discharge_counter_reg, tot_discharge_counter_next : unsigned(8 downto 0) := to_unsigned(0, 9);
	signal transfer_counter_reg, transfer_counter_next	: unsigned(8 downto 0) := to_unsigned(0, 9);
	--signal memory_address_s		: unsigned(23 downto 0) := (others => '0');
	signal memory_address_reg, memory_address_next : unsigned(23 downto 0) := (others => '0');
	signal fifo_r_req			: std_logic := '0';
	signal fifo_r_data			: std_logic_vector(15 downto 0);
	signal memory_req_done_s	: std_logic := '0';
	signal mem_write_req_s		: std_logic := '0';


	type prep_buffer_type is array(0 to 20) of std_logic_vector(7 downto 0);
	type elab_buffer_type is array(0 to 20) of std_logic_vector(15 downto 0);
	signal preparation_buffer_reg, preparation_buffer_next	 : prep_buffer_type		:= (others => (others => '0'));
	signal elaboration_buffer_reg, elaboration_buffer_next	 : elab_buffer_type 	:= (others => (others => '0'));
	signal preparation_counter_reg, preparation_counter_next : unsigned(4 downto 0) := (others => '0');

	signal init_state_counter_reg, init_state_counter_next : unsigned(4 downto 0) := (others => '0');

begin

	fifo_r_data <= buffer_s(first_index_s);
	mem_write_req		<= mem_write_req_s;

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset = '1') then
				first_index_s			<= 0;
				last_index_s			<= 0;
				element_counter_s	 	<= to_unsigned(0, element_counter_s'length);
			else
				-- Fifo loading process
				if (fifo_w_req = '1') then
					buffer_s(last_index_s) <= fifo_w_data;
					last_index_s <= last_index_s + 1;
					element_counter_s <= element_counter_s + 1;
					if (last_index_s = 150) then 
						last_index_s <= 0;
					end if;
				end if;
				if (fifo_r_req = '1') then
					element_counter_s <= element_counter_s - 1;
					first_index_s <= first_index_s + 1;
					if (first_index_s = 150) then 
						first_index_s <= 0;
					end if;
				end if;
				-- Update element counter
				if (fifo_w_req = '1' and fifo_r_req = '1') then
					element_counter_s <= element_counter_s;
				end if;
			end if;
		end if;
	end process;

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset = '1') then
				state_reg				<= WAIT_STATE;
				transfer_counter_reg	<= (others => '0');
				discharge_counter_reg	<= (others => '0');
				memory_address_reg		<= (others => '0');
				preparation_counter_reg <= (others => '0');
				
				elaboration_buffer_reg	<= (others => (others => '0'));
				preparation_buffer_reg	<= (others => (others => '0'));
				tot_discharge_counter_reg <= (others => '0');

				init_state_counter_reg	<= (others => '0');
			else
				state_reg				<= state_next;
				transfer_counter_reg	<= transfer_counter_next;
				discharge_counter_reg	<= discharge_counter_next;
				memory_address_reg		<= memory_address_next;
				preparation_counter_reg <= preparation_counter_next;

				elaboration_buffer_reg	<= elaboration_buffer_next;
				preparation_buffer_reg	<= preparation_buffer_next;			
				tot_discharge_counter_reg <= tot_discharge_counter_next;

				init_state_counter_reg	<= init_state_counter_next;
			end if;
		end if;
	end process;

	process(state_reg, fifo_r_data, element_counter_s, transfer_counter_reg, discharge_counter_reg, mem_write_ready, mem_write_done, 
			memory_address_reg, preparation_counter_reg, preparation_buffer_reg, elaboration_buffer_reg, tot_discharge_counter_reg, init_state_counter_reg)
	begin
		state_next 					<= state_reg;
		transfer_counter_next		<= transfer_counter_reg;
		discharge_counter_next 		<= discharge_counter_reg;
		memory_address_next			<= memory_address_reg;
		preparation_counter_next 	<= preparation_counter_reg;
		fifo_r_req					<= '0';
		mem_write_req_s				<= '0';

		elaboration_buffer_next		<= elaboration_buffer_reg;
		preparation_buffer_next		<= preparation_buffer_reg;
		tot_discharge_counter_next	<= tot_discharge_counter_reg;
		
		init_state_counter_next		<= init_state_counter_reg;

		case state_reg is
		
			when WAIT_STATE =>
				if (element_counter_s >= 8) then 
					state_next <= INIT_STATE;
				end if;

			when INIT_STATE => 
				if (init_state_counter_reg = 1) then
					state_next <= WAIT_STATE;
					init_state_counter_next <= (others => '0');
				else
					state_next <= PREPARATION_STATE;
					init_state_counter_next <= init_state_counter_reg + 1;
				end if;
				if (discharge_counter_reg = 8) then--64) then
					discharge_counter_next 	<= (others => '0');
					if (tot_discharge_counter_reg = 7) then
						memory_address_next		<= (others => '0');
						tot_discharge_counter_next <= (others => '0');
					else
						tot_discharge_counter_next <= tot_discharge_counter_reg + 1;
						memory_address_next		<= memory_address_reg - 8 + 64; --8 x 8 x tot_index--std_logic_vector( ( unsigned(memory_address_reg) + 1) * 8 );
					end if;
				end if;

			when PREPARATION_STATE => 
				if (preparation_counter_reg = 8) then
					preparation_counter_next <= (others => '0');
					state_next <= ELABORATION_STATE;
				else
					preparation_counter_next <= preparation_counter_reg + 1;
					preparation_buffer_next( to_integer( preparation_counter_reg * 2 ) ) 		<= 	fifo_r_data(15 downto 8);
					preparation_buffer_next( to_integer( preparation_counter_reg * 2 + 1 ) ) 	<= fifo_r_data(7 downto 0);
					fifo_r_req <= '1';
				end if;

			when ELABORATION_STATE => 
				state_next <= DISCHARGE_STATE;
				for I in 0 to 15 loop
					for J in 0 to 7 loop
						elaboration_buffer_next(J)(15 - I) <= preparation_buffer_reg(I)(J);
					end loop;
				end loop;

			when DISCHARGE_STATE =>
				if (transfer_counter_reg = 8) then--128) then --for debug--128) then 
					discharge_counter_next 	<= discharge_counter_reg + 1;
					transfer_counter_next	<= (others => '0');
					state_next				<= INIT_STATE;--WAIT_STATE;
					memory_address_next 	<= memory_address_reg + 1;		
				elsif (mem_write_ready = '1') then
					mem_write_req_s		<= '1';
					mem_write_address	<= std_logic_vector( unsigned(memory_address_reg) + (transfer_counter_reg * 8) ); 
					mem_write_data		<= elaboration_buffer_reg( to_integer(transfer_counter_reg) );
					state_next			<= WRITE_WAIT;--WRITE_REQ_STATE;
				end if;

			when WRITE_WAIT => 
				state_next <= WRITE_REQ_STATE;

			when WRITE_REQ_STATE =>
				if (mem_write_done = '1') then
					state_next 				<= DISCHARGE_STATE;
					transfer_counter_next 	<= transfer_counter_reg + 1;
					--fifo_r_req				<= '1';
					--memory_address_next	 	<= memory_address_reg + 1;
				end if;

		end case;
	end process;

end architecture;