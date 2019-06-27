library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity multiplexer_2to1_sel2bit_param is
    generic(N : integer := 8);
    port(
    input_1 : in std_logic_vector(N-1 downto 0);
    input_2 : in std_logic_vector(N-1 downto 0);
    selector : in std_logic_vector(1 downto 0);
    output : out std_logic_vector(N-1 downto 0));
end multiplexer_2to1_sel2bit_param;

architecture arch_multiplexer_2to1_sel2bit_param of multiplexer_2to1_sel2bit_param is

begin

mux_proc: process(selector,input_1,input_2)
begin
    case selector is
        when "00" => output <= input_2;
        when "01" => output <= input_2;
        when "10" => output <= input_1;
        when "11" => output <= input_2;
        when others => output <= input_2;
    end case;
end process;

end arch_multiplexer_2to1_sel2bit_param;


