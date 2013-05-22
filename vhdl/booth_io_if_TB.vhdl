library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity booth_io_if_TB is
end booth_io_if_TB;

architecture booth_io_if_TB_Arch of booth_io_if_TB is

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
    
    
-----------    
--- Signals

--- Testbench-driven signals
    -- system/pblaze side
    signal clk         : std_logic := '0';
    signal sys_rst     : std_logic := '0';
    signal port_id     : std_logic_vector (7 downto 0) := (others => 'Z');
    signal port_data_to_if     : std_logic_vector (7 downto 0) := (others => '0');
    signal write_strobe: std_logic := '0';    
    signal read_strobe : std_logic := '0';
    -- boothmult side
    signal done_in     :  std_logic := '0';
    signal product :  std_logic_vector (63 downto 0) := (others => '0');

    
--- Resultant signals from booth_io_if
    -- system/pblaze side
    signal port_data_from_if    : std_logic_vector (7 downto 0);
    -- boothmult side
    signal rst_cmd     : std_logic;
    signal start_cmd   : std_logic;
    signal multiplier : std_logic_vector (31 downto 0);
    signal multiplicand : std_logic_vector (31 downto 0);
    
--- Other signals
    signal product_read : std_logic_vector (63 downto 0) := (others => '0');
    
    
--- Constants
    constant CLK_PER            : time := 20 ns;
    constant INDEX_PORT         : std_logic_vector := x"A0";
    constant DATA_PORT          : std_logic_vector := x"A1";    
    
    

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
    
    UUT : booth_io_if
    port map (
        clk => clk,
        sys_rst => sys_rst,
        port_id => port_id,
        
        out_port => port_data_from_if,
        read_strobe => read_strobe,
        
        in_port => port_data_to_if,
        write_strobe => write_strobe,
        
    --------------------------------------

        rst_cmd => rst_cmd,
        start_cmd => start_cmd,
        done_in => done_in, 
        
        multiplier_out => multiplier,
        multiplicand_out => multiplicand,
        product_in => product
    );


    
-- Test process

    TESTING : process
    begin

        --wait for (CLK_PER/2);
        wait for 3*CLK_PER;
        
    -- Write 1 to RESET bit in COMMAND
        -- 0x01 to reg 0x11
        port_id <= INDEX_PORT;
        port_data_to_if <= x"11";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"01";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- TODO: assert that rst_cmd is driven. But for how long?
        
    -- Write 0xDEADBEEF to MULTIPLIER
        -- 0xEF to reg 0x04
        port_id <= INDEX_PORT;
        port_data_to_if <= x"04";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"EF";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- 0xBE to reg 0x05
        port_id <= INDEX_PORT;
        port_data_to_if <= x"05";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"BE";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- 0xAD to reg 0x06
        port_id <= INDEX_PORT;
        port_data_to_if <= x"06";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"AD";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- 0xDE to reg 0x07
        port_id <= INDEX_PORT;
        port_data_to_if <= x"07";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"DE";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        assert multiplier = x"DEADBEEF" report "Multiplier not DEADBEEF" severity error;
        
        
    -- Write 0x1337D00D to MULTIPLICAND
        -- 0x0D to reg 0x00
        port_id <= INDEX_PORT;
        port_data_to_if <= x"00";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"0D";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- 0xD0 to reg 0x01
        port_id <= INDEX_PORT;
        port_data_to_if <= x"01";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"D0";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- 0x37 to reg 0x02
        port_id <= INDEX_PORT;
        port_data_to_if <= x"02";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"37";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        -- 0x13 to reg 0x03
        port_id <= INDEX_PORT;
        port_data_to_if <= x"03";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"13";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
        assert multiplicand = x"1337D00D" report "Multiplicand not 1337D00D" severity error;

    -- Write 1 to START bit in COMMAND
        -- 0x02 to reg 0x11
        port_id <= INDEX_PORT;
        port_data_to_if <= x"11";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= x"02";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        
    -- Read STATUS register (simulate waiting for operation to complete)
        for i in 0 to 4 loop
            -- read reg 0x10
            port_id <= INDEX_PORT;
            port_data_to_if <= x"10";
            write_strobe <= '1', '0' after CLK_PER;
            wait for 2*CLK_PER;
            port_id <= DATA_PORT;
            port_data_to_if <= (others => 'Z');
            read_strobe <= '1', '0' after CLK_PER;
            wait for 2*CLK_PER;
        end loop;
        
    -- Simulate completion.
        product <= x"CAFEBABEB00B1EE5";
        done_in <= '1';
        wait for 2*CLK_PER;
    
    -- Read STATUS register
        -- read reg 0x10
        port_id <= INDEX_PORT;
        port_data_to_if <= x"10";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;

    -- Read 64-bit PRODUCT register into product_read temp signal.
        -- read reg 0x08
        port_id <= INDEX_PORT;
        port_data_to_if <= x"08";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(7 downto 0) <= port_data_from_if;
        wait for CLK_PER;
        
        -- read reg 0x09
        port_id <= INDEX_PORT;
        port_data_to_if <= x"09";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(15 downto 8) <= port_data_from_if;
        wait for CLK_PER;
        
        -- read reg 0x0A
        port_id <= INDEX_PORT;
        port_data_to_if <= x"0A";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(23 downto 16) <= port_data_from_if;
        wait for CLK_PER;
        
        -- read reg 0x0B
        port_id <= INDEX_PORT;
        port_data_to_if <= x"0B";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(31 downto 24) <= port_data_from_if;
        wait for CLK_PER;
        
        -- read reg 0x0C
        port_id <= INDEX_PORT;
        port_data_to_if <= x"0C";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(39 downto 32) <= port_data_from_if;
        wait for CLK_PER;

        -- read reg 0x0D
        port_id <= INDEX_PORT;
        port_data_to_if <= x"0D";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(47 downto 40) <= port_data_from_if;
        wait for CLK_PER;
        
        -- read reg 0x0E
        port_id <= INDEX_PORT;
        port_data_to_if <= x"0E";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(55 downto 48) <= port_data_from_if;
        wait for CLK_PER;
        
        -- read reg 0x0F
        port_id <= INDEX_PORT;
        port_data_to_if <= x"0F";
        write_strobe <= '1', '0' after CLK_PER;
        wait for 2*CLK_PER;
        port_id <= DATA_PORT;
        port_data_to_if <= (others => 'Z');
        read_strobe <= '1', '0' after CLK_PER;
        wait for CLK_PER;
        product_read(63 downto 56) <= port_data_from_if;
        wait for CLK_PER;
        
        assert product_read = x"CAFEBABEB00B1EE5" report "product_read not CAFEBABEB00B1EE5" severity error;
        
        
        
        wait;
        
    end process TESTING;

end booth_io_if_TB_Arch;