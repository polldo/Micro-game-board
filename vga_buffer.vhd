library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_buffer is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		-- Vga interface
		display_enable		: in std_logic;
		new_page			: in std_logic;
		fifo_r_req			: in std_logic;
		fifo_r_data			: out std_logic_vector(15 downto 0);
		-- Memory interface
		read_req			: out std_logic;
		read_address		: out std_logic_vector(23 downto 0);
		read_length			: out std_logic_vector(8 downto 0);
		read_data			: in std_logic_vector(15 downto 0);
		read_ready			: in std_logic;
		read_data_valid		: in std_logic
	);
end entity;

architecture bhv of vga_buffer is
	-- Buffer signals
	type buffer_type is array(0 to 200) of std_logic_vector(15 downto 0);
	signal buffer_s: buffer_type := (others => (others => '0'));
	signal fifo_w_data			: std_logic_vector(15 downto 0); -- := "1100000110000011";--(others => '0');--"1100110011001100";--
	signal fifo_w_req			: std_logic := '0';
	signal fifo_flush_req		: std_logic := '0';
	--signal fifo_r_req_old 		: std_logic := '0';
	--signal fifo_r_req_sync 		: std_logic := '0';
	signal first_index_s 		: integer range 0 to 200 := 0;--(8 downto 0) := 0;
	signal last_index_s 		: integer range 0 to 200 := 0;--(8 downto 0) := 0;
	signal element_counter_s 	: unsigned(8 downto 0) := to_unsigned(0, 9);
	-- Buffer filler signals
	type state_type is (WAIT_STATE, READ_STATE, READ_WAIT_STATE);
	signal state_reg, state_next: state_type := WAIT_STATE; 
	signal read_address_reg, read_address_next : std_logic_vector(23 downto 0) := (others => '0');
	signal read_save_count_reg, read_save_count_next : unsigned(3 downto 0) := to_unsigned(0, 4);
	signal fifo_flushed : std_logic := '0';
begin

	-- Image buffer processes
	fifo_r_data <= buffer_s(first_index_s);

	process(clock, reset)
	begin
		if (reset = '1') then
			first_index_s			<= 0;
			last_index_s			<= 0;
			element_counter_s	 	<= to_unsigned(0, element_counter_s'length);
			--fifo_r_req_old 			<= '0';
			--fifo_r_req_sync			<= '0';
		elsif (clock = '1' and clock'event) then
			if (fifo_flush_req = '1') then
				first_index_s 		<= 0;
				last_index_s 		<= 0;
				element_counter_s 	<= (others => '0');
			else
				if (fifo_w_req = '1') then
					buffer_s(last_index_s) <= fifo_w_data;
					last_index_s <= last_index_s + 1;
					element_counter_s <= element_counter_s + 8;--+ 1;
					if (last_index_s = 7) then
						last_index_s <= 0;
					end if;
				end if;
				-- Synchronization read process
				--fifo_r_req_old 	<= fifo_r_req;
				--fifo_r_req_sync <= '0';
				--if (fifo_r_req_old = '0' and fifo_r_req = '1') then
				--	fifo_r_req_sync <= '1';
				--elsif (fifo_r_req_sync = '1') then
				--	element_counter_s <= element_counter_s - 1;
				--	first_index_s <= first_index_s + 1;
				--	if (first_index_s = 7) then
				--		first_index_s <= 0;
				--	end if;
				--end if;
				if (fifo_r_req = '1') then
					element_counter_s <= element_counter_s - 1;
					first_index_s <= first_index_s + 1;
					if (first_index_s = 7) then
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

	-- Image buffer filler
	process(clock, reset)
	begin
		if (reset = '1') then
			state_reg 				<= WAIT_STATE;
			read_address_reg 		<= (others => '0');
			read_save_count_reg		<= (others => '0');
		elsif (clock = '1' and clock'event) then
			state_reg 			<= state_next;
			read_address_reg 	<= read_address_next;
			read_save_count_reg <= read_save_count_next;
		end if;
	end process;

	process(state_reg, read_address_reg, read_save_count_reg, new_page, display_enable, element_counter_s, read_ready, read_data_valid, read_data, fifo_flushed)
	begin
		state_next 				<= state_reg;
		fifo_w_req 				<= '0';
		read_req 				<= '0';
		read_address_next 		<= read_address_reg;
		read_save_count_next	<= read_save_count_reg;
		fifo_flush_req			<= '0';
		case state_reg is

			when WAIT_STATE => 
				if (display_enable = '1') then
					fifo_flushed <= '0';
				end if;
				if (new_page = '1') then --and element_counter_s > 0 and fifo_flushed = '0') then --and element_counter_s > 0) then
					read_address_next 	<= (others => '0'); 
					fifo_flush_req 		<= '1';
					fifo_flushed		<= '1';
				end if;
				--if (display_enable = '0' and element_counter_s = 0) then
				if (element_counter_s = 0) then
					state_next <= READ_STATE;
				end if;

			when READ_STATE =>
				if (read_ready = '1') then
					read_req 				<= '1';
					read_address 			<= read_address_reg;
					read_length 			<= std_logic_vector(to_unsigned(8, read_length'length));--read_length_const;
					state_next				<= READ_WAIT_STATE;
				end if; 
				
			when READ_WAIT_STATE =>
				if (read_data_valid = '1') then
					fifo_w_data				<= read_data;--"000000000000" & std_logic_vector(read_save_count_reg);--read_data; 
					fifo_w_req 				<= '1';
					read_save_count_next	<= read_save_count_reg + 1;
					if (read_save_count_reg = 7) then
						read_save_count_next	<= (others => '0');
						read_address_next		<= std_logic_vector( unsigned(read_address_reg) + to_unsigned(8, read_address_reg'length) );
						state_next				<= WAIT_STATE;
					end if;
				end if;

		end case;
	end process;

end architecture;