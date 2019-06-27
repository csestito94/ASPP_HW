-- This component provides RATE_WIDTH parallel ReLU units.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity parallel_ReLU_param is
    port(
    clock : in std_logic;
    reset : in std_logic;
    ReLU_sel : in std_logic; -- provided by the Processing System
    ready : in std_logic;
    clock_enable : in std_logic;
    data_in_v : in reg_array(RATE_WIDTH-1 downto 0);
    data_out_v : out reg_array(RATE_WIDTH-1 downto 0));
end parallel_ReLU_param;

architecture arch_parallel_ReLU_param of parallel_ReLU_param is

component ReLU_compute is
    port(
    clock : in std_logic;
    reset : in std_logic;
    ReLU_sel : in std_logic; 
    ready : in std_logic;
    clock_enable : in std_logic;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
end component;

begin

ReLU: for i in 0 to RATE_WIDTH-1 generate
    ReLUi: ReLU_compute port map
            (clock => clock,
            reset => reset,
            ReLU_sel => ReLU_sel,
            ready => ready,
            clock_enable => clock_enable,
            data_in => data_in_v(i),
            data_out => data_out_v(i));
end generate ReLU;

end arch_parallel_ReLU_param;
