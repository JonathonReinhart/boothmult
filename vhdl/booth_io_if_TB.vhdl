library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity booth_io_if_TB is
end booth_io_if_TB;

architecture booth_io_if_TB_Arch of booth_io_if_TB is

--- Components    
    component clockgen is
        port (         
            clk : out std_logic;
            rst : out std_logic
        );
    end component;
    
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
    
    
    
--- Signals    
    signal clk         : std_logic;
    signal sys_rst     : std_logic;
    signal port_id     : std_logic_vector (7 downto 0);
        
    signal out_port    : std_logic_vector (7 downto 0);
    signal read_strobe : std_logic;
        
    signal in_port     : std_logic_vector (7 downto 0);
    signal write_strobe: std_logic;
        
    --------------------------------------
    
    signal rst_cmd     : std_logic;          
    signal start_cmd   : std_logic;
    signal done_in     :  std_logic;                        
    signal multiplier_out : std_logic_vector (31 downto 0);
    signal multiplicand_out : std_logic_vector (31 downto 0);
    signal product_in :  std_logic_vector (63 downto 0);
    
    
--- Constants
    constant INDEX_PORT         : std_logic_vector := x"A0";
    constant DATA_PORT          : std_logic_vector := x"A1";    
    

begin

-- Instantiated components
    CLOCK : clockgen
    port map (
        clk => clk,
        rst => sys_rst
    );
    
    UUT : booth_io_if
    port map (
        clk => clk,
        sys_rst => sys_rst,
        port_id => port_id,
        
        out_port => out_port,
        read_strobe => read_strobe,
        
        in_port => in_port,
        write_strobe => write_strobe,
        
    --------------------------------------

        rst_cmd => rst_cmd,
        start_cmd => start_cmd,
        done_in => done_in, 
        
        multiplier_out => multiplier_out,
        multiplicand_out => multiplicand_out,
        product_in => product_in
    );


    
-- Test process

    TESTING : process
    begin

        wait for 60 ns;
        port_id <= INDEX_PORT;

        wait;
        
    end process TESTING;

end booth_io_if_TB_Arch;