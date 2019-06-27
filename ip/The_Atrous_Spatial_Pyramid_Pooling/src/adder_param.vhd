-- This registered adder performs a sum between two signed bit vectors.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_param is
    generic (N: integer:= 8);
    port ( 
    clock: in std_logic;
    reset: in std_logic;
    clock_enable: in std_logic;
    a: in std_logic_vector(N-1 downto 0); 
    b: in std_logic_vector(N-1 downto 0); 
    s: out std_logic_vector(N downto 0)
    );
end adder_param;

architecture arch_adder_param of adder_param is

attribute use_dsp : string;
attribute use_dsp of arch_adder_param : architecture is "true";

signal s_int: signed(N downto 0);

begin

process(clock)
begin
if rising_edge(clock) then
    if (reset = '1') then
        s_int <= (others => '0');
    elsif (clock_enable = '1') then
        s_int <= signed(a(N-1)&a)+signed(b(N-1)&b);
    end if;
end if;
end process;

s <= std_logic_vector(s_int);

end arch_adder_param;
