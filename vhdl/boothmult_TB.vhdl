library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boothmult_TB is
end boothmult_TB;

architecture boothmult_TB_Arch of boothmult_TB is
--- Components    
    component clockgen is
        generic (
            PERIOD : time := 20 ns;
            RST_DUR : integer := 2
        );
        port (         
            clk : out std_logic;
            rst : out std_logic
        );
    end component;
    
    component boothmult is
    generic (
        N : positive := 32                                  -- Factor bit width
        );
		    
    port (
    -- PicoBlaze-facing/system  signals
        clk         : in std_logic;                         -- System clock (50 MHz)
        reset     : in std_logic;                         -- System Reset (active high)
        
        multiplier      : in  std_logic_vector(N-1 downto 0);
        multiplicand    : in  std_logic_vector(N-1 downto 0);
        product         : out std_logic_vector((2*N)-1 downto 0);
        start           : in  std_logic;
        done            : out std_logic
        );
    end component;
	    
-----------    
--- Signals

--- Testbench-driven signals
    -- system/pblaze side
    signal clk         : std_logic := '0';
    signal sys_rst     : std_logic := '0';
    signal write_strobe: std_logic := '0';    
    signal read_strobe : std_logic := '0';
    -- boothmult side
	signal breset      : std_logic := '0';
    signal done_out     :  std_logic;
    signal product :  std_logic_vector (63 downto 0);
    
--- Resultant signals from booth_io_if
    -- boothmult side
    signal rst_cmd     : std_logic;
    signal start_cmd   : std_logic;
    signal tst_multiplier : std_logic_vector (31 downto 0);
    signal tst_multiplicand : std_logic_vector (31 downto 0);
    
--- Other signals
    signal product_read : std_logic_vector (63 downto 0) := (others => '0');
    
--- Constants
    constant CLK_PER            : time := 20 ns;

begin


-- Instantiated components
    CLOCK : clockgen
    generic map (
        PERIOD => CLK_PER,
        RST_DUR => 2
    )
    port map (
        clk => clk,
        rst => sys_rst
    );
	
    UUT : boothmult
    generic map ( N => 32 )
    port map (
        clk => clk,
        reset => breset, --sys_rst,
        multiplier => tst_multiplier,
        multiplicand  => tst_multiplicand,
        product         => product_read,
        start         => start_cmd,
        done            => done_out
        
    );
TESTING : process
begin
  start_cmd <= '0';
  breset <= '0';
  wait for 3*CLK_PER;
  
  --write reset
  breset <= '1';
  wait for 5*CLK_PER;
  
  --write to multiplier and multiplicand
  tst_multiplier <= x"00031337";
  tst_multiplicand <= x"7FFFFFFF";
  wait for 5*CLK_PER;
  
  --Start it up
  breset <= '0';
  wait for CLK_PER;
  start_cmd <= '1';
  wait for 3*CLK_PER;
  
  start_cmd <= '0';
  
	wait;
        
end process TESTING;
       
end boothmult_TB_Arch;