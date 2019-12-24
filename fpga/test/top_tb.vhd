--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--	Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end entity;

architecture provaTB of top_tb is

	component top_entity is
		port    
		(
			clock, reset_n 			: in std_logic;
			-- VGA signals
			--vga_v_sync, vga_h_sync		: out std_logic;
			--vga_r_out, vga_g_out, vga_b_out	: out std_logic;
			-- SDRAM signals
			sdram_clock			: out std_logic;
			sdram_data			: inout std_logic_vector(15 downto 0);
			sdram_bank			: out std_logic_vector(1 downto 0);
			sdram_address		: out std_logic_vector(12 downto 0);
			sdram_cke			: out std_logic;
			sdram_cs_n 			: out std_logic;
			sdram_ras_n			: out std_logic;
			sdram_cas_n 		: out std_logic;
			sdram_we_n 			: out std_logic;
			sdram_umqm			: out std_logic;
			sdram_ldqm			: out std_logic;
			-- Memory tester signals
			button_in 			: in 	std_logic;
			led_out				: out std_logic
		);
	end component;

	signal s_clk, s_rst : std_logic := '0';
	signal s_v, s_h, s_r, s_g, s_b : std_logic;
	signal sdram_clock_s		: std_logic;
	signal sdram_data_s			: std_logic_vector(15 downto 0);
	signal sdram_bank_s			: std_logic_vector(1 downto 0);
	signal sdram_address_s		: std_logic_vector(12 downto 0);
	signal sdram_cke_s			: std_logic;
	signal sdram_cs_n_s 		: std_logic;
	signal sdram_ras_n_s		: std_logic;
	signal sdram_cas_n_s 		: std_logic;
	signal sdram_we_n_s 		: std_logic;
	signal button_in_s 			: std_logic;
	signal led_out_s			: std_logic;
begin

	DUT: top_entity port map (s_clk, s_rst, --s_v, s_h, s_r, s_g, s_b, 
								sdram_clock_s, sdram_data_s, sdram_bank_s,
								sdram_address_s, sdram_cke_s, sdram_cs_n_s, sdram_ras_n_s, sdram_cas_n_s, sdram_we_n_s, 
								button_in_s, led_out_s);
	
	s_clk <= not s_clk after 10ns;

	process
	begin
		wait for 10 ns;
		s_rst	<= '1'; wait for 3 ns;
		s_rst	<= '0';
		button_in_s <= '1';
		wait for 30000 ns;
		button_in_s <= '0';
	wait;
	end process;

end architecture;