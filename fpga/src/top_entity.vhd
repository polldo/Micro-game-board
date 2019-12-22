library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_entity is
	port    
	(
		clock, reset_n 			: in std_logic;
		-- VGA signals
		vga_v_sync, vga_h_sync		: out std_logic;
		vga_r_out, vga_g_out, vga_b_out	: out std_logic_vector(2 downto 0);
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
		-- Spi signals
		spi_enable			: in std_logic;
		spi_clock			: in std_logic;
		spi_data				: in std_logic
	);
end entity;

architecture struct of top_entity is

	component dcm_pll is
		port ( 	CLKIN_IN        : in    std_logic; 
				CLKIN_IBUFG_OUT : out   std_logic; 
				CLK0_OUT        : out   std_logic; 
				CLK2X_OUT       : out   std_logic);
	end component;
	
	component dcm_pll_shift is
		port ( 	CLKIN_IN : in    std_logic; 
				CLK0_OUT : out   std_logic);
	end component;

	component memory_controller is
		port    
		(
			clock				: in std_logic;
			reset 				: in std_logic;
			-- Read port
			read_req			: in std_logic;
			read_address		: in std_logic_vector(23 downto 0);
			read_length			: in std_logic_vector(8 downto 0);
			read_data			: out std_logic_vector(15 downto 0);
			read_ready			: out std_logic;
			read_data_valid		: out std_logic;
			-- Write port
			write_req			: in std_logic;
			write_address		: in std_logic_vector(23 downto 0);
			write_data			: in std_logic_vector(15 downto 0);
			write_ready			: out std_logic;
			write_done			: out std_logic;
			-- Sdram port
			sdram_data			: inout std_logic_vector(15 downto 0);
			sdram_bank			: out std_logic_vector(1 downto 0);
			sdram_address		: out std_logic_vector(12 downto 0);
			sdram_cke			: out std_logic;
			sdram_cs_n 			: out std_logic;
			sdram_ras_n			: out std_logic;
			sdram_cas_n 		: out std_logic;
			sdram_we_n 			: out std_logic
		);
	end component;

	component vga is
		port    
		(
			clock_vga			: in std_logic;
			clock_memory		: in std_logic;
			reset				: in std_logic;
			-- Vga port
			v_sync, h_sync 		: out std_logic;
			r_out, g_out, b_out	: out std_logic_vector(2 downto 0);
			-- Memory port
			read_req			: out std_logic;
			read_address		: out std_logic_vector(23 downto 0);
			read_length			: out std_logic_vector(8 downto 0);
			read_data			: in std_logic_vector(15 downto 0);
			read_ready			: in std_logic;
			read_data_valid		: in std_logic
		);
	end component;

	component display_controller is
		port
		(
			clock 		 		: in 	std_logic;
			new_pixel, new_page : in 	std_logic;
			read_data			: in 	std_logic_vector(7 downto 0);
			read_address		: out 	integer range 0 to 80000;--std_logic_vector(31 downto 0); 	 	
			pixel_out			: out 	std_logic_vector(3 downto 0)
		);
	end component;	
	
	
	component spi is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		-- Spi interface
		spi_enable			: in std_logic;
		spi_clock			: in std_logic;
		spi_data				: in std_logic;
		-- Memory write port
		mem_write_ready		: in std_logic;
		mem_write_done		: in std_logic;
		mem_write_req		: out std_logic;
		mem_write_address	: out std_logic_vector(23 downto 0);
		mem_write_data		: out std_logic_vector(15 downto 0)
	);
	end component;

	-- PLL Clock signals
	signal clock_s 	: std_logic;
	signal clock_100_s	: std_logic;
	signal clock_100_shift_s : std_logic;
	signal reset_s		: std_logic;
	-- VGA signals
	signal vga_v_sync_s, vga_h_sync_s 	: std_logic;
	-- Memory Controller signals
	-- Read port signals
	signal read_req_s			: std_logic;
	signal read_address_s		: std_logic_vector(23 downto 0);
	signal read_length_s		: std_logic_vector(8 downto 0);
	signal read_data_s			: std_logic_vector(15 downto 0);
	signal read_ready_s			: std_logic;
	signal read_data_valid_s	: std_logic;
	-- Write port signals
	signal write_req_s			: std_logic;
	signal write_address_s		: std_logic_vector(23 downto 0);
	signal write_data_s			: std_logic_vector(15 downto 0);
	signal write_ready_s		: std_logic;
	signal write_done_s			: std_logic;

begin

	-- VGA output signal assignment
	vga_h_sync <= vga_h_sync_s;
	vga_v_sync <= vga_v_sync_s;
	-- SDRAM clock phase is shifted, to not violate timings
	sdram_clock <= clock_100_shift_s;
	-- SDRAM data is never masked
	sdram_umqm 	<= '0';
	sdram_ldqm 	<= '0';
	-- High active reset.
	reset_s <= not reset_n;

------------------------------------- 
-- Clock generation components: 
--	clock 				@ 50 MHz	
--  clock_100_s 		@ 100 MHz  	
--  clock_100_shift_s 	@ 100 MHz, Phase shift: 70

	PLL_CLK: dcm_pll port map
	(
		CLKIN_IN 		=> clock,
		CLKIN_IBUFG_OUT	=> open,
		CLK0_OUT		=> clock_s,
		CLK2X_OUT		=> clock_100_s
	);
	
	PLL_CLK_SHFT: dcm_pll_shift port map
	(
		CLKIN_IN => clock_100_s,
		CLK0_OUT => clock_100_shift_s
	);
--------------------------------------
-- SPI slave. 
-- Responsible for receiving data in block of 16 bit and saving 
-- them into the SDRAM

	SPI_INST: spi port map
	(
		clock				=> clock_100_s,
		reset				=> reset_s,
		spi_enable			=> spi_enable,
		spi_clock			=> spi_clock,
		spi_data			=> spi_data,
		mem_write_ready		=> write_ready_s,
		mem_write_done		=> write_done_s,
		mem_write_req		=> write_req_s,
		mem_write_address	=> write_address_s,
		mem_write_data		=> write_data_s
	);
	
-------------------------------------
-- SDRAM Memory Controller
-- Performs burst reads of arbitrary length and single write

	MEM_CTRL: memory_controller port map
    (
        clock            => clock_100_s, 
        reset            => reset_s, 
        read_req         => read_req_s,
        read_address     => read_address_s,
        read_length      => read_length_s,
        read_data        => read_data_s,
        read_ready       => read_ready_s,
        read_data_valid  => read_data_valid_s,
        write_req        => write_req_s,
        write_address    => write_address_s,
        write_data       => write_data_s,
        write_ready      => write_ready_s,
        write_done       => write_done_s,
        sdram_data       => sdram_data,
        sdram_bank       => sdram_bank,
        sdram_address    => sdram_address,
        sdram_cke        => sdram_cke,
        sdram_cs_n       => sdram_cs_n,
        sdram_ras_n      => sdram_ras_n,
        sdram_cas_n      => sdram_cas_n,
        sdram_we_n       => sdram_we_n
    );

--------------------------------------
-- VGA component
-- reads an image from the SDRAM memory and outputs it following VGA standard
-- resolution: 800x600     Hz: 60 

	VGA_COMP: vga port map
	(
		clock_vga		=> clock_s, 
		clock_memory	=> clock_100_s,
		reset			=> reset_s,
		v_sync 			=> vga_v_sync_s, 
		h_sync 			=> vga_h_sync_s, 
		r_out 			=> vga_r_out, 
		g_out 			=> vga_g_out, 
		b_out 			=> vga_b_out,
		read_req 		=> read_req_s,
		read_address 	=> read_address_s,
		read_length 	=> read_length_s,
		read_data 		=> read_data_s,
		read_ready 		=> read_ready_s,
		read_data_valid => read_data_valid_s
	);

end architecture;