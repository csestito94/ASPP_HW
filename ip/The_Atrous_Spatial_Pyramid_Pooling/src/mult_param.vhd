-- This registered multiplier performs the product between an unsigned bit vector 
-- and a signed bit vector. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mult_param is
    generic (N: integer:= 8);
    port ( 
    clock: in std_logic;
    reset: in std_logic;
    clock_enable: in std_logic;
    a: in std_logic_vector(N-1 downto 0); -- N bit unsigned
    b: in std_logic_vector(N-1 downto 0); -- N bit signed
    p: out std_logic_vector(2*N-1 downto 0)
    );
end mult_param;

architecture arch_mult_param of mult_param is

attribute use_dsp : string;
attribute use_dsp of arch_mult_param : architecture is "true";

signal p_int: signed(2*N+1 downto 0);

begin

process(clock)
begin
if rising_edge(clock) then
    if (reset = '1') then
        p_int <= (others => '0');
    elsif (clock_enable = '1') then
        p_int <= signed('0'&a)*signed(b(N-1)&b);
    end if;
end if;
end process;

p <= std_logic_vector(p_int(2*N-1 downto 0));

end arch_mult_param;
