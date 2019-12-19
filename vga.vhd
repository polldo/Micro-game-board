library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga is
	port    
	(
		clock_vga			: in std_logic;
		clock_memory		: in std_logic;
		reset				: in std_logic;
		-- Vga port
		v_sync, h_sync 		: out std_logic;
		r_out, g_out, b_out	: out std_logic;
		-- Memory port
		read_req			: out std_logic;
		read_address		: out std_logic_vector(23 downto 0);
		read_length			: out std_logic_vector(8 downto 0);
		read_data			: in std_logic_vector(15 downto 0);
		read_ready			: in std_logic;
		read_data_valid		: in std_logic
	);
end entity;

architecture struct of vga is
	component vga_controller is
		port    
		(
			clock			: in std_logic;
			reset			: in std_logic;
			-- Vga port
			v_sync, h_sync	: out std_logic;
			display_enable	: out std_logic;
			new_page		: out std_logic
		);
	end component;

	component vga_datapath is
		port    
		(
			clock				: in std_logic;
			reset				: in std_logic;
			-- Vga interface
			display_enable		: in std_logic;
			r_out, g_out, b_out	: out std_logic;
			-- Image buffer interface
			fifo_r_data			: in std_logic_vector(15 downto 0);
			fifo_r_req 			: out std_logic
		);
	end component;

	component vga_buffer is
		port
		(
			clock				: in std_logic;
			reset				: in std_logic;
			-- Vga interface
			display_enable		: in std_logic;
			new_page			: in std_logic;
			fifo_r_req			: in std_logic;
			fifo_r_data			: out std_logic_vector(15 downto 0);
			-- Memory interface
			read_req			: out std_logic;
			read_address		: out std_logic_vector(23 downto 0);
			read_length			: out std_logic_vector(8 downto 0);
			read_data			: in std_logic_vector(15 downto 0);
			read_ready			: in std_logic;
			read_data_valid		: in std_logic
		);
	end component;

	signal h_sync_s			: std_logic;
	signal v_sync_s			: std_logic;
	signal new_page_s		: std_logic;
	signal disp_en_s		: std_logic;
	signal fifo_r_data_s 	: std_logic_vector(15 downto 0);
	signal fifo_r_req_s		: std_logic;
begin

	h_sync 	<= h_sync_s;
	v_sync 	<= v_sync_s;

	VGA_CTRL: vga_controller port map
	(
		clock	 		=> clock_vga, 
		reset			=> reset,
		v_sync 			=> v_sync_s,
		h_sync 			=> h_sync_s, 
		display_enable 	=> disp_en_s,
		new_page 		=> new_page_s
	);

	VGA_DP: vga_datapath port map
	(
		clock 			=> clock_memory,
		reset			=> reset,
		display_enable 	=> disp_en_s, 
		r_out 			=> r_out, 
		g_out 			=> g_out, 
		b_out 			=> b_out,
		fifo_r_data 	=> fifo_r_data_s,
		fifo_r_req 		=> fifo_r_req_s
	);

	VGA_BUFF: vga_buffer port map
	(
		clock			=> clock_memory,
		reset			=> reset,
		display_enable	=> disp_en_s,
		new_page		=> new_page_s,
		fifo_r_req		=> fifo_r_req_s,
		fifo_r_data		=> fifo_r_data_s,
		read_req		=> read_req,
		read_address	=> read_address,
		read_length		=> read_length,
		read_data		=> read_data,
		read_ready		=> read_ready,
		read_data_valid	=> read_data_valid
	);

end architecture;
