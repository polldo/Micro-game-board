--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--  Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use STD.textio.all;
use ieee.std_logic_textio.all;
  
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY top_spi_tb IS
END top_spi_tb;
 
ARCHITECTURE behavior OF top_spi_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top_entity
    PORT(
         clock : IN  std_logic;
         reset_n : IN  std_logic;
         sdram_clock : OUT  std_logic;
         sdram_data : INOUT  std_logic_vector(15 downto 0);
         sdram_bank : OUT  std_logic_vector(1 downto 0);
         sdram_address : OUT  std_logic_vector(12 downto 0);
         sdram_cke : OUT  std_logic;
         sdram_cs_n : OUT  std_logic;
         sdram_ras_n : OUT  std_logic;
         sdram_cas_n : OUT  std_logic;
         sdram_we_n : OUT  std_logic;
         sdram_umqm : OUT  std_logic;
         sdram_ldqm : OUT  std_logic;
         spi_enable : IN  std_logic;
         spi_clock : IN  std_logic;
         spi_data : IN  std_logic;
         button_in : IN  std_logic;
         led_out : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';
   signal reset_n : std_logic := '0';
   signal spi_enable : std_logic := '0';
   signal spi_clock : std_logic := '0';
   signal spi_data : std_logic := '0';
   signal button_in : std_logic := '0';

	--BiDirs
   signal sdram_data : std_logic_vector(15 downto 0);

 	--Outputs
   signal sdram_clock : std_logic;
   signal sdram_bank : std_logic_vector(1 downto 0);
   signal sdram_address : std_logic_vector(12 downto 0);
   signal sdram_cke : std_logic;
   signal sdram_cs_n : std_logic;
   signal sdram_ras_n : std_logic;
   signal sdram_cas_n : std_logic;
   signal sdram_we_n : std_logic;
   signal sdram_umqm : std_logic;
   signal sdram_ldqm : std_logic;
   signal led_out : std_logic_vector(2 downto 0);

   -- Clock period definitions
   constant clock_period : time := 10 ns;
   constant sdram_clock_period : time := 10 ns;
   constant spi_clock_period : time := 1000 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top_entity PORT MAP (
          clock => clock,
          reset_n => reset_n,
          sdram_clock => sdram_clock,
          sdram_data => sdram_data,
          sdram_bank => sdram_bank,
          sdram_address => sdram_address,
          sdram_cke => sdram_cke,
          sdram_cs_n => sdram_cs_n,
          sdram_ras_n => sdram_ras_n,
          sdram_cas_n => sdram_cas_n,
          sdram_we_n => sdram_we_n,
          sdram_umqm => sdram_umqm,
          sdram_ldqm => sdram_ldqm,
          spi_enable => spi_enable,
          spi_clock => spi_clock,
          spi_data => spi_data,
          button_in => button_in,
          led_out => led_out
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 
--   sdram_clock_process :process
--   begin
--		sdram_clock <= '0';
--		wait for sdram_clock_period/2;
--		sdram_clock <= '1';
--		wait for sdram_clock_period/2;
--   end process;
-- 
   spi_clock_process :process
   begin
		spi_clock <= '0';
		wait for spi_clock_period/2;
		spi_clock <= '1';
		wait for spi_clock_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
	file file_handler     : text open read_mode is "spi_test_simuli.dat";
	variable row          : line;
	variable data_read  : std_logic;
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
		reset_n <= '1';

      wait for 110000ns;


		while not endfile(file_handler) loop
			readline(file_handler, row);
			read(row, data_read);
			wait until spi_clock <= '0';
			spi_enable <= '1';
			spi_data <= data_read;
			wait until spi_clock <= '1';
		end loop;
	
      -- insert stimulus here 

      wait;
   end process;

END;
