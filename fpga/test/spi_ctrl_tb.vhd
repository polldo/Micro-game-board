--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:58:41 12/05/2019
-- Design Name:   
-- Module Name:   C:/Users/Poldo/Documents/uni/polito/Electronics_Embedded_Sys/project/XILINX_PROJECT/src/image_processor/spi_ctrl_tb.vhd
-- Project Name:  image_processor
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: spi_rx
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
 
ENTITY spi_ctrl_tb IS
END spi_ctrl_tb;
 
ARCHITECTURE behavior OF spi_ctrl_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spi_rx
    PORT(
         clock : IN  std_logic;
         reset : IN  std_logic;
         spi_enable : IN  std_logic;
         spi_clock : IN  std_logic;
         spi_data : IN  std_logic;
         ack_received : IN  std_logic;
         data_received : OUT  std_logic_vector(15 downto 0);
         transfer_complete : OUT  std_logic
        );
    END COMPONENT;
		 
	component spi_controller is
		port    
		(
			clock				: in std_logic;
			reset				: in std_logic;
			-- Spi port
			data_received		: in std_logic_vector(15 downto 0);
			transfer_complete	: in std_logic;
			ack_received		: out std_logic;
			-- Fifo port
			fifo_w_req			: out std_logic;
			fifo_w_data			: out std_logic_vector(15 downto 0)
		);
	end component;
		 

   --Inputs
   signal clock : std_logic := '0';
   signal reset : std_logic := '0';
   signal spi_enable : std_logic := '0';
   signal spi_clock : std_logic := '0';
   signal spi_data : std_logic := '0';
   signal ack_received : std_logic := '0';

 	--Outputs
   signal data_received : std_logic_vector(15 downto 0);
   signal transfer_complete : std_logic;
	
	signal fifo_w_data : std_logic_vector(15 downto 0);
	signal fifo_w_req : std_logic;

   -- Clock period definitions
   constant clock_period : time := 10 ns;
   constant spi_clock_period : time := 100 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: spi_rx PORT MAP (
          clock => clock,
          reset => reset,
          spi_enable => spi_enable,
          spi_clock => spi_clock,
          spi_data => spi_data,
          ack_received => ack_received,
          data_received => data_received,
          transfer_complete => transfer_complete
        );
		  
	-- Instantiate the Unit Under Test (UUT)
   uut_ctrl: spi_controller PORT MAP (
          clock => clock,
          reset => reset,
			 data_received => data_received,
          transfer_complete => transfer_complete,
          ack_received => ack_received,
			 fifo_w_req => fifo_w_req,
			 fifo_w_data => fifo_w_data
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 
   spi_clock_process :process
   begin
		spi_clock <= '0';
		wait for spi_clock_period/2;
		spi_clock <= '1';
		wait for spi_clock_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

		spi_enable <= '1';
		spi_data	<= '1';

      wait for clock_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
