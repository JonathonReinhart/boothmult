library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- Port I/O Register-based interface
-- This generic interface resides on a port I/O bus, and provides a register-based interface,
-- with registers accessed via an "index" port and a "data" port.

entity portio_reg_if is
    generic (
        INDEX_PORT  : positive;  -- 8-bit port ID associated with the "index" or current register.
        DATA_PORT   : positive   -- 8-bit port ID associated with the "data" being read or written.   
    )

    port (
    
    -- System-facing signals
        clk         : in std_logic;     -- System clock
        rst         : in std_logic;     -- System reset (active high)
        
        -- 8-bit port ID, asserted by uProc for reads and writes
        port_id     : in std_logic_vector (7 downto 0);
        
        -- I/O Data being read to uProc
        -- TODO: Will out_port connect to MUX or be Hi-Z and connect directly to uProc?
        out_port    : out std_logic_vector (7 downto 0);    -- 8-bit data out to uProc
        read_strobe : in std_logic;                         -- strobed when uProc is reading from us
        
        -- I/O Data being written from uProc
        in_port     : in std_logic_vector (7 downto 0);     -- 8-bit data in from uProc
        write_strobe: in std_logic;                         -- strobed when uProc is writing to us
        
    -- Consumer-facing signals
        reg_idx     : out std_logic_vector (7 downto 0);    -- 8-bit register "index" currently selected.
        reg_data    : inout std_logic_vector (7 downto 0);  -- 8 bit register "data" being read or written.
        
        reg_read    : out std_logic;    -- Strobed when a register is being read.
        reg_write   : out std_logic    -- Strobed when a register is being written.
    );
end portio_reg_if;
      
      
architecture behavioral of portio_reg_if is
        
begin

    P1 : process (clk, sys_rst) is       
       
    end process P1;

end behavioral;        








