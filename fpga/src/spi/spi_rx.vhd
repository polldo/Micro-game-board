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
		data_received		: out std_logic_vector(15 downto 0);
		transfer_complete	: out std_logic
	);
end entity;

architecture bhv of spi_rx is

	signal spi_data_s			: std_logic_vector(1 downto 0) := (others => '0');
	signal spi_clock_s 			: std_logic_vector(1 downto 0) := (others => '0');
	signal spi_clock_rising 	: std_logic := '0';
	signal bit_counter 			: unsigned(4 downto 0) := (others => '0');
	signal data_received_s 		: std_logic_vector(15 downto 0) := (others => '0');

	signal init_counter : unsigned(32 downto 0) := (others => '0');
	signal init_reset : std_logic := '1';
	signal reset_s : std_logic;

begin

	-- Hold an initial reset
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

	-- Sample spi clock and data. Look for spi clock rising
	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset_s = '1' or spi_enable = '0') then
				spi_clock_s <= (others => '0');
				spi_data_s 	<= (others => '0');
			else
				spi_clock_s(0) 	<= spi_clock;
				spi_clock_s(1) 	<= spi_clock_s(0);
				spi_data_s(0)	<= spi_data;
				spi_data_s(1) 	<= spi_data_s(0);
				if (spi_clock_s(1) = '0' and spi_clock_s(0) = '1') then
					spi_clock_rising <= '1';
				else
					spi_clock_rising <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Wait for the spi clock rising, then shift the data register inserting the new sampled spi value
	process(clock)
	begin
		if (clock = '1' and clock'event) then
			if (reset_s = '1' or spi_enable = '0') then
				bit_counter <= (others => '0');
			else
				transfer_complete <= '0';
				if (spi_clock_rising = '1') then
					bit_counter 		<= bit_counter + 1;
					data_received_s 	<= data_received_s(14 downto 0) & spi_data_s(1);
					if (bit_counter = 15) then
						bit_counter 		<= (others => '0');
						data_received <= data_received_s(14 downto 0) & spi_data_s(1);
						transfer_complete <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;

end architecture;