library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level_entity is
    Port ( clk : in std_logic;
           rst : in std_logic;
			  lock : out std_logic;
           leds : out std_logic_vector(7 downto 0);
           switches : in std_logic_vector(7 downto 0);
           rs232_rx : in std_logic;
           rs232_tx : out std_logic);
end top_level_entity;

architecture Behavioral of top_level_entity is

   -- Insert component declaration for program here
	component program is
    Port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;

	-- Program memory signals
		signal address      : std_logic_vector (9 downto 0);


	COMPONENT kcpsm3
		PORT(
			instruction   : IN std_logic_vector(17 downto 0);
			in_port       : IN std_logic_vector(7 downto 0);
			interrupt     : IN std_logic;
			reset         : IN std_logic;
			clk           : IN std_logic;          
			address       : OUT std_logic_vector(9 downto 0);
			port_id       : OUT std_logic_vector(7 downto 0);
			write_strobe  : OUT std_logic;
			out_port      : OUT std_logic_vector(7 downto 0);
			read_strobe   : OUT std_logic;
			interrupt_ack : OUT std_logic
			);
		END COMPONENT;

		-- PicoBlaze Signals
		signal instruction  : std_logic_vector (17 downto 0);
		signal port_id      : std_logic_vector (7 downto 0);
		signal write_strobe : std_logic;
		signal in_port      : std_logic_vector (7 downto 0);
		signal out_port     : std_logic_vector (7 downto 0);
		signal read_strobe  : std_logic;



		COMPONENT uart_rx
			PORT
			(
			  serial_in           : IN std_logic;
			  read_buffer         : IN std_logic;
			  reset_buffer        : IN std_logic;
			  en_16_x_baud        : IN std_logic;
			  clk                 : IN std_logic;          
			  data_out            : OUT std_logic_vector(7 downto 0);
			  buffer_data_present : OUT std_logic;
			  buffer_full         : OUT std_logic;
			  buffer_half_full    : OUT std_logic
			);
		END COMPONENT;

		COMPONENT uart_tx
		PORT
		(
			data_in          : IN std_logic_vector(7 downto 0);
			write_buffer     : IN std_logic;
			reset_buffer     : IN std_logic;
			en_16_x_baud     : IN std_logic;
			clk              : IN std_logic;          
			serial_out       : OUT std_logic;
			buffer_full      : OUT std_logic;
			buffer_half_full : OUT std_logic
		);
		END COMPONENT;

		-- UART signals
		signal baud_count      : std_logic_vector (8 downto 0);
		signal en_16_x_baud    : std_logic;
		signal read_from_uart  : std_logic;
  		signal rx_data         : std_logic_vector(7 downto 0);
  		signal data_present    : std_logic;
		signal write_to_uart   : std_logic;
		signal write_to_leds   : std_logic;
		signal buffer_full     : std_logic;

      COMPONENT my_dcm
	   PORT
		(
		  CLKIN_IN : IN std_logic;
		  RST_IN : IN std_logic;          
		  CLKFX_OUT : OUT std_logic;
		  CLKIN_IBUFG_OUT : OUT std_logic;
		  CLK0_OUT : OUT std_logic;
		  LOCKED_OUT : OUT std_logic
		);
	   END COMPONENT;

      signal clk55MHz   : std_logic;
	signal rst_p : std_logic;

begin


-- Instantiate PicoBlaze and the instruction ROM.  This is simply
-- cut and paste from the example designs that come with PicoBlaze.
-- Interrupts are not used for this design.

	rst_p <= not rst;

	my_kcpsm3: kcpsm3 
	   PORT MAP
		(
			address       => address,
			instruction   => instruction,
			port_id       => port_id,
			write_strobe  => write_strobe,
			out_port      => out_port,
			read_strobe   => read_strobe,
			in_port       => in_port,
			interrupt     => '0',
			interrupt_ack => open,
			reset         => rst_p,
			clk           => clk55MHz
		);

   -- Insert component instantiation for program ROM here
	our_program : program
	  PORT MAP (
		 clk => clk55MHz,
		 address => address,
		 instruction => instruction
	  );

   Inst_my_dcm: my_dcm PORT MAP(
		CLKIN_IN => clk,
		RST_IN => rst_p,
		CLKFX_OUT => clk55MHz,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		LOCKED_OUT => lock
	);


-- Implement the 16x bit rate counter for the uart transmit and receive.
-- The system clock is 50 MHz, and the desired baud rate is 9600.  I used
-- the formula in the documentation to calculate the terminal count value.

	baudgen: process (clk55MHz,rst_p)
	begin  
   	if rst_p = '1' then
      	baud_count <= "000000000";
			en_16_x_baud <= '0';
   	elsif (clk55MHz'event and clk55MHz = '1') then
      	if (baud_count = X"166")then
		  		baud_count <= "000000000";
		  		en_16_x_baud <= '1';
      	else
		  		baud_count <= baud_count + 1;
        		en_16_x_baud <= '0';
      	end if;
   	end if;
	end process;

	
   -- Implement the output port logic:
      --   leds_out, port 01
      --   uart_data_tx, port 03

	write_to_uart <= write_strobe and port_id(0) and port_id(1) and not port_id(2);
   write_to_leds <= write_strobe and port_id(0) and not port_id(1) and not port_id(2);
	--write_to_leds <= write_strobe and port_id(0);
	
  process (clk55MHz,rst_p)
	begin  
	  if (clk55MHz'event and clk55MHz='1') then
	  	 if rst_p = '1'	then
	      leds <= "00000000";
	    elsif(write_to_leds = '1') then
	        leds <= out_port;
       end if;
     end if;
	end process;


   transmit: uart_tx 
	PORT MAP
	(
		data_in          => out_port,
		write_buffer     => write_to_uart,
		reset_buffer     => rst_p,
		en_16_x_baud     => en_16_x_baud,
		serial_out       => rs232_tx,
		buffer_full      => open,
		buffer_half_full => open,
		clk              => clk55MHz
	);


	--  Implement the input port logic:
      --  switch_in, port 00
      --  uart_data_rx, port 02
      --  data_present, port 04
      --  buffer_full, port 05

	process (clk55MHz,rst_p)
	begin  
   	if (clk55MHz'event and clk55MHz = '1') then
			if rst_p = '1' then
      		in_port <= "00000000";
      		read_from_uart <= '0';
			else
      		case (port_id) is
        			when X"00" =>
							in_port <= switches;
        			when X"02" =>
						in_port <= rx_data;
        			when X"04" =>
							in_port <= "0000000" & data_present;
					when X"05" =>
							in_port <= "0000000" & buffer_full;
        			when others =>
						in_port <= "00000000";
      		end case;
      	end if;
			read_from_uart <= read_strobe and port_id(2);
		end if;
	end process;

  	receive: uart_rx 
	PORT MAP
	(
		serial_in           => rs232_rx,
		data_out            => rx_data,
		read_buffer         => read_from_uart,
		reset_buffer        => rst_p,
		en_16_x_baud        => en_16_x_baud,
		buffer_data_present => data_present,
		buffer_full         => open,
		buffer_half_full    => open,
		clk                 => clk55MHz
	); 



end Behavioral;
