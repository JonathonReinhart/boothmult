library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_entity_TB is
end top_level_entity_TB;

architecture top_level_entity_TB_Arch of top_level_entity_TB is

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
    
    component top_level_entity is
        port (   
            clk : in std_logic;
             tx : out std_logic;
             rx : in std_logic );
    end component;
    
    
    
-----------    
--- Signals

--- Testbench-driven signals
    signal clk         : std_logic := '0';
    signal sys_rst     : std_logic := '0';    
    
--- Constants
    constant CLK_PER            : time := 20 ns;
   
    
    

begin

-- Instantiated components
    CLOCK : clockgen
    generic map (
        PERIOD => CLK_PER,
        RST_DUR => 3
    )
    port map (
        clk => clk,
        rst => sys_rst
    );
    
    UUT : top_level_entity
    port map (
        clk => clk,
        tx => open,
        rx => '0'
    );


-- Test process

    TESTING : process
    begin


        wait;
        
    end process TESTING;

end top_level_entity_TB_Arch;