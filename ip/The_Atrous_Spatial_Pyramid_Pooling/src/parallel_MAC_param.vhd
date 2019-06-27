-- This components provides RATE_WIDTH parallel 3x3 MAC modules.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity parallel_MAC_param is
    port(
    clock: in std_logic;
    reset: in std_logic;
    ready: in std_logic;
    clock_enable: in std_logic;
    weight_v: in win_array;
    win_in_v: in win_array;
    pix_out_v: out conv_array(RATE_WIDTH-1 downto 0));
end parallel_MAC_param;

architecture arch_parallel_MAC_param of parallel_MAC_param is

component MAC_module is
    port(
    clock : in std_logic;
    reset : in std_logic;
    ready : in std_logic;
    clock_enable : in std_logic;
    weight : in reg_array(WEIGHT_WIDTH-1 downto 0);
    win_in : in reg_array(WEIGHT_WIDTH-1 downto 0);
    pix_out : out std_logic_vector(DATA_WIDTH+11 downto 0));
end component;

begin

MAC: for i in 0 to RATE_WIDTH-1 generate
    MACi: MAC_module port map(
            clock => clock,
            reset => reset,
            ready => ready,
            clock_enable => clock_enable,
            weight => weight_v(i),
            win_in => win_in_v(i),
            pix_out => pix_out_v(i));
end generate MAC;

end arch_parallel_MAC_param;
