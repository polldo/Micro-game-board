library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_controller is
	port    
	(
		clock				: in std_logic;
		reset 				: in std_logic;
		-- Read port
		read_req			: in std_logic;
		read_address		: in std_logic_vector(23 downto 0);
		read_length			: in std_logic_vector(8 downto 0);
		read_data			: out std_logic_vector(15 downto 0);
		read_ready			: out std_logic;
		read_data_valid		: out std_logic;
		-- Write port
		write_req			: in std_logic;
		write_address		: in std_logic_vector(23 downto 0);
		write_data			: in std_logic_vector(15 downto 0);
		write_ready			: out std_logic;
		write_done			: out std_logic;
		-- Sdram port
		sdram_data			: inout std_logic_vector(15 downto 0);
		sdram_bank			: out std_logic_vector(1 downto 0);
		sdram_address		: out std_logic_vector(12 downto 0);
		sdram_cke			: out std_logic;
		sdram_cs_n 			: out std_logic;
		sdram_ras_n			: out std_logic;
		sdram_cas_n 		: out std_logic;
		sdram_we_n 			: out std_logic
	);
end entity;

architecture bhv of memory_controller is
	-- CONTROLLER control logic
	type state_type is (IDLE_STATE, REFRESH_STATE, REF_WAIT_STATE, ACTIVE_STATE, ACTIVE_NOP_STATE, 
						WRITE_STATE, READ_STATE, WRITE_NOP_STATE, READ_NOP_STATE, PRECHARGE_STATE);
	signal state_reg, state_next: state_type := IDLE_STATE; 
	-- Commands needed by the SDRAM: cke, cs_n, ras_n, cas_n, we_n.
	constant CMD_NOP		        	: std_logic_vector(4 downto 0) := "10111";
	constant CMD_MODE_REGISTER_SET		: std_logic_vector(4 downto 0) := "10000";
	constant CMD_ACTIVE   				: std_logic_vector(4 downto 0) := "10011";
	constant CMD_READ       			: std_logic_vector(4 downto 0) := "10101";
	constant CMD_WRITE      			: std_logic_vector(4 downto 0) := "10100";
	constant CMD_PRECHARGE  			: std_logic_vector(4 downto 0) := "10010";
	constant CMD_REFRESH    			: std_logic_vector(4 downto 0) := "10001";
	-- Sdram registered in/out
	signal bank_reg, 	bank_next 		: std_logic_vector(1 downto 0);
	signal address_reg, address_next 	: std_logic_vector(12 downto 0);
	signal cmd_reg, 	cmd_next		: std_logic_vector(4 downto 0);
	-- Read request buffer -- this signals must remain stable during the operation
	signal r_buff_req_reg, 		r_buff_req_next 	: std_logic := '0';
	signal r_data_reg, 			r_data_next 		: std_logic_vector(15 downto 0);
	signal r_ready_reg,		 	r_ready_next 		: std_logic := '0';
	signal r_length_reg, 		r_length_next		: unsigned(8 downto 0);
	signal r_data_valid_reg, 	r_data_valid_next 	: std_logic := '0';
	-- Write request buffer -- this signals must remain stable during the operation
	signal w_buff_req_reg, 	w_buff_req_next 	: std_logic := '0';
	signal w_ready_reg, 	w_ready_next 		: std_logic := '0';
	signal w_done_reg, 		w_done_next		 	: std_logic := '0';
	signal w_data_reg,		w_data_next			: std_logic_vector(15 downto 0);
	signal w_output_en_reg, w_output_en_next 	: std_logic := '0';
	-- Sdram support signals and registers
	type sdram_operation is (NOP_OP, READ_OP, WRITE_OP);
	signal current_operation_reg, current_operation_next: sdram_operation := NOP_OP;
	signal address_buff_reg, address_buff_next : std_logic_vector(23 downto 0);
	signal addr_row_s	: std_logic_vector(12 downto 0);
	signal addr_col_s	: std_logic_vector(8 downto 0);
	signal addr_bank_s	: std_logic_vector(1 downto 0);
	-- Timers needed by FSM states
	signal timer_ref_reg, 	timer_ref_next 		: unsigned(3 downto 0);
	signal timer_write_reg, timer_write_next 	: std_logic; --unsigned(1 downto 0); 
	signal timer_read_reg, 	timer_read_next		: std_logic; --unsigned(1 downto 0);
	signal cas_counter_reg, cas_counter_next	: unsigned(2 downto 0);
	signal ref_counter_reg, ref_counter_next	: unsigned(15 downto 0) := to_unsigned(0, 16);
	-- Init FSM signals
	type init_state_type is (INIT_WAIT_STATE, INIT_PRECHARGE_STATE, INIT_REFRESH_STATE,
							 INIT_SET_MODE_STATE, INIT_DONE_STATE);
	signal init_state_reg, init_state_next	: init_state_type; 
	signal init_cmd_reg, init_cmd_next			: std_logic_vector(4 downto 0);
	signal init_addr_reg, init_addr_next 		: std_logic_vector(12 downto 0);
	signal init_counter_reg, init_counter_next 	: unsigned(15 downto 0);
	signal init_done_reg, init_done_next		: std_logic := '0';
begin

	--internal port assignment
	read_data 		<= r_data_reg;
	read_ready		<= r_ready_reg;
	read_data_valid	<= r_data_valid_reg;
	write_ready		<= w_ready_reg; 
	write_done		<= w_done_reg;
	--sdram port assignment
	sdram_data		<= w_data_reg when w_output_en_reg = '1' else (others => 'Z');
	sdram_bank		<= bank_reg;
	sdram_address	<= address_reg;
	sdram_cke		<= cmd_reg(4);
	sdram_cs_n 		<= cmd_reg(3);
	sdram_ras_n		<= cmd_reg(2);
	sdram_cas_n 	<= cmd_reg(1);
	sdram_we_n 		<= cmd_reg(0);
	-- address assignment
	addr_bank_s	<= address_buff_reg(23 downto 22);
	addr_row_s	<= address_buff_reg(21 downto 9); 
	addr_col_s	<= address_buff_reg(8 downto 0);

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset = '1') then
				-- Reset registers' state
				state_reg				<= IDLE_STATE;
				bank_reg				<= (others => 'Z');
				address_reg 			<= (others => 'Z');
				cmd_reg					<= (others => 'Z'); -- could be a problem
				r_data_reg				<= (others => 'Z');
				r_buff_req_reg			<= '0';
				r_ready_reg				<= '0';	--problem
				r_data_valid_reg 		<= '0';
				r_length_reg     		<= (others => 'Z');
				w_data_reg				<= (others => 'Z');
				w_output_en_reg			<= '0';
				w_buff_req_reg			<= '0';
				w_ready_reg				<= '0'; 	--problem
				w_done_reg 				<= '0';
				current_operation_reg 	<= NOP_OP;
				address_buff_reg		<= (others => 'Z');
				timer_ref_reg      		<= to_unsigned(0, timer_ref_next'length);
				timer_write_reg     	<= '0';
				timer_read_reg      	<= '0';
				cas_counter_reg			<= to_unsigned(0, cas_counter_reg'length);
				ref_counter_reg			<= to_unsigned(0, ref_counter_reg'length);
				init_state_reg			<= INIT_WAIT_STATE;
				init_cmd_reg			<= (others => 'Z');
				init_addr_reg			<= (others => '1');
				init_counter_reg		<= to_unsigned(0, init_counter_reg'length);
				init_done_reg			<= '0';
			else
				-- Central FSM Registers update
				state_reg				<= state_next;
				bank_reg				<= bank_next;
				address_reg 			<= address_next;
				cmd_reg					<= cmd_next;
				r_buff_req_reg			<= r_buff_req_next;
				r_data_reg				<= r_data_next;
				r_ready_reg				<= r_ready_next;
				r_data_valid_reg 		<= r_data_valid_next;
				r_length_reg     		<= r_length_next;
				w_buff_req_reg			<= w_buff_req_next;
				w_ready_reg				<= w_ready_next;
				w_done_reg				<= w_done_next;
				w_data_reg				<= w_data_next;
				w_output_en_reg			<= w_output_en_next;
				current_operation_reg	<= current_operation_next;
				address_buff_reg		<= address_buff_next;
				timer_ref_reg      		<= timer_ref_next;
				timer_write_reg     	<= timer_write_next;
				timer_read_reg      	<= timer_read_next;
				cas_counter_reg			<= cas_counter_next;
				ref_counter_reg			<= ref_counter_next;
				-- Init FSM Registers update
				init_state_reg			<= init_state_next;
				init_cmd_reg			<= init_cmd_next;
				init_addr_reg			<= init_addr_next;
				init_counter_reg		<= init_counter_next;
				init_done_reg			<= init_done_next;
			end if;
		end if;
	end process;

	-- Init FSM
	process(init_state_reg, init_cmd_reg, init_addr_reg, init_counter_reg, init_done_reg)
	begin
		init_state_next 	<= init_state_reg;
		init_cmd_next		<= init_cmd_reg;
		init_addr_next		<= init_addr_reg;
		init_counter_next 	<= to_unsigned(0, init_counter_next'length);
		init_done_next 		<= init_done_reg;
		case init_state_reg is

		when INIT_WAIT_STATE =>
			init_state_next		<= INIT_WAIT_STATE;
			init_cmd_next		<= CMD_NOP;
			init_counter_next	<= init_counter_reg + 1;
			if (init_counter_reg >= 20000) then--5000) then --10000) then
				init_state_next		<= INIT_PRECHARGE_STATE;
				init_counter_next	<= to_unsigned(0, init_counter_next'length);
			end if;

		when INIT_PRECHARGE_STATE =>
			init_state_next		<= INIT_PRECHARGE_STATE;
			init_cmd_next		<= CMD_PRECHARGE;
			init_counter_next	<= init_counter_reg + 1;
			init_addr_next		<= (others => '1');
			if (init_counter_reg = 1) then
				init_state_next		<= INIT_REFRESH_STATE;
				init_cmd_next		<= CMD_NOP;
				init_counter_next	<= to_unsigned(0, init_counter_next'length);
			end if;

		when INIT_REFRESH_STATE =>
			init_state_next		<= INIT_REFRESH_STATE;
			init_cmd_next		<= CMD_REFRESH;
			init_counter_next	<= init_counter_reg + 1;
			if (init_counter_reg /= 0 and init_counter_reg /= 4) then
				init_cmd_next		<= CMD_NOP;
				if (init_counter_reg = 7) then
					init_state_next		<= INIT_SET_MODE_STATE;
					init_counter_next	<= to_unsigned(0, init_counter_next'length);
				end if;
			end if;

		when INIT_SET_MODE_STATE =>
			init_state_next		<= INIT_SET_MODE_STATE;
			init_cmd_next		<= CMD_MODE_REGISTER_SET;
			init_addr_next		<= "000" & "0" & "00" & "010" & "0" & "000";
			init_counter_next	<= init_counter_reg + 1;
			if (init_counter_reg > 0) then
				init_cmd_next	<= CMD_NOP;
				if (init_counter_reg = 4) then
					init_state_next	<= INIT_DONE_STATE;
				end if;
			end if;

		when INIT_DONE_STATE =>
			init_state_next	<= INIT_DONE_STATE;
			init_done_next	<= '1';

		end case;
	end process;

	-- FSM
	process(state_reg, bank_reg, address_reg, cmd_reg, r_buff_req_reg, r_data_reg, r_ready_reg, r_data_valid_reg,
				read_length, r_length_reg, w_buff_req_reg, w_ready_reg, w_done_reg, w_data_reg, w_output_en_reg, address_buff_reg, ref_counter_reg,
				init_done_next, init_done_reg, --problem?
				write_req, read_req, write_data, write_address, read_address,
				init_cmd_next, init_addr_next, timer_ref_reg,
				addr_row_s, addr_col_s, addr_bank_s,
				current_operation_reg, timer_write_reg, cas_counter_reg,
				sdram_data, timer_read_reg)
	begin
		-- Registers default next value
		state_next				<= state_reg;
		bank_next				<= bank_reg;
		address_next 			<= address_reg;
		cmd_next				<= cmd_reg;
		r_buff_req_next			<= r_buff_req_reg;
		r_data_next				<= r_data_reg;
		r_ready_next			<= r_ready_reg;
		r_data_valid_next 		<= r_data_valid_reg;
		r_length_next    		<= r_length_reg;
		w_buff_req_next			<= w_buff_req_reg;
		w_ready_next			<= w_ready_reg;
		w_done_next				<= w_done_reg;
		w_data_next				<= w_data_reg;
		w_output_en_next		<= '0';
		current_operation_next 	<= current_operation_reg;
		address_buff_next		<= address_buff_reg;
		timer_ref_next     		<= to_unsigned(0, timer_ref_next'length);
		timer_write_next    	<= '0';
		timer_read_next     	<= '0';
		cas_counter_next		<= to_unsigned(0, cas_counter_next'length);
		ref_counter_next		<= ref_counter_reg + 1;		--problem -> it counts even before init. it may not be a problem -> in this way after init a refresh is performed
		-- Ready signals are asserted when the sdram Init is done
		if (init_done_next = '1' and init_done_reg = '0') then --problem
			r_ready_next	<= '1';
			w_ready_next	<= '1';
		end if;
		-- Buffering request process
		if (write_req = '1') then
			w_buff_req_next	<= '1';
			w_ready_next 	<= '0';
			w_done_next		<= '0';
		end if;
		if (read_req = '1') then
			r_buff_req_next		<= '1';
			r_ready_next		<= '0';
			r_data_valid_next 	<= '0';
		end if;
		case state_reg is
		
			when IDLE_STATE =>
				if (init_done_reg = '1') then
					cmd_next 			<= CMD_NOP;
					state_next 			<= IDLE_STATE;
					r_data_valid_next 	<= '0';
					w_done_next			<= '0';
					if (ref_counter_reg >= 781) then --500000) then  ! XXX
						state_next 				<= REFRESH_STATE;
						ref_counter_next 		<= to_unsigned(0, ref_counter_next'length);
						current_operation_next 	<= NOP_OP;
					elsif (w_buff_req_reg = '1' or write_req = '1') then
						state_next 				<= ACTIVE_STATE;
						current_operation_next 	<= WRITE_OP;
						w_buff_req_next 		<= '0';
						w_ready_next 			<= '0'; --not necessary if present in buffering req process
						w_done_next				<= '0'; --not necessary if present in buffering req process
						w_data_next 			<= write_data;
						address_buff_next		<= write_address;
					elsif (r_buff_req_reg = '1' or read_req = '1') then
						state_next 				<= ACTIVE_STATE;
						current_operation_next 	<= READ_OP;
						address_buff_next		<= read_address;
						r_buff_req_next			<= '0';
						r_ready_next			<= '0';--not necessary if present in buffering req process
						r_data_valid_next 		<= '0';--not necessary if present in buffering req process
						r_length_next			<= unsigned(read_length);
					end if;
				else
					state_next 		<= IDLE_STATE;
					cmd_next 		<= init_cmd_next;
					address_next 	<= init_addr_next;
				end if;

			when REFRESH_STATE =>
				state_next	<= REF_WAIT_STATE;
				cmd_next	<= CMD_REFRESH;

			when REF_WAIT_STATE =>
				state_next 	<= REF_WAIT_STATE;
				cmd_next	<= CMD_NOP;
				timer_ref_next <= timer_ref_reg + 1;
				if (timer_ref_reg = 6) then
					state_next <= IDLE_STATE;
				end if;

			when ACTIVE_STATE =>
				state_next		<= ACTIVE_NOP_STATE;
				cmd_next 		<= CMD_ACTIVE;
				address_next 	<= addr_row_s;
				bank_next		<= addr_bank_s;

			when ACTIVE_NOP_STATE =>
				state_next 	<= READ_STATE;
				cmd_next 	<= CMD_NOP;
				if (current_operation_reg = WRITE_OP) then
					state_next <= WRITE_STATE;
				end if;
				
			when WRITE_STATE =>
				state_next			<= WRITE_NOP_STATE;
				cmd_next			<= CMD_WRITE;
				address_next 		<= "0000" & addr_col_s; --A10 to 0 -> manual precharge
				w_output_en_next 	<= '1';

			when WRITE_NOP_STATE =>
				state_next		<= WRITE_NOP_STATE;
				cmd_next		<= CMD_NOP;
				if (timer_write_reg = '1') then
					state_next	<= PRECHARGE_STATE;
				end if;
				timer_write_next <= '1';--timer_write_reg + 1;

			when READ_STATE =>
				state_next			<= READ_STATE;
				cmd_next			<= CMD_READ;
				address_next 		<= "0000" & addr_col_s;
				address_buff_next 	<= std_logic_vector( unsigned(address_buff_reg) + 1 );
				r_length_next		<= r_length_reg - 1;
				if (r_length_reg = 1) then
					state_next		<= READ_NOP_STATE;
				end if;
				cas_counter_next 	<= cas_counter_reg + 1;
				if (cas_counter_reg = 3) then
					r_data_next 		<= sdram_data;
					r_data_valid_next 	<= '1';
					cas_counter_next 	<= cas_counter_reg;
				end if;

			when READ_NOP_STATE => 
				state_next	<= READ_NOP_STATE;
				cmd_next	<= CMD_NOP;
				timer_read_next <= '1';
				if (timer_read_reg = '1') then
					state_next <= PRECHARGE_STATE;
				end if;
				cas_counter_next 	<= cas_counter_reg + 1;
				if (cas_counter_reg = 3) then
					r_data_next 		<= sdram_data;
					r_data_valid_next 	<= '1';
					cas_counter_next 	<= cas_counter_reg;
				end if;

			when PRECHARGE_STATE =>
				cmd_next 		<= CMD_PRECHARGE;
				state_next 		<= IDLE_STATE;
				address_next 	<= (others => '0');
				if (current_operation_reg = WRITE_OP) then
					w_ready_next 	<= '1';
					w_done_next		<= '1';
				else
					r_ready_next 		<= '1';
					r_data_next 		<= sdram_data;
					r_data_valid_next 	<= '1';							
				end if;

		end case;
	end process;

end architecture;