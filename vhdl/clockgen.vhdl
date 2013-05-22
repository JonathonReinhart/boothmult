library ieee;
use ieee.std_logic_1164.all;

entity clockgen is
    port ( clk : out std_logic );
end clockgen;

architecture behavioral of clockgen is
begin
    run: process
    begin
    
        clk <= '1';
        wait for 50 ns;
        
        clk <= '0';
        wait for 50 ns;
    
    end process run;

end behavioral;