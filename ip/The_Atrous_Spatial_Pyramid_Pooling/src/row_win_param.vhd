-- Row of an arbitrary number of N bit registers --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity row_win_param is
    generic(
    N : integer := 8; -- word size
    D : integer := 49); -- row depth (i.e. number of registers)
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    data_in : in std_logic_vector(N-1 downto 0);
    row_out : out reg_array(D-1 downto 0));
end row_win_param;

architecture arch_row_win_param of row_win_param is

component reg_param is
    generic (N : integer := 8);        
    port (
    clock : in  std_logic;
    reset : in  std_logic;
    clock_enable : in  std_logic;
    data_in : in  std_logic_vector(N-1 downto 0);
    data_out : out std_logic_vector(N-1 downto 0));
end component;

signal data_int : reg_array(D downto 0) := (others => (others => '0'));

begin

data_int(0) <= data_in;

REG : for i in 0 to D-1 generate
    REG_i : reg_param 
            generic map(N => DATA_WIDTH)
            port map(
            clock => clock,
            reset => reset,
            clock_enable => clock_enable,
            data_in => data_int(i),
            data_out => data_int(i+1));
end generate REG;

RO : for i in 0 to D-1 generate
    row_out(i) <= data_int(i+1);
end generate RO;

end arch_row_win_param;

