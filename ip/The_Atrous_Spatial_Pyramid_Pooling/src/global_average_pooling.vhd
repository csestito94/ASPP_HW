-- The Global Average Pooling-TOP Level

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity global_average_pooling is
    generic(N: integer := 24); -- ceil(log2(255*row*col))
    port(
    clk: in std_logic;
    start: in std_logic;
    s_valid: in std_logic;
    din: in std_logic_vector(N-1 downto 0);
    dout: out std_logic_vector(31 downto 0)); -- according to the AXI4 Data Width
end global_average_pooling;

architecture arch_gap of global_average_pooling is

component gap_fsm is
    port(
    clk: in std_logic;
    start : in std_logic;
    s_valid : in std_logic;
    clr : out std_logic;
    clr_mean : out std_logic;
    ce_acc : out std_logic;
    ce_mean : out std_logic;
    my_valid : out std_logic);
end component;

component accum_pool is
    generic(N: integer := 24);
    port(
    clk : in std_logic;
    clr : in std_logic;
    ce : in std_logic;
    d : in std_logic_vector(N-1 downto 0);
    q : out std_logic_vector(N-1 downto 0));
end component;

component reg_param is
    generic (N : integer := 8);        
    port (
    clock : in  std_logic;
    reset : in  std_logic;
    clock_enable : in  std_logic;
    data_in : in  std_logic_vector(N-1 downto 0);
    data_out : out std_logic_vector(N-1 downto 0));
end component;

signal clr,clr_mean,ce_acc,ce_acc_int,ce_mean,my_valid: std_logic;
signal out_acc: std_logic_vector(N-1 downto 0);
signal mean: std_logic_vector(31 downto 0);

begin
ce_acc_int <= ce_acc and my_valid;
FSM: gap_fsm port map(clk => clk, start => start,s_valid => s_valid, clr => clr, clr_mean => clr_mean, ce_acc => ce_acc, ce_mean => ce_mean, my_valid => my_valid);
ACC: accum_pool generic map(N => N) port map(clk => clk, clr => clr, ce => ce_acc_int, d => din, q => out_acc);
mean <= "00000000000000000000000" & out_acc(N-1 downto N-9);
REG: reg_param generic map(N => 32) port map(clock => clk, reset => clr_mean, clock_enable => ce_mean, data_in => mean, data_out => dout);

end arch_gap;

