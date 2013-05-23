library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
use IEEE.NUMERIC_STD.all;

entity boothmult is
    generic (
        N : positive := 32
    );
    port    (
	    clk, reset      : in  std_logic;
        multiplier      : in  std_logic_vector(N-1 downto 0);
        multiplicand    : in  std_logic_vector(N-1 downto 0);
        product         : out std_logic_vector((2*N)-1 downto 0);
        start           : in  std_logic;
        done            : out std_logic
    );
end boothmult;

architecture boothmultarch of boothmult is

    signal a, s, p : SIGNED((2*N) downto 0);
	signal pp : signed((2*N)-1 downto 0);
	signal dd : unsigned(0 downto 0);

begin

    done <= '0';
	a(2*N downto N+1) <= signed(multiplicand(N-1 downto 0));
	a(N downto 0) <= (others => '0');
	s(2*N downto N+1) <= signed(not(multiplicand(N-1 downto 0))) + 1;
	s(N downto 0) <= (others => '0');
	p(2*N downto N+1) <= (others => '0');
	p(N downto 1) <= signed(multiplier(N-1 downto 0));
	p(0) <= '0';
	
mult: process(clk,reset)
  variable count : integer := 0;
  variable todo  : signed(1 downto 0);
  variable letsgo : integer range 0 to 1 := 0;
  variable ppp : signed((2*N) downto 0) := p;
  variable ddd  : unsigned(0 downto 0);
begin
  
  --testing code
  todo := ppp(1) & ppp(0);
  
  if (reset = '1') then
    ppp := p;
    count := 0;
    ddd := "0";
  elsif (start = '0') then
    ppp := p;
    count := 0;
    ddd := "0";
  elsif (count = N) then
    ppp := ppp;
    ddd := "1";
  elsif (clk'event and clk = '1') then
    ddd := "0";
    if (todo = "01") then
      ppp := ppp + a;
    elsif (todo = "10") then
      ppp := ppp + s;
    elsif (todo = "00") then
      ppp := ppp;
    elsif (todo = "11") then
      ppp := ppp;
    end if;
    count := count + 1;
    ppp := shift_right(ppp,1);
    --ppp := ppp sra 1;
  end if;
   
   pp(2*N-1 downto 0) <= ppp(2*N downto 1);
   dd <= ddd;
   
end process;

   --product <= std_logic_vector(s(2*N downto 1));
   
    product((2*N)-1) <= multiplier(N-1) xor multiplicand(N-1);
    product((2*N-2) downto 0) <= std_logic_vector(pp((2*N-2) downto 0));
    done <= std_logic(dd(0));

end boothmultarch;


