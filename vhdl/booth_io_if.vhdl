library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Booth Multiplier I/O interface
-- Connects the Booth Multiplier to the rest of the system, designed around the PicoBlaze
entity booth_io_if is
	generic (
		N : positive := 32									-- Factor bit width
		);

	
	port (
	-- PicoBlaze-facing/system	signals
		clk			: in std_logic;							-- System clock (50 MHz)
		sys_rst		: in std_logic;							-- System Reset (active high)
		port_id		: in std_logic_vector (7 downto 0);		-- Port ID, asserted by pBlaze
		
		-- I/O Data from BM module to pBlaze
		out_port	: out std_logic_vector (7 downto 0);	-- 8-bit data out to pBlaze
		read_strobe : in std_logic;							-- strobed when pBlaze is reading from us
		
		-- I/O Data from pBlaze to BM module
		in_port		: in std_logic_vector (7 downto 0);		-- 8-bit data in from pBlaze
		write_strobe: in std_logic;							-- strobed when pBlaze is writing to us
		
	--------------------------------------
	
	-- Booth Mutliplier (Internal) signals
		-- Asserted by IO/IF when reset command is rcvd
		rst_cmd		: out std_logic;		  

		-- Asserted by IO/IF when multiplier/multiplicand are valid and an operation should begin
		start_cmd	: out std_logic;

		-- Asserted by multiplier when operation is finished and product is valid
		done_in		: in  std_logic;						
		
		-- "Multiplier" input value, out to multiplier
		multiplier_out : out std_logic_vector (N-1 downto 0);
		
		-- "Multiplicand" input value, out to multiplier
		multiplicand_out : out std_logic_vector (N-1 downto 0);
		
		-- "Product" result from multiplier
		product_in : in	 std_logic_vector ((2*N)-1 downto 0)
		);
end booth_io_if;


architecture behavioral of booth_io_if is

    -- Port IDs associated with this device
	constant INDEX_PORT			: std_logic_vector(7 downto 0) := x"A0";
	constant DATA_PORT			: std_logic_vector(7 downto 0) := x"A1";

	-- Register index constants
	constant REG_MULTIPLICAND_0 : std_logic_vector(7 downto 0) := x"00";  -- LSB
	constant REG_MULTIPLICAND_1 : std_logic_vector(7 downto 0) := x"01";
	constant REG_MULTIPLICAND_2 : std_logic_vector(7 downto 0) := x"02";
	constant REG_MULTIPLICAND_3 : std_logic_vector(7 downto 0) := x"03";  -- MSB
	
	constant REG_MULTIPLIER_0	: std_logic_vector(7 downto 0) := x"04";  -- LSB
	constant REG_MULTIPLIER_1	: std_logic_vector(7 downto 0) := x"05";
	constant REG_MULTIPLIER_2	: std_logic_vector(7 downto 0) := x"06";
	constant REG_MULTIPLIER_3	: std_logic_vector(7 downto 0) := x"07";  -- MSB
	
	constant REG_PRODUCT_0		: std_logic_vector(7 downto 0) := x"08";  -- LSB
	constant REG_PRODUCT_1		: std_logic_vector(7 downto 0) := x"09";
	constant REG_PRODUCT_2		: std_logic_vector(7 downto 0) := x"0A";
	constant REG_PRODUCT_3		: std_logic_vector(7 downto 0) := x"0B";
	constant REG_PRODUCT_4		: std_logic_vector(7 downto 0) := x"0C";
	constant REG_PRODUCT_5		: std_logic_vector(7 downto 0) := x"0D";
	constant REG_PRODUCT_6		: std_logic_vector(7 downto 0) := x"0E";
	constant REG_PRODUCT_7		: std_logic_vector(7 downto 0) := x"0F";  -- MSB
	
	constant REG_STATUS			: std_logic_vector(7 downto 0) := x"10";
	constant REG_CTRL			: std_logic_vector(7 downto 0) := x"11";
	
	constant CTRL_RESET_BIT		: integer := 0;
	constant CTRL_START_BIT		: integer := 1;
	

	signal curreg				: std_logic_vector (7 downto 0);	-- currently selected register idx.
	signal curreg_value			: std_logic_vector (7 downto 0);	-- the value of cur. sel. register
	
	--- Our registers, "visible" to pBlaze
	signal MULTIPLICAND			: std_logic_vector (N-1 downto 0);
	signal MULTIPLIER			: std_logic_vector (N-1 downto 0);
	signal PRODUCT				: std_logic_vector((2*N)-1 downto 0) := (others => '1');
	
	signal STATUS				: std_logic_vector (7 downto 0) := (others => '0');
	alias  STATUS0_BUSY			is STATUS(0);
	alias  STATUS1_PROD_VALID	is STATUS(1);
	


begin

    -- curreg_value is always the value of the currently selected value.
	with curreg select
		curreg_value <= 
			MULTIPLICAND(7	downto 0 )	when REG_MULTIPLICAND_0,	-- LSB
			MULTIPLICAND(15 downto 8 )	when REG_MULTIPLICAND_1,
			MULTIPLICAND(23 downto 16)	when REG_MULTIPLICAND_2,	
			MULTIPLICAND(31 downto 24)	when REG_MULTIPLICAND_3,	-- MSB
			
			MULTIPLIER(7  downto 0 )	when REG_MULTIPLIER_0,		-- LSB
			MULTIPLIER(15 downto 8 )	when REG_MULTIPLIER_1,		
			MULTIPLIER(23 downto 16)	when REG_MULTIPLIER_2,		
			MULTIPLIER(31 downto 24)	when REG_MULTIPLIER_3,		-- MSB
			
			PRODUCT(7  downto 0 )		when REG_PRODUCT_0,			-- LSB
			PRODUCT(15 downto 8 )		when REG_PRODUCT_1,
			PRODUCT(23 downto 16)		when REG_PRODUCT_2,
			PRODUCT(31 downto 24)		when REG_PRODUCT_3,
			PRODUCT(39 downto 32)		when REG_PRODUCT_4,
			PRODUCT(47 downto 40)		when REG_PRODUCT_5,
			PRODUCT(55 downto 48)		when REG_PRODUCT_6,
			PRODUCT(63 downto 56)		when REG_PRODUCT_7,			-- MSB
			
			STATUS						when REG_STATUS,
			(others => '1')				when others;				-- Invalid	
	
    -- Set out_port data, depending on the active port_id.
    with port_id select
        out_port <=
            curreg              when INDEX_PORT,
            curreg_value        when DATA_PORT,
            (others => '1')     when others;
    


    
    
	P1 : process (clk) is
		
		variable reset_regs_to_defaults : boolean;
		
		-- Number of clocks to hold command outputs high
		variable start_cmd_ct : integer := 0;
		variable reset_cmd_ct : integer := 0;
	
	
	begin
		-- Reset these temporaries every time the process is entered
		if rising_edge(clk) then
			reset_regs_to_defaults := false;

		
			if sys_rst='1' then
				reset_regs_to_defaults := true;
			else	-- sys_rst='1'
		
			
			--------------------------------------------------------------------------------------------
			-- pBlaze I/O
					
				-- Write (OUTPUT) operation from pBlaze?
				if (write_strobe='1') then
				
					-- What port is pBlaze writing to
					if (port_id = INDEX_PORT) then		    -- Index port
						curreg <= in_port;
						
					elsif (port_id = DATA_PORT) then		-- Data port
						-- Store incoming data to register, depending on currently selected reg number.
						-- TODO: Forbid writes to everything but RESET if STATUS0_BUSY
						case curreg is
							when REG_MULTIPLICAND_0		=>	MULTIPLICAND(7	downto 0 ) <= in_port;	-- LSB
							when REG_MULTIPLICAND_1		=>	MULTIPLICAND(15 downto 8 ) <= in_port;
							when REG_MULTIPLICAND_2		=>	MULTIPLICAND(23 downto 16) <= in_port;
							when REG_MULTIPLICAND_3		=>	MULTIPLICAND(31 downto 24) <= in_port;	-- MSB
							
							when REG_MULTIPLIER_0		=>	MULTIPLIER(7  downto 0 ) <= in_port;	-- LSB
							when REG_MULTIPLIER_1		=>	MULTIPLIER(15 downto 8 ) <= in_port;
							when REG_MULTIPLIER_2		=>	MULTIPLIER(23 downto 16) <= in_port;
							when REG_MULTIPLIER_3		=>	MULTIPLIER(31 downto 24) <= in_port;	-- MSB
							
							when REG_PRODUCT_0			=>	PRODUCT(7  downto 0 ) <= in_port;		-- LSB
							when REG_PRODUCT_1			=>	PRODUCT(15 downto 8 ) <= in_port;
							when REG_PRODUCT_2			=>	PRODUCT(23 downto 16) <= in_port;
							when REG_PRODUCT_3			=>	PRODUCT(31 downto 24) <= in_port;
							when REG_PRODUCT_4			=>	PRODUCT(39 downto 32) <= in_port;
							when REG_PRODUCT_5			=>	PRODUCT(47 downto 40) <= in_port;
							when REG_PRODUCT_6			=>	PRODUCT(55 downto 48) <= in_port;
							when REG_PRODUCT_7			=>	PRODUCT(63 downto 56) <= in_port;		-- MSB
							
							when REG_CTRL				=> 
								-- Check which bits are being written to.
								if (in_port(CTRL_RESET_BIT) = '1') then
									reset_cmd_ct := 3;
									reset_regs_to_defaults := true;
									
								elsif (in_port(CTRL_START_BIT) = '1') then
                                    start_cmd_ct := 3;
									STATUS0_BUSY <= '1';
									
								end if;
								
							when others					=>	null;			 -- Invalid reg, do nothing
						end case;
						
						-- Also, any time pBlaze writes to a register, we clear the PROD_VALID flag.
						STATUS1_PROD_VALID <= '0';
						
					else	-- Port not for us!
					
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
				if (reset_cmd_ct > 0) then
					reset_cmd_ct := reset_cmd_ct - 1;
					rst_cmd <= '1';
				else
					rst_cmd <= '0';
				end if;
				 
				if (start_cmd_ct > 0) then
					start_cmd_ct := start_cmd_ct - 1;
					start_cmd <= '1';
				else
					start_cmd <= '0';
				end if;

			end if;		-- else sys_rst='1'
		
		
			if (reset_regs_to_defaults) then
				-- Reset all of our registers to their defaults
				curreg				<= (others => '0');
				MULTIPLICAND		<= (others => '0');
				MULTIPLIER			<= (others => '0');
				PRODUCT				<= (others => '1');
				STATUS				<= (others => '0');

				start_cmd <= '0';
				start_cmd_ct := 0;
				-- Don't reset 'rst_cmd_ct', it must remain active to drive rst_cmd.
			end if;
		
		end if;	 -- rising_edge(clk)

	 
	end process P1;
	 

	multiplicand_out	<= MULTIPLICAND;
	multiplier_out		<= MULTIPLIER;

end behavioral;

