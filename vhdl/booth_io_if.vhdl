library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Booth Multiplier I/O interface
-- Connects the Booth Multiplier to the rest of the system, designed around the PicoBlaze
entity booth_io_if is
    generic (
        N : positive := 32                                  -- Factor bit width
        );

    
    port (
    -- PicoBlaze-facing/system  signals
        clk         : in std_logic;                         -- System clock (50 MHz)
        sys_rst     : in std_logic;                         -- System Reset (active high)
        port_id     : in std_logic_vector (7 downto 0);     -- Port ID, asserted by pBlaze
        
        -- I/O Data from BM module to pBlaze
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
end booth_io_if;


architecture behavioral of booth_io_if is

    constant INDEX_PORT         : unsigned := x"A0";
    constant DATA_PORT          : unsigned := x"A1";

    -- Register index constants
    constant REG_MULTIPLICAND_0 : std_logic_vector(7 downto 0) := x"00";  -- LSB
    constant REG_MULTIPLICAND_1 : std_logic_vector(7 downto 0) := x"01";
    constant REG_MULTIPLICAND_2 : std_logic_vector(7 downto 0) := x"02";
    constant REG_MULTIPLICAND_3 : std_logic_vector(7 downto 0) := x"03";  -- MSB
    
    constant REG_MULTIPLIER_0   : std_logic_vector(7 downto 0) := x"04";  -- LSB
    constant REG_MULTIPLIER_1   : std_logic_vector(7 downto 0) := x"05";
    constant REG_MULTIPLIER_2   : std_logic_vector(7 downto 0) := x"06";
    constant REG_MULTIPLIER_3   : std_logic_vector(7 downto 0) := x"07";  -- MSB
    
    constant REG_PRODUCT_0      : std_logic_vector(7 downto 0) := x"08";  -- LSB
    constant REG_PRODUCT_1      : std_logic_vector(7 downto 0) := x"09";
    constant REG_PRODUCT_2      : std_logic_vector(7 downto 0) := x"0A";
    constant REG_PRODUCT_3      : std_logic_vector(7 downto 0) := x"0B";
    constant REG_PRODUCT_4      : std_logic_vector(7 downto 0) := x"0C";
    constant REG_PRODUCT_5      : std_logic_vector(7 downto 0) := x"0D";
    constant REG_PRODUCT_6      : std_logic_vector(7 downto 0) := x"0E";
    constant REG_PRODUCT_7      : std_logic_vector(7 downto 0) := x"0F";  -- MSB
    
    constant REG_STATUS         : std_logic_vector(7 downto 0) := x"10";
    constant REG_CTRL           : std_logic_vector(7 downto 0) := x"11";
    
    constant CTRL_RESET_BIT     : integer := 0;
    constant CTRL_START_BIT     : integer := 1;
    
    -- currently selected register (via "index" port)
    signal curreg               : std_logic_vector (7 downto 0);
    
    --- Our registers, "visible" to pBlaze
    signal MULTIPLICAND         : std_logic_vector (N-1 downto 0);
    signal MULTIPLIER           : std_logic_vector (N-1 downto 0);
    signal PRODUCT              : std_logic_vector((2*N)-1 downto 0) := (others => '1');
    
    signal STATUS               : std_logic_vector (7 downto 0) := (others => '0');
    alias  STATUS0_BUSY         is STATUS(0);
    alias  STATUS1_PROD_VALID   is STATUS(1);
    
begin

    --P1 : process (clk, sys_rst) is
    P1 : process (clk) is
        
        variable reset_regs_to_defaults : boolean;
        
		  variable start_cmd_active : boolean := false;
		  variable reset_cmd_active : boolean := false;
		  
		  variable cmd_clk_count : integer := 0;
    
    
    begin
        -- Reset these temporaries every time the process is entered
        if rising_edge(clk) then
            reset_regs_to_defaults := false;
            --reset_command_received := false;
            --start_cmd_active := false;

        
            if sys_rst='1' then
                reset_regs_to_defaults := true;
                --rst_cmd <= '0';     -- Special case, so he can be driven for one clock during reset command.
            
            else    -- sys_rst='1'
        
            
            --------------------------------------------------------------------------------------------
            -- pBlaze I/O
            
                -- Read (INPUT) operation from pBlaze - Assume this is always happening, ignore timing on read_strobe.
                -- What port is pBlaze reading from
                if (unsigned(port_id) = INDEX_PORT) then        -- Index port
                    out_port <= curreg;
                    
                elsif (unsigned(port_id) = DATA_PORT) then      -- Data port
                    -- Reply with data, depending on current register index
                    case curreg is
                        when REG_MULTIPLICAND_0     =>  out_port <= MULTIPLICAND(7  downto 0 ); -- LSB
                        when REG_MULTIPLICAND_1     =>  out_port <= MULTIPLICAND(15 downto 8 );
                        when REG_MULTIPLICAND_2     =>  out_port <= MULTIPLICAND(23 downto 16);
                        when REG_MULTIPLICAND_3     =>  out_port <= MULTIPLICAND(31 downto 24); -- MSB
                        
                        when REG_MULTIPLIER_0       =>  out_port <= MULTIPLIER(7  downto 0 );   -- LSB
                        when REG_MULTIPLIER_1       =>  out_port <= MULTIPLIER(15 downto 8 );
                        when REG_MULTIPLIER_2       =>  out_port <= MULTIPLIER(23 downto 16);
                        when REG_MULTIPLIER_3       =>  out_port <= MULTIPLIER(31 downto 24);   -- MSB
                        
                        when REG_PRODUCT_0          =>  out_port <= PRODUCT(7  downto 0 );      -- LSB
                        when REG_PRODUCT_1          =>  out_port <= PRODUCT(15 downto 8 );
                        when REG_PRODUCT_2          =>  out_port <= PRODUCT(23 downto 16);
                        when REG_PRODUCT_3          =>  out_port <= PRODUCT(31 downto 24);
                        when REG_PRODUCT_4          =>  out_port <= PRODUCT(39 downto 32);
                        when REG_PRODUCT_5          =>  out_port <= PRODUCT(47 downto 40);
                        when REG_PRODUCT_6          =>  out_port <= PRODUCT(55 downto 48);
                        when REG_PRODUCT_7          =>  out_port <= PRODUCT(63 downto 56);      -- MSB
                        
                        when REG_STATUS             =>  out_port <= STATUS;                        
                        when others                 =>  out_port <= (others => '1');            -- Invalid
                    end case;
                    
                else    -- Port not for us!
                    out_port <= (others => 'Z');
                end if;
                    
                -- Write (OUTPUT) operation from pBlaze?
                if (write_strobe='1') then
                
                    -- What port is pBlaze writing to
                    if (unsigned(port_id) = INDEX_PORT) then        -- Index port
                        curreg <= in_port;
                        
                    elsif (unsigned(port_id) = DATA_PORT) then      -- Data port
                        -- Store incoming data to register, depending on currently selected reg number.
                        -- TODO: Forbid writes to everything but RESET if STATUS0_BUSY
                        case curreg is
                            when REG_MULTIPLICAND_0     =>  MULTIPLICAND(7  downto 0 ) <= in_port;  -- LSB
                            when REG_MULTIPLICAND_1     =>  MULTIPLICAND(15 downto 8 ) <= in_port;
                            when REG_MULTIPLICAND_2     =>  MULTIPLICAND(23 downto 16) <= in_port;
                            when REG_MULTIPLICAND_3     =>  MULTIPLICAND(31 downto 24) <= in_port;  -- MSB
                            
                            when REG_MULTIPLIER_0       =>  MULTIPLIER(7  downto 0 ) <= in_port;    -- LSB
                            when REG_MULTIPLIER_1       =>  MULTIPLIER(15 downto 8 ) <= in_port;
                            when REG_MULTIPLIER_2       =>  MULTIPLIER(23 downto 16) <= in_port;
                            when REG_MULTIPLIER_3       =>  MULTIPLIER(31 downto 24) <= in_port;    -- MSB
                            
                            when REG_PRODUCT_0          =>  PRODUCT(7  downto 0 ) <= in_port;       -- LSB
                            when REG_PRODUCT_1          =>  PRODUCT(15 downto 8 ) <= in_port;
                            when REG_PRODUCT_2          =>  PRODUCT(23 downto 16) <= in_port;
                            when REG_PRODUCT_3          =>  PRODUCT(31 downto 24) <= in_port;
                            when REG_PRODUCT_4          =>  PRODUCT(39 downto 32) <= in_port;
                            when REG_PRODUCT_5          =>  PRODUCT(47 downto 40) <= in_port;
                            when REG_PRODUCT_6          =>  PRODUCT(55 downto 48) <= in_port;
                            when REG_PRODUCT_7          =>  PRODUCT(63 downto 56) <= in_port;       -- MSB
                            
                            when REG_CTRL               => 
                                -- Check which bits are being written to.
                                if (in_port(CTRL_RESET_BIT) = '1') then
                                    reset_cmd_active := true;
												cmd_clk_count := 3;
                                    reset_regs_to_defaults := true;
                                    
                                elsif (in_port(CTRL_START_BIT) = '1') then
                                    start_cmd_active := true;
												cmd_clk_count := 3;
                                    STATUS0_BUSY <= '1';
                                    
                                end if;
                                
                            when others                 =>  null;            -- Invalid reg, do nothing
                        end case;
                        
                        -- Also, any time pBlaze writes to a register, we clear the PROD_VALID flag.
                        STATUS1_PROD_VALID <= '0';
                        
                    else    -- Port not for us!
                    
                    end if; -- port_id
                
                end if; -- write_strobe
            
                
            --------------------------------------------------------------------------------------------
            -- Multiplier I/O
                
                -- Finished?
                if (done_in='1') then
                    -- When the multiplier indicates it is finished, save the result to the register,
                    -- and update the status bits.
                    PRODUCT <= product_in;
                    STATUS0_BUSY <= '0';
                    STATUS1_PROD_VALID <= '1';
                end if;
                
            ------------------------------
            -- Update outputs
					 
					 if cmd_clk_count > 0 then
					     cmd_clk_count := cmd_clk_count - 1;
				    else
					     start_cmd_active := false;
						  reset_cmd_active := false;
				    end if;
					 
					 
					 if start_cmd_active then start_cmd <= '1'; else start_cmd <= '0'; end if;
					 if reset_cmd_active then rst_cmd <= '1'; else rst_cmd <= '0'; end if;
					 


            end if;     -- else sys_rst='1'
        
        
            if (reset_regs_to_defaults) then
                -- Reset all of our registers to their defaults
                curreg              <= (others => '0');
                MULTIPLICAND        <= (others => '0');
                MULTIPLIER          <= (others => '0');
                PRODUCT             <= (others => '1');
                STATUS              <= (others => '0');
                start_cmd <= '0';
                out_port <= (others => 'Z');
		
					 start_cmd_active := false;
					 --cmd_clk_count := 0;				-- These cannot be reset, because they're driving the reset signal
					 --reset_cmd_active := false;
            end if;
        
        end if;  -- rising_edge(clk)

	 
    end process P1;
	 

    
    
    multiplicand_out    <= MULTIPLICAND;
    multiplier_out      <= MULTIPLIER;

end behavioral;

