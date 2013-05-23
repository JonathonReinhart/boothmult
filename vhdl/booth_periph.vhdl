library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Booth Mutliplier, as to be connected to I/O interface of PicoBlaze
-- Essentially just a wrapper for booth_io_if and boothmult.
entity booth_periph is
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
end booth_periph;


architecture behavioral of booth_periph is

-- Components
    component booth_io_if is
        generic (
            N : positive := 32                                  -- Factor bit width
            );

        
        port (
        -- PicoBlaze-facing/system  signals
            clk         : in std_logic;                         -- System clock (50 MHz)
            sys_rst     : in std_logic;                         -- System Reset (active high)
            port_id     : in std_logic_vector (7 downto 0);     -- Port ID, asserted by pBlaze
            
            -- I/O Data from BM module to pBlaze
            -- TODO: Will out_port connect to MUX or be Hi-Z and connect directly to pBlaze?
            out_port    : out std_logic_vector (7 downto 0);    -- 8-bit data out to pBlaze
            read_strobe : in std_logic;                         -- strobed when pBlaze is reading from us
            
            -- I/O Data from pBlaze to BM module
            in_port     : in std_logic_vector (7 downto 0);     -- 8-bit data in from pBlaze
            write_strobe: in std_logic;                         -- strobed when pBlaze is writing to us
            
        --------------------------------------
        
        -- Booth Mutliplier (Internal) signals
            -- Asserted by IO/IF when reset command is rcvd
            rst_cmd     : out std_logic;          

            -- Asserted by IO/IF when multiplier/multiplicand are valid and an operation should begin
            start_cmd   : out std_logic;

            -- Asserted by multiplier when operation is finished and product is valid
            done_in     : in  std_logic;                        
            
            -- "Multiplier" input value, out to multiplier
            multiplier_out : out std_logic_vector (N-1 downto 0);
            
            -- "Multiplicand" input value, out to multiplier
            multiplicand_out : out std_logic_vector (N-1 downto 0);
            
            -- "Product" result from multiplier
            product_in : in  std_logic_vector ((2*N)-1 downto 0)
            );
    end component;
    
    -- TODO: boothmult goes here


-- Signals
-- For connecting I/O interface to multiplier

    signal mult_reset   : std_logic;
    -- io_if -> mult
    signal rst_cmd      : std_logic;
    signal mult_start   : std_logic;
    signal multiplier   : std_logic_vector (N-1 downto 0);
    signal multiplicand : std_logic_vector (N-1 downto 0);
    -- io_if <- mult
    signal mult_done    : std_logic;
    signal product      : std_logic_vector ((2*N)-1 downto 0);
    
    

begin

    io_if: booth_io_if
    port map (
    -- PicoBlaze-facing/system  signals
        clk => clk,
        sys_rst => sys_rst,
        port_id => port_id,
        out_port => out_port,
        read_strobe => read_strobe,
        in_port => in_port,
        write_strobe => write_strobe,
    -- Booth Mutliplier (Internal) signals   
        rst_cmd => rst_cmd,
        start_cmd => mult_start,
        done_in => mult_done,
        multiplier_out => multiplier,
        multiplicand_out => multiplicand,
        product_in => product
        );

    mult_reset <= rst_cmd or sys_rst;   -- Reset the multiplier with a reset cmd or system reset
        
        
    -- TODO: instantiate boothmult here        
        
end behavioral;

