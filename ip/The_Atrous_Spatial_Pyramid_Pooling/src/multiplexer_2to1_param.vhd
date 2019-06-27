-- Parameterized N bit MUX 2to1

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity multiplexer_2to1_param is
    generic(N : integer := 8); -- word size
    port(
    input_1 : in std_logic_vector(N-1 downto 0);
    input_2 : in std_logic_vector(N-1 downto 0);
    selector : in std_logic;
    output : out std_logic_vector(N-1 downto 0));
end multiplexer_2to1_param;

architecture arch_multiplexer_2to1_param of multiplexer_2to1_param is

begin

output <= input_1 when selector = '1' else input_2;

end arch_multiplexer_2to1_param;

