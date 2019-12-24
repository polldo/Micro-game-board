--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--	Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_rx_tb is
end entity;

architecture provaTB of spi_rx_tb is

	component spi_rx is
		port    
		(
			clock				: in std_logic;
			spi_enable			: in std_logic;
			spi_clock			: in std_logic;
			spi_data			: in std_logic;
			data_received		: out std_logic_vector(15 downto 0);
			transfer_complete	: out std_logic
		);
	end component;

	signal s_clk: std_logic := '0';
	signal s_spi_en, s_spi_clk, s_spi_data, s_transfer_complete: std_logic := '0';
	signal s_data_received : std_logic_vector(15 downto 0) := (others => '0');
begin

	DUT: spi_rx port map (s_clk, s_spi_en, s_spi_clk, s_spi_data, s_data_received, s_transfer_complete);
	
	s_clk 		<= not s_clk after 5 ns;
	s_spi_clk 	<= not s_spi_clk after 50 ns;

	process
	begin
		wait for 5 ns;
		s_spi_en 	<= '1';
		s_spi_data 	<= '1';
		wait;
	end process;

end architecture;