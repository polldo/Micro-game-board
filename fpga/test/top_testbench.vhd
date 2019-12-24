--------------------------------------------------------------------------------
--  Author: Paolo Calao
--  Alias: Poldo
--  Github link: https://github.com/Polldo
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY top_testbench IS
END top_testbench;
 
ARCHITECTURE behavior OF top_testbench IS 
 
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
         button_in : IN  std_logic;
         led_out : OUT  std_logic_vector(2 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';
   signal reset_n : std_logic := '0';
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
   constant clock_period : time := 20 ns;
   constant sdram_clock_period : time := 10 ns;
 
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

   -- Stimulus process
   stim_proc: process
   begin
		reset_n 	<= '1';	
		wait for 10 ns;
		--reset_n	<= '0'; wait for 3 ns;
		--reset_n 	<= '1';
		button_in <= '1';
		wait for 300000 ns;
		button_in <= '0';
      wait;
   end process;

END;
