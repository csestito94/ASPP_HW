-- Parameterized FIFO 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity line_buffer_param is
    generic(
    D : integer := 39951; -- FIFO depth (row*col-k)
    N : integer := 8); -- word size
    port(
    clock : in std_logic;
    clock_enable : in std_logic;
    shift_in : in std_logic_vector(N-1 downto 0);
    shift_out : out std_logic_vector(N-1 downto 0));
end line_buffer_param;

architecture arch_line_buffer_param of line_buffer_param is

signal shift_int : reg_array (D-1 downto 0) := (others => (others => '0'));
    
begin

shift_proc : process(clock)
begin
if rising_edge(clock) then
    if (clock_enable = '1') then
        shift_int(0) <= shift_in;
        for i in 1 to D-1 loop
            shift_int(i) <= shift_int(i-1);
        end loop;
    end if;
end if;
end process;
    
shift_out <= shift_int(D-1);

end arch_line_buffer_param;

