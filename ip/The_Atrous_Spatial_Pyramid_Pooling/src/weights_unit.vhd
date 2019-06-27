-- Coefficients unit TOP level

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity weights_unit is
    port(
    clock : in std_logic;
    start : in std_logic;
    valid : in std_logic;
    last : in std_logic;
    ready : out std_logic;
    coeff : in std_logic_vector(DATA_WIDTH-1 downto 0);
    weight_v : out win_array);
end weights_unit;

architecture arch_weights_unit of weights_unit is

component ctrl_weights is
    port(
    clock : in std_logic;
    start : in std_logic;
    valid : in std_logic;
    last : in std_logic;
    reset_int : out std_logic;
    clock_enable : out std_logic;
    ready : out std_logic);
end component;

component weights_array is
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    coeff : in std_logic_vector(DATA_WIDTH-1 downto 0);
    weights : out reg_array(WEIGHT_WIDTH-1 downto 0));
end component;

signal reset_int : std_logic;
signal clock_enable_int : std_logic;

begin

CW : ctrl_weights port map(clock => clock, start => start, valid => valid, last => last, reset_int => reset_int, clock_enable => clock_enable_int, ready => ready);
WA : for i in 0 to RATE_WIDTH-1 generate
    WAi: weights_array port map(clock => clock, reset => reset_int, clock_enable => clock_enable_int, coeff => coeff, weights => weight_v(i));
end generate WA;

end arch_weights_unit;

