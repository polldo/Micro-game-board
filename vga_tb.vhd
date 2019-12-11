library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_tb is
end entity;

architecture provaTB of vga_tb is

	component vga is
			port    
			(
				clock, rst: in std_logic;
				v_sync, h_sync: out std_logic;
				r_out, g_out, b_out: out std_logic
			);
	end component;

	signal s_clk, s_rst: std_logic := '0';
	signal s_v, s_h, s_r, s_g, s_b: std_logic;
	
begin

	DUT: vga port map (s_clk, s_rst, s_v, s_h, s_r, s_g, s_b);
	
	s_clk <= not s_clk after 10ns;

end architecture;