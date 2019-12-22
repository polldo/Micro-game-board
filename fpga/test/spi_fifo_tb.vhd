--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:07:00 12/04/2019
-- Design Name:   
-- Module Name:   C:/Users/Poldo/Documents/uni/polito/Electronics_Embedded_Sys/project/XILINX_PROJECT/src/image_processor/spi_fifo_tb.vhd
-- Project Name:  image_processor
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: spi_fifo
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY spi_fifo_tb IS
END spi_fifo_tb;
 
ARCHITECTURE behavior OF spi_fifo_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spi_fifo
    PORT(
         clock : IN  std_logic;
         reset : IN  std_logic;
         fifo_w_req : IN  std_logic;
         fifo_w_data : IN  std_logic_vector(15 downto 0);
         mem_write_ready : IN  std_logic;
         mem_write_done : IN  std_logic;
         mem_write_req : OUT  std_logic;
         mem_write_address : OUT  std_logic_vector(23 downto 0);
         mem_write_data : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';
   signal reset : std_logic := '0';
   signal fifo_w_req : std_logic := '0';
   signal fifo_w_data : std_logic_vector(15 downto 0) := (others => '0');
   signal mem_write_ready : std_logic := '1';
   signal mem_write_done : std_logic := '0';

 	--Outputs
   signal mem_write_req : std_logic;
   signal mem_write_address : std_logic_vector(23 downto 0);
   signal mem_write_data : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clock_period : time := 10 ns;
 
   signal fill_fifo : std_logic := '0';

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: spi_fifo PORT MAP (
          clock => clock,
          reset => reset,
          fifo_w_req => fifo_w_req,
          fifo_w_data => fifo_w_data,
          mem_write_ready => mem_write_ready,
          mem_write_done => mem_write_done,
          mem_write_req => mem_write_req,
          mem_write_address => mem_write_address,
          mem_write_data => mem_write_data
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;

   --fill fifo process
   process
   begin
    if (fill_fifo = '1') then
      wait until clock = '0';
      fifo_w_req <= '1';
      wait until clock = '1';
      fifo_w_req <= '0';
      wait for clock_period * 10;
    end if;
	 wait for clock_period;
   end process;

   process
   begin
    wait until mem_write_req = '1';
	 mem_write_done  <= '0';
    wait for clock_period;
    wait until clock = '0';
    mem_write_ready <= '0';
    wait for clock_period*2;
    wait until clock = '0';
    mem_write_done <= '1';
    mem_write_ready <= '1';
	 --wait for clock_period;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clock_period*10;

      wait until clock = '0';

      fifo_w_data <= (others => '1');
      fill_fifo <= '1';
      -- insert stimulus here 
		--wait for 10000 ns;

      wait;
   end process;

END;
