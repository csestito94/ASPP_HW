-- N bit Counter with an upper limit.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity up_counter_param is
    generic(
    N : integer := 8; -- word size
    MAX : integer := 200); -- upper limit
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    count : out std_logic_vector(N-1 downto 0));
end up_counter_param;

architecture arch_up_counter_param of up_counter_param is

signal count_int : integer range 0 to MAX-1 := 0;

begin

cnt_proc : process(clock)
begin
if (rising_edge(clock)) then
    if (reset = '1' or count_int = MAX-1) then
        count_int <= 0;
    elsif (clock_enable = '1') then
        count_int <= count_int + 1;
    end if;
end if;
end process;
            
count <= std_logic_vector(to_unsigned(count_int,N));

end arch_up_counter_param;

