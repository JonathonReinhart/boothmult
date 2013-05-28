library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity top_level_entity is
    port (   clk : in std_logic;
              tx : out std_logic;
              rx : in std_logic );
end top_level_entity;


architecture Behavioral of top_level_entity is

------------------------------------------------------------------------------------
-- Components

  -- PicoBlaze microprocessor core
  component kcpsm3 
    port (      address : out std_logic_vector(9 downto 0);
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

  -- PicoBlaze Program ROM
  component program
    port (      address : in std_logic_vector(9 downto 0);
            instruction : out std_logic_vector(17 downto 0);
                    clk : in std_logic);
    end component;

  -- UART transmitter with integral 16 byte FIFO buffer
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

  -- UART Receiver with integral 16 byte FIFO buffer
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

  -- Digital Clock Manager
  COMPONENT my_dcm
    PORT(
		CLKIN_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
  END COMPONENT;
	
	-- Booth multiplier peripheral
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
	
    
    -- ChipScope ICON 
    component chipscope_icon
      PORT (
        CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));
    end component;
	
    -- ChipScope ILA
    component chipscope_ila
      PORT (
        CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
        CLK : IN STD_LOGIC;
        DATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        TRIG1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0));

    end component;

	
------------------------------------------------------------------------------------
-- Signals	

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
signal uart_status_data : std_logic_vector(7 downto 0);
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

-- Signals for ChipScope
signal chipscope_control0 : std_logic_vector(35 downto 0);
signal ila_trig0 : std_logic_vector(7 downto 0);
signal ila_trig1 : std_logic_vector(7 downto 0);
signal ila_data : std_logic_vector(31 downto 0);


------------------------------------------------------------------------------------
-- Constants	

-- Port IDs
constant UART_STATUS_PORT	: std_logic_vector(7 downto 0) := x"00";
constant UART_DATA_PORT 	: std_logic_vector(7 downto 0) := x"01";		-- Rx and Tx
constant BOOTH_INDEX_PORT 	: std_logic_vector(7 downto 0) := x"A0";
constant BOOTH_DATA_PORT 	: std_logic_vector(7 downto 0) := x"A1";




------------------------------------------------------------------------------------
-- Start circuit description	
begin

  sys_rst <= '0';		-- TODO: Add an input pin


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

  interrupt <= '0';	-- Interrupt unused



  -- Digital Clock Manager instantiation
  	Inst_my_dcm: my_dcm PORT MAP(
		CLKIN_IN => clk,
		CLKFX_OUT => clk55MHz,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		LOCKED_OUT => open
	);


  --
  ----------------------------------------------------------------------------------------------------------------------------------
  -- KCPSM3 input ports 
  ----------------------------------------------------------------------------------------------------------------------------------
  --
  --
  -- UART FIFO status signals to form a bus
  --

  uart_status_data <= "000" & rx_data_present & rx_full & rx_half_full & tx_full & tx_half_full ;

  --
  -- The inputs connect via a pipelined multiplexer
  --

  input_ports: process(clk55MHz)
  begin
    if clk55MHz'event and clk55MHz='1' then

      case port_id is

        -- read UART status at address 00 hex
        when UART_STATUS_PORT =>    in_port <= uart_status_data;

        -- read UART receive data at address 01 hex
        when UART_DATA_PORT =>    in_port <= rx_data;
		  
		  when BOOTH_INDEX_PORT => in_port <= data_from_booth;
		  when BOOTH_DATA_PORT => in_port <= data_from_booth;
        
        -- Don't care used for all other addresses to ensure minimum logic implementation
        when others =>    in_port <= "XXXXXXXX";  

      end case;


      -- Form read strobe for UART receiver FIFO buffer.
      -- The fact that the read strobe will occur after the actual data is read by 
      -- the KCPSM3 is acceptable because it is really means 'I have read you'!
		if read_strobe='1' and (port_id = UART_DATA_PORT) then
			read_from_uart <= '1';
		else
			read_from_uart <= '0';
		end if;

    end if;

  end process input_ports;



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

  -- Combinatorial logic controlling write strobe for UART
  write_to_uart  <= '1' when (write_strobe='1' and port_id = UART_DATA_PORT) else '0';

  ----------------------------------------------------------------------------------------------------------------------------------
  -- Booth Multiplier peripheral device
  
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
          
          
  ----------------------------------------------------------------------------------------------------------------------------------
  --  ChipScope

  icon : chipscope_icon
  port map (
    CONTROL0 => chipscope_control0);
    
  ila : chipscope_ila
  port map (
    CONTROL => chipscope_control0,
    CLK => clk55MHz,
    TRIG0 => ila_trig0,
    TRIG1 => ila_trig1,
    DATA => ila_data);

  ila_trig0(0) <= read_strobe;                              -- Trig0 is the strobes
  ila_trig0(1) <= write_strobe;
  ila_trig0(2) <= read_strobe or write_strobe;
  ila_trig0(7 downto 3) <= (others => '0');
  
  ila_trig1 <= port_id;                                     -- Trig1 is the port_id (we want to be able to filter on this)
    
  ila_data(7  downto 0)  <= port_id;
  ila_data(15 downto 8)  <= in_port;
  ila_data(23 downto 16) <= out_port;
  ila_data(24) <= read_strobe;
  ila_data(25) <= write_strobe;
  
    
end Behavioral;


