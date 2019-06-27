-- This component provides Dilated Windows, Zero-Padded when desidered.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity padd_atrous_param is
    generic(
    KE : integer := 49; -- square window size, according to the max dilated rate (ke=k+(k-1)(r-1))
    COL : integer := 200; -- fmap col size
    CNTB : integer := 8); -- ceil(log2(COL))
    port(
    clock : in std_logic;
    reset : in std_logic;
    ready : in std_logic;
    clock_enable : in std_logic;
    win_in : in reg_array(KE*KE-1 downto 0);
    win_out : out win_array);
end padd_atrous_param;

architecture arch_padd_atrous_param of padd_atrous_param is

-- For each fmap row, this counter provides the j-th col position.
component up_counter_param is
    generic(
    N : integer := 8;
    MAX : integer := 200);
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    count : out std_logic_vector(N-1 downto 0));
end component;

-- According to the counting, this decoder provides valid selection signal for mux banks.
-- Hence it handles the Zero-Padding =>(size(ofmap)=size(ifmap)).
component sel_decoder_param is
    generic(
    N : integer := 8;
    COL : integer := 200;
    P : integer := 1);
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    input : in std_logic_vector(N-1 downto 0);
    output : out std_logic_vector(WEIGHT_WIDTH-1 downto 0));
end component;

-- These mus banks provides input fmap values or zero padding.
component multiplexer_2to1_param is
    generic(N : integer := 8);
    port(
    input_1 : in std_logic_vector(N-1 downto 0);
    input_2 : in std_logic_vector(N-1 downto 0);
    selector : in std_logic;
    output : out std_logic_vector(N-1 downto 0));
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

type ker_array is array (natural range <>) of std_logic_vector (WEIGHT_WIDTH-1 downto 0);
signal clock_enable_int : std_logic;
signal count_int : std_logic_vector(CNTB-1 downto 0);
signal selector : ker_array(RATE_WIDTH-1 downto 0);
signal win_int : win_array := (others => (others => (others => '0')));
signal win_int_reg : win_array := (others => (others => (others => '0')));

begin

clock_enable_int <= (ready and clock_enable);

CNT : up_counter_param generic map(N => CNTB, MAX => COL) port map(clock => clock, reset => reset, clock_enable => clock_enable_int, count => count_int);

SD : for i in 0 to RATE_WIDTH-1 generate
    SD_i: sel_decoder_param generic map(N => CNTB, COL => COL, P => R(i)) 
          port map(clock => clock, reset => reset, clock_enable => clock_enable_int,input => count_int, output => selector(i));
end generate SD;

-- Generic Dilated 3x3 Window. Refer to the documentation for more details.
WI: for i in 0 to RATE_WIDTH-1 generate
    win_int(i)(0) <= win_in((KE*KE-1)/2-R(i)*(1+KE));           
    win_int(i)(1) <= win_in((KE*KE-1)/2-R(i)*KE);   
    win_int(i)(2) <= win_in((KE*KE-1)/2+R(i)*(1-KE));   
    win_int(i)(3) <= win_in((KE*KE-1)/2-R(i));     
    win_int(i)(4) <= win_in((KE*KE-1)/2);     
    win_int(i)(5) <= win_in((KE*KE-1)/2+R(i));     
    win_int(i)(6) <= win_in((KE*KE-1)/2-R(i)*(1-KE));      
    win_int(i)(7) <= win_in((KE*KE-1)/2+R(i)*KE);      
    win_int(i)(8) <= win_in((KE*KE-1)/2+R(i)*(1+KE));   
end generate WI; 

MUXi: for i in 0 to RATE_WIDTH-1 generate
    MUXj: for j in 0 to WEIGHT_WIDTH-1 generate
        MUXij : multiplexer_2to1_param generic map(N => DATA_WIDTH) port map(input_1 => win_int(i)(j), input_2 => (others => '0'), selector => selector(i)(j), output => win_int_reg(i)(j));
    end generate MUXj;
end generate MUXi;

RXi: for i in 0 to RATE_WIDTH-1 generate
    RXj: for j in 0 to WEIGHT_WIDTH-1 generate
        RXij : reg_param generic map(N => DATA_WIDTH) port map(clock => clock, reset => reset, clock_enable => ready, data_in => win_int_reg(i)(j), data_out => win_out(i)(j));
    end generate RXj;
end generate RXi;

end arch_padd_atrous_param;

