-- Acccumulator for Mean Pooling

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accum_pool is
    generic(N: integer := 24);
    port(
    clk : in std_logic;
    clr : in std_logic;
    ce : in std_logic;
    d : in std_logic_vector(N-1 downto 0);
    q : out std_logic_vector(N-1 downto 0));
end accum_pool;

architecture arch_accum_pool of accum_pool is

attribute use_dsp : string;
attribute use_dsp of arch_accum_pool : architecture is "true";

signal dint : unsigned(N-1 downto 0);
signal tmp : unsigned(N-1 downto 0);

begin

acc_proc: process(clk)
begin
    if rising_edge(clk) then
    dint <= unsigned(d);  
        if (clr = '1') then            
            tmp <= (others => '0');      
        elsif (ce = '1') then
            tmp <= tmp + dint;
        end if;
    q <= std_logic_vector(tmp);     
    end if;
end process;

end arch_accum_pool;


