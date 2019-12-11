library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is
	port    
	(
		clock				: in std_logic;
		reset				: in std_logic;
		-- Spi interface
		spi_enable			: in std_logic;
		spi_clock			: in std_logic;
		spi_data			: in std_logic;
		-- Memory write port
		mem_write_ready		: in std_logic;
		mem_write_done		: in std_logic;
		mem_write_req		: out std_logic;
		mem_write_address	: out std_logic_vector(23 downto 0);
		mem_write_data		: out std_logic_vector(15 downto 0)
		-- Debug port
		;debug_spi : out std_logic_vector(3 downto 0)
	);
end entity;

architecture struct of spi is

	component spi_rx is
		port    
		(
			clock				: in std_logic;
			reset				: in std_logic;
			spi_enable			: in std_logic;
			spi_clock			: in std_logic;
			spi_data			: in std_logic;
			ack_received		: in std_logic;
			data_received		: out std_logic_vector(15 downto 0);
			transfer_complete	: out std_logic
			-- Debug port
			--;debug_spi : out std_logic_vector(3 downto 0)
		);
	end component;

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
			-- Debug port
			--;debug_spi : out std_logic_vector(3 downto 0)
		);
	end component;

	component spi_fifo is
		port    
		(
			clock				: in std_logic;
			reset				: in std_logic;
			-- Fifo write port  
			fifo_w_req			: in std_logic;
			fifo_w_data			: in std_logic_vector(15 downto 0);
			-- Fifo read port
			--fifo_r_req			: in std_logic;
			--fifo_r_data			: out std_logic_vector(15 downto 0);
			-- Fifo to Memory write port
			mem_write_ready		: in std_logic;
			mem_write_done		: in std_logic;
			mem_write_req		: out std_logic;
			mem_write_address	: out std_logic_vector(23 downto 0);
			mem_write_data		: out std_logic_vector(15 downto 0)
			-- Debug port
			;debug_spi : out std_logic_vector(3 downto 0)
		);
	end component;

	signal ack_received_s 		: std_logic;
	signal data_received_s		: std_logic_vector(15 downto 0);
	signal transfer_complete_s	: std_logic;
	signal fifo_w_req_s			: std_logic;
	signal fifo_w_data_s		: std_logic_vector(15 downto 0);
	--signal mem_write_ready_s	: std_logic;
	--signal mem_write_done_s		: std_logic;
	--signal mem_write_req_s		: std_logic;
	--signal mem_write_address_s	: std_logic_vector(23 downto 0);
	--signal mem_write_data_s		: std_logic_vector(15 downto 0);
begin

	SPI_RECEIVER_INST: spi_rx port map 
	(
		clock				 => clock,
		reset				 => reset,
		spi_enable			 => spi_enable,
		spi_clock			 => spi_clock,
		spi_data			 => spi_data,
		ack_received		 => ack_received_s,
		data_received		 => data_received_s,
		transfer_complete	 => transfer_complete_s
		--,debug_spi			=> debug_spi
	);

	SPI_CONTROLLER_INST: spi_controller port map
	(
		clock				=> clock,
		reset				=> reset,
		data_received		=> data_received_s,
		transfer_complete	=> transfer_complete_s,
		ack_received		=> ack_received_s,
		fifo_w_req			=> fifo_w_req_s,
		fifo_w_data			=> fifo_w_data_s
		--,debug_spi			=> debug_spi
	);

	SPI_FIFO_INST: spi_fifo port map
	(
		clock				=> clock,
		reset				=> reset,
		fifo_w_req			=> fifo_w_req_s,
		fifo_w_data			=> fifo_w_data_s,
		mem_write_ready		=> mem_write_ready, 
		mem_write_done		=> mem_write_done,
		mem_write_req		=> mem_write_req,
		mem_write_address	=> mem_write_address,
		mem_write_data		=> mem_write_data
		,debug_spi			=> debug_spi
	);

end architecture;