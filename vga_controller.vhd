library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
	port    
	(
		clock			: in std_logic;
		reset			: in std_logic;
		v_sync, h_sync	: out std_logic;
		display_enable	: out std_logic;
		new_page		: out std_logic
	);
end entity;

architecture bhv of vga_controller is
	-- resolution 800x600
	constant H_F_PORCH : unsigned(10 downto 0) := to_unsigned(800, 11);
	constant H_S_PULSE : unsigned(10 downto 0) := to_unsigned(800 + 56, 11);
	constant H_B_PORCH : unsigned(10 downto 0) := to_unsigned(800 + 56 + 120, 11);
	constant H_END_VAL : unsigned(10 downto 0) := to_unsigned(800 + 56 + 120 + 64, 11);
	constant V_F_PORCH : unsigned(10 downto 0) := to_unsigned(600, 11);
	constant V_S_PULSE : unsigned(10 downto 0) := to_unsigned(600 + 37, 11);
	constant V_B_PORCH : unsigned(10 downto 0) := to_unsigned(600 + 37 + 6, 11);
	constant V_END_VAL : unsigned(10 downto 0) := to_unsigned(600 + 37 + 6 + 23, 11);
	--constant H_F_PORCH : unsigned(10 downto 0) := to_unsigned(1280, 11);
	--constant H_S_PULSE : unsigned(10 downto 0) := to_unsigned(1280 + 64, 11);
	--constant H_B_PORCH : unsigned(10 downto 0) := to_unsigned(1280 + 64 + 136, 11);
	--constant H_END_VAL : unsigned(10 downto 0) := to_unsigned(1280 + 64 + 136 + 200, 11);
	--constant V_F_PORCH : unsigned(10 downto 0) := to_unsigned(800, 11);
	--constant V_S_PULSE : unsigned(10 downto 0) := to_unsigned(800 + 1, 11);
	--constant V_B_PORCH : unsigned(10 downto 0) := to_unsigned(800 + 1 + 3, 11);
	--constant V_END_VAL : unsigned(10 downto 0) := to_unsigned(800 + 1 + 3 + 24, 11);
	--constant H_F_PORCH : unsigned(10 downto 0) := to_unsigned(1280, 11);
	--constant H_S_PULSE : unsigned(10 downto 0) := to_unsigned(1280 + 48, 11);
	--constant H_B_PORCH : unsigned(10 downto 0) := to_unsigned(1280 + 48 + 112, 11);
	--constant H_END_VAL : unsigned(10 downto 0) := to_unsigned(1280 + 48 + 112 + 248, 11);
	--constant V_F_PORCH : unsigned(10 downto 0) := to_unsigned(1024, 11);
	--constant V_S_PULSE : unsigned(10 downto 0) := to_unsigned(1024 + 1, 11);
	--constant V_B_PORCH : unsigned(10 downto 0) := to_unsigned(1024 + 1 + 3, 11);
	--constant V_END_VAL : unsigned(10 downto 0) := to_unsigned(1024 + 1 + 3 + 38, 11);
	--constant H_F_PORCH : unsigned(10 downto 0) := to_unsigned(1280, 11);
	--constant H_S_PULSE : unsigned(10 downto 0) := to_unsigned(1280 + 88, 11);
	--constant H_B_PORCH : unsigned(10 downto 0) := to_unsigned(1280 + 88 + 136, 11);
	--constant H_END_VAL : unsigned(10 downto 0) := to_unsigned(1280 + 88 + 136 + 224, 11);
	--constant V_F_PORCH : unsigned(10 downto 0) := to_unsigned(960, 11);
	--constant V_S_PULSE : unsigned(10 downto 0) := to_unsigned(960 + 1, 11);
	--constant V_B_PORCH : unsigned(10 downto 0) := to_unsigned(960 + 1 + 3, 11);
	--constant V_END_VAL : unsigned(10 downto 0) := to_unsigned(960 + 1 + 3 + 38, 11);
	-- vga counter signals
	signal h_val, v_val : unsigned(15 downto 0) := to_unsigned(0, 16);
	--signal h_f_porch_s, h_s_pulse_s, h_b_porch_s : std_logic := '0';
	--signal v_f_porch_s, v_s_pulse_s, v_b_porch_s : std_logic := '0';
	signal h_s_pulse_s, v_s_pulse_s : std_logic := '0';
	signal h_on, v_on : std_logic := '0';
	---- window position signals
	signal img_x_inscreen : std_logic := '0';
	signal img_y_inscreen : std_logic := '0';
	-- Init counter
	signal vga_init 		: std_logic := '0';
	signal vga_init_counter : unsigned(15 downto 0) := (others => '0');

	-- fsm signals
	--signal h_val_reg, h_val_next, v_val_reg, v_val_next : unsigned(10 downto 0) := (others => '0');
	--signal h_s_pulse_reg, h_s_pulse_next : std_logic := '0';
	--signal v_s_pulse_reg, v_s_pulse_next : std_logic := '0';
	--signal display_enable_reg, display_enable_next : std_logic := '0';
begin



--------- FSM START
	--v_sync <= v_s_pulse_reg;
	--h_sync <= h_s_pulse_reg;
	--display_enable <= display_enable_reg;

	--process(clock)
	--begin
	--	if (clock = '1' and clock'event) then
	--		h_val_reg <= h_val_next;
	--		v_val_reg <= v_val_next;
	--		h_s_pulse_reg <= h_s_pulse_next;
	--		v_s_pulse_reg <= v_s_pulse_next;
	--		display_enable_reg <= display_enable_next;
	--	end if;
	--end process;

	--process(h_val_reg, v_val_reg)
	--begin
	--	h_val_next <= h_val_reg + 1;
	--	if (h_val_reg = 1039) then
	--		h_val_next <= (others => '0');
	--		v_val_next <= v_val_reg + 1;
	--	end if;
	--	if (v_val_reg = 665) then
	--		v_val_next <= (others => '0');
	--	end if;
	--	h_s_pulse_next <= '0';
	--	if (h_val_reg < 977 and h_val_reg >= 855) then
	--		h_s_pulse_next <= '1';
	--	end if;
	--	v_s_pulse_next <= '0';
	--	if (v_val_reg < 642 and v_val_reg >= 636) then
	--		v_s_pulse_next <= '1';
	--	end if;
	--	display_enable_next <= '0';
	--	if (h_val_reg > 799 and v_val_reg > 599) then
	--		display_enable_next <= '1';
	--	end if;
	--end process;

-------------------FSM END

	process(clock)
	begin
		if (clock = '1' and clock'event) then
				
			if (reset = '1') then
				h_val <= (others => '0');
				v_val <= (others => '0');
			else
				h_val <= h_val + 1;
				if (h_val = H_END_VAL - 1) then
					h_val <= (others => '0');
					v_val <= v_val + 1;
					if (v_val = V_END_VAL - 1) then
						v_val <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

	process(h_val, v_val)
	begin
		-- H SYNC RELATED CONTROL
		h_s_pulse_s <= '0';
		h_on 		<= '0';
		if (h_val < H_F_PORCH) then  
			h_on <= '1';
		elsif (h_val >= H_S_PULSE and h_val < H_B_PORCH) then
			h_s_pulse_s <= '1';
		end if;
		-- V SYNC RELATED CONTROL
		v_s_pulse_s <= '0';
		v_on 		<= '0';
		if (v_val < V_F_PORCH) then
			v_on <= '1';
		elsif (v_val >= V_S_PULSE and v_val < V_B_PORCH) then
			v_s_pulse_s <= '1';
		end if;
	end process;

	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset = '1') then
				vga_init 			<= '0';
				vga_init_counter 	<= (others => '0');
			else
				if (vga_init = '0') then
					if (vga_init_counter >= 300) then
						vga_init <= '1';
					else
						vga_init_counter <= vga_init_counter + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	--process(clock)
	--begin
	--	if (clock = '1' and clock'event) then
	--		-- H SYNC RELATED CONTROL
	--		h_f_porch_s <= '0';
	--		h_s_pulse_s <= '0';
	--		h_b_porch_s <= '0';
	--		h_val 		<= h_val + 1;
	--		if (h_val >= H_F_PORCH and h_val < H_S_PULSE) then  
	--			h_f_porch_s <= '1';
	--		elsif (h_val >= H_S_PULSE and h_val < H_B_PORCH) then
	--			h_s_pulse_s <= '1';
	--		elsif (h_val >= H_B_PORCH and h_val < H_END_VAL) then
	--			h_b_porch_s <= '1';
	--		elsif (h_val = H_END_VAL) then
	--			h_val <= to_unsigned(1, h_val'length);
	--		end if;
	--	end if;
	--end process;
	
	--process(clock)
	--begin
	--	if (clock = '1' and clock'event) then
	--		-- V SYNC RELATED CONTROL
	--		if (h_val = H_END_VAL) then		
	--			v_val <= v_val + 1;
	--		end if;
	--		v_f_porch_s <= '0';
	--		v_s_pulse_s <= '0';
	--		v_b_porch_s <= '0';
	--		if (v_val = V_END_VAL) then
	--			v_val <= to_unsigned(1, v_val'length);
	--		end if;
	--		if (v_val >= V_F_PORCH and v_val < V_S_PULSE) then
	--			v_f_porch_s <= '1';
	--		elsif (v_val >= V_S_PULSE and v_val < V_B_PORCH) then
	--			v_s_pulse_s <= '1';
	--		elsif (v_val >= V_B_PORCH and v_val < V_END_VAL) then
	--			v_b_porch_s <= '1';
	--		end if;
	--	end if;
	--end process;

	img_x_inscreen <= '1' when h_val >= 100 and h_val < 612 else '0';--1124 else '0';--< --228 else '0';--h_val >= 100 and h_val < 612 else '0';
	img_y_inscreen <= '1' when v_val >= 100 and v_val < 356 else '0';--612 else '0';--< --164 else '0';
	----display_enable <= img_x_inscreen and img_y_inscreen and not (v_f_porch_s or v_s_pulse_s or v_b_porch_s or h_f_porch_s or h_s_pulse_s or h_b_porch_s);
	--display_enable <= not (v_f_porch_s or v_s_pulse_s or v_b_porch_s or h_f_porch_s or h_s_pulse_s or h_b_porch_s);
	display_enable 	<= (vga_init) and h_on and v_on and img_x_inscreen and img_y_inscreen;
	new_page 		<= (vga_init) and not v_on;
	v_sync 	<= (vga_init) and v_s_pulse_s;
	--h_sync 	<= (vga_init) and not h_s_pulse_s; 
	h_sync 	<= (vga_init) and h_s_pulse_s; 

end architecture;
