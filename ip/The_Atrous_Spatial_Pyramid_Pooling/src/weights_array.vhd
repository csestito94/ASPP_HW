-- This components stores the coefficients (i.e. a shift-register).

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity weights_array is
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    coeff : in std_logic_vector(DATA_WIDTH-1 downto 0);
    weights : out reg_array(WEIGHT_WIDTH-1 downto 0));
end weights_array;

architecture arch_weights_array of weights_array is

component row_win_param is
    generic(
    N : integer := 8;
    D : integer := 49);
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    data_in : in std_logic_vector(N-1 downto 0);
    row_out : out reg_array(D-1 downto 0));
end component;

begin

ROW_REG : row_win_param generic map(N => DATA_WIDTH, D => WEIGHT_WIDTH) port map(clock => clock, reset => reset, clock_enable => clock_enable, data_in => coeff, row_out => weights);

end arch_weights_array;

