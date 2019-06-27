-- FSM for coefficients storing. 
-- It handles Weight_DMA-ASPP_Core AXI4-Stream Inteface

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ctrl_weights is
    port(
    clock : in std_logic;
    start : in std_logic;
    valid : in std_logic;
    last : in std_logic;
    reset_int : out std_logic;
    clock_enable : out std_logic;
    ready : out std_logic);
end ctrl_weights;

architecture arch_ctrl_weights of ctrl_weights is

type state_type is (init,free,lat,stop);
signal curr_state, next_state : state_type;
    
begin

state_reg_proc: process(clock)
begin
    if rising_edge(clock) then
        if start = '1' then
            curr_state <= init;
         else
            curr_state <= next_state;
        end if;
    end if;
end process;

next_state_logic: process(curr_state,last)
begin
    case curr_state is
        when init =>
            next_state <= free;
        when free =>
            if last = '1' then
                next_state <= lat;
            else
                next_state <= free;
            end if;
        when lat =>
            next_state <= stop;
        when stop =>
            next_state <= stop;            
    end case;
end process;

output_logic: process(curr_state)
begin
    case curr_state is
        when init =>
            reset_int <= '1';
            clock_enable <= '0';
            ready <= '0';
        when free =>
            reset_int <= '0';
            clock_enable <= '1';
            ready <= '1';      
        when lat =>
            reset_int <= '0';
            clock_enable <= '0';
            ready <= '1';             
        when stop =>
            reset_int <= '0';
            clock_enable <= '0';
            ready <= '0';                 
    end case;
end process;

end arch_ctrl_weights;

