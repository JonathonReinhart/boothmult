--
-- Library declarations
--
-- Standard IEEE libraries
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
------------------------------------------------------------------------------------
--
--
entity top_level_entity is
    Port (   clk : in std_logic;
              tx : out std_logic;
              rx : in std_logic );
    end top_level_entity;
--
------------------------------------------------------------------------------------
--
-- Start of test architecture
--
architecture Behavioral of top_level_entity is
--
------------------------------------------------------------------------------------
--
-- declaration of KCPSM3
--
  component kcpsm3 
    Port (      address : out std_logic_vector(9 downto 0);
            instruction : in std_logic_vector(17 downto 0);
                port_id : out std_logic_vector(7 downto 0);
           write_strobe : out std_logic;
               out_port : out std_logic_vector(7 downto 0);
            read_strobe : out std_logic;
                in_port : in std_logic_vector(7 downto 0);
              interrupt : in std_logic;
          interrupt_ack : out std_logic;
                  reset : in std_logic;
                    clk : in std_logic);
    end component;
--
-- declaration of program ROM
--
  component program
    Port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;
--
-- declaration of UART transmitter with integral 16 byte FIFO buffer
--
  component uart_tx
    Port (            data_in : in std_logic_vector(7 downto 0);
                 write_buffer : in std_logic;
                 reset_buffer : in std_logic;
                 en_16_x_baud : in std_logic;
                   serial_out : out std_logic;
                  buffer_full : out std_logic;
             buffer_half_full : out std_logic;
                          clk : in std_logic);
    end component;
--
-- declaration of UART Receiver with integral 16 byte FIFO buffer
--
  component uart_rx
    Port (            serial_in : in std_logic;
                       data_out : out std_logic_vector(7 downto 0);
                    read_buffer : in std_logic;
                   reset_buffer : in std_logic;
                   en_16_x_baud : in std_logic;
            buffer_data_present : out std_logic;
                    buffer_full : out std_logic;
               buffer_half_full : out std_logic;
                            clk : in std_logic);
  end component;
--
-- Insert DCM component declaration here
	COMPONENT my_dcm
	PORT(
		CLKIN_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;
	
	component booth_periph is
    generic (
        N : positive := 32                                  -- Factor bit width
        );
    port (
        clk         : in std_logic;                         -- System clock (50 MHz)
        sys_rst     : in std_logic;                         -- System Reset (active high)
        port_id     : in std_logic_vector (7 downto 0);     -- Port ID, asserted by pBlaze
        
        -- I/O Data from BM module to pBlaze
        -- TODO: Will out_port connect to MUX or be Hi-Z and connect directly to pBlaze?
        out_port    : out std_logic_vector (7 downto 0);    -- 8-bit data out to pBlaze
        read_strobe : in std_logic;                         -- strobed when pBlaze is reading from us
        
        -- I/O Data from pBlaze to BM module
        in_port     : in std_logic_vector (7 downto 0);     -- 8-bit data in from pBlaze
        write_strobe: in std_logic                          -- strobed when pBlaze is writing to us
        );
	end component;
	
	
	
	

------------------------------------------------------------------------------------
signal sys_rst : std_logic;	-- TODO: Add an input pin

--
-- Signals used to connect KCPSM3 to program ROM and I/O logic
--
signal address         : std_logic_vector(9 downto 0);
signal instruction     : std_logic_vector(17 downto 0);
signal port_id         : std_logic_vector(7 downto 0);
signal out_port        : std_logic_vector(7 downto 0);
signal in_port         : std_logic_vector(7 downto 0);
signal write_strobe    : std_logic;
signal read_strobe     : std_logic;
signal interrupt       : std_logic;
signal interrupt_ack   : std_logic;
--
-- Signals for connection of peripherals
--
signal uart_status_port : std_logic_vector(7 downto 0);
--
-- Signals for UART connections
--
signal          baud_count : integer range 0 to 127 :=0;
signal        en_16_x_baud : std_logic;
signal       write_to_uart : std_logic;
signal             tx_full : std_logic;
signal        tx_half_full : std_logic;
signal      read_from_uart : std_logic;
signal             rx_data : std_logic_vector(7 downto 0);
signal     rx_data_present : std_logic;
signal             rx_full : std_logic;
signal        rx_half_full : std_logic;
--
-- Signals for DCM
signal clk55MHz : std_logic;

  
signal data_from_booth : std_logic_vector (7 downto 0);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Start of circuit description
--
begin

  sys_rst <= '0';

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 and the program memory 
  ----------------------------------------------------------------------------------------------------------------------------------
  --

  processor: kcpsm3
    port map(      address => address,
               instruction => instruction,
                   port_id => port_id,
              write_strobe => write_strobe,
                  out_port => out_port,
               read_strobe => read_strobe,
                   in_port => in_port,
                 interrupt => interrupt,
             interrupt_ack => interrupt_ack,
                     reset => sys_rst,
                       clk => clk55MHz);
 
  program_rom: program
    port map(      address => address,
               instruction => instruction,
                       clk => clk55MHz);

  -- Insert DCM component instantiation here
  	Inst_my_dcm: my_dcm PORT MAP(
		CLKIN_IN => clk,
		CLKFX_OUT => clk55MHz,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		LOCKED_OUT => open
	);

    
  -- Interrupt unused
  interrupt <= '0';


  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 input ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  --
  -- UART FIFO status signals to form a bus
  --

  uart_status_port <= "000" & rx_data_present & rx_full & rx_half_full & tx_full & tx_half_full ;

  --
  -- The inputs connect via a pipelined multiplexer
  --

  input_ports: process(clk55MHz)
  begin
    if clk55MHz'event and clk55MHz='1' then

      case port_id(0) is

        
        -- read UART status at address 00 hex
        when '0' =>    in_port <= uart_status_port;

        -- read UART receive data at address 01 hex
        when '1' =>    in_port <= rx_data;
        
        -- Don't care used for all other addresses to ensure minimum logic implementation
        when others =>    in_port <= "XXXXXXXX";  

      end case;

      -- Form read strobe for UART receiver FIFO buffer.
      -- The fact that the read strobe will occur after the actual data is read by 
      -- the KCPSM3 is acceptable because it is really means 'I have read you'!

      read_from_uart <= read_strobe and port_id(0); 

    end if;

  end process input_ports;


  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 output ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
   
  output_ports: process(clk55MHz)
  begin

    if clk55MHz'event and clk55MHz='1' then
      if write_strobe='1' then



      end if;

    end if; 

  end process output_ports;

  --
  -- write to UART transmitter FIFO buffer at address 01 hex.
  -- This is a combinatorial decode because the FIFO is the 'port register'.
  --

  write_to_uart <= write_strobe and port_id(0);

  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- UART  
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  -- Connect the 8-bit, 1 stop-bit, no parity transmit and receive macros.
  -- Each contains an embedded 16-byte FIFO buffer.
  --

  transmit: uart_tx 
  port map (            data_in => out_port, 
                   write_buffer => write_to_uart,
                   reset_buffer => sys_rst,
                   en_16_x_baud => en_16_x_baud,
                     serial_out => tx,
                    buffer_full => tx_full,
               buffer_half_full => tx_half_full,
                            clk => clk55MHz );

  receive: uart_rx
  port map (            serial_in => rx,
                         data_out => rx_data,
                      read_buffer => read_from_uart,
                     reset_buffer => sys_rst,
                     en_16_x_baud => en_16_x_baud,
              buffer_data_present => rx_data_present,
                      buffer_full => rx_full,
                 buffer_half_full => rx_half_full,
                              clk => clk55MHz );  
  
  --
  -- Set baud rate to 38400 for the UART communications
  -- Requires en_16_x_baud to be 614400Hz which is a single cycle pulse every 90 cycles at 55MHz 
  --
  -- NOTE : If the highest value for baud_count exceeds 127 you will need to adjust 
  --        the range of integers in the signal declaration for baud_count.
  --

  baud_timer: process(clk55MHz)
  begin
    if clk55MHz'event and clk55MHz='1' then
      if baud_count=89 then
           baud_count <= 0;
         en_16_x_baud <= '1';
       else
           baud_count <= baud_count + 1;
         en_16_x_baud <= '0';
      end if;
    end if;
  end process baud_timer;

  ----------------------------------------------------------------------------------------------------------------------------------
  
  booth: booth_periph
  port map (
        clk => clk55MHz,
        sys_rst => sys_rst,
        port_id => port_id,
		  
        -- I/O Data from BM module to pBlaze
        out_port => data_from_booth,	-- 8-bit data out to pBlaze
        read_strobe => read_strobe,		-- strobed when pBlaze is reading from us                      
        
        -- I/O Data from pBlaze to BM module
        in_port => out_port,  			-- 8-bit data in from pBlaze
        write_strobe => write_strobe	-- strobed when pBlaze is writing to us                          
		  );
  

  

end Behavioral;

------------------------------------------------------------------------------------------------------------------------------------
--
-- END OF FILE uart_clock.vhd
--
------------------------------------------------------------------------------------------------------------------------------------


