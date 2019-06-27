-- Parameterized windowed buffer 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity buffer_win_param is
    generic(
    KE : integer := 49; -- square window size, according to the max dilated rate (ke=k+(k-1)(r-1))
    COL : integer := 200); -- fmap col size
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    win_out : out reg_array(KE*KE-1 downto 0));
end buffer_win_param;

architecture arch_buffer_win_param of buffer_win_param is

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

component line_buffer_param is
    generic(
    D : integer := 39951;
    N : integer := 8);
    port(
    clock : in std_logic;
    clock_enable : in std_logic;
    shift_in : in std_logic_vector(N-1 downto 0);
    shift_out : out std_logic_vector(N-1 downto 0));
end component;

signal row_in  : reg_array(KE-1 downto 0) := (others => (others => '0'));
type row_array is array (natural range <>) of reg_array(KE-1 downto 0);
signal row_out : row_array(KE-1 downto 0) := (others => (others => (others => '0')));

begin

row_in(0) <= data_in;

ROW : for i in 0 to KE-1 generate
    ROW_i : row_win_param 
            generic map(
            N => DATA_WIDTH,
            D => KE)
            port map(
            clock => clock,
            reset => reset,
            clock_enable => clock_enable,
            data_in => row_in(i),
            row_out => row_out(i));
end generate ROW;

LINE_BUF : for i in 0 to KE-2 generate
    LINE_BUF_i : line_buffer_param 
                    generic map(
                    D => COL-KE,
                    N => DATA_WIDTH)
                    port map(
                    clock => clock,
                    clock_enable => clock_enable,
                    shift_in => row_out(i)(KE-1),
                    shift_out => row_in(i+1));
end generate LINE_BUF;

WO : for i in 0 to KE-1 generate
    win_out(KE*KE-KE*i-1 downto KE*KE-KE*(i+1)) <= row_out(KE-i-1);
end generate WO;

end arch_buffer_win_param;

