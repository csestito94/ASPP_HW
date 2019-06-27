-- Parameterized N bit register with reset and clock enable --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reg_param is
    generic (N : integer := 8); -- word size       
    port (
    clock : in  std_logic;
    reset : in  std_logic;
    clock_enable : in  std_logic;
    data_in : in  std_logic_vector(N-1 downto 0);
    data_out : out std_logic_vector(N-1 downto 0));
end reg_param;

architecture arch_reg_param of reg_param is

begin

reg_proc : process(clock)
begin
if rising_edge(clock) then
    if (reset = '1') then
        data_out <= (others => '0');
    elsif (clock_enable = '1') then
        data_out <= data_in;
    end if;
end if;
end process;

end arch_reg_param;

