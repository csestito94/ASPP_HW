-- This decoder handles mux selectors for the Zero-Padding.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity sel_decoder_param is
    generic(
    N : integer := 8; -- word size
    COL : integer := 200; -- fmap col size
    P : integer := 1); -- padding size
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    input : in std_logic_vector(N-1 downto 0);
    output : out std_logic_vector(WEIGHT_WIDTH-1 downto 0));
end sel_decoder_param;

architecture arch_sel_decoder_param of sel_decoder_param is

signal input_int : integer range 0 to COL-1;

begin

process(clock)
begin
    if (rising_edge(clock)) then
        if (reset = '1') then
            output <= (others => '0');
        elsif (clock_enable = '1') then
            if (input_int < P) then
                output <= "011011011";
            elsif (input_int >= (COL-P)) then
                output <= "110110110";
            else
                output <= "111111111";
            end if;
        end if;
    end if;
end process;

input_int <= to_integer(unsigned(input));

end arch_sel_decoder_param;

