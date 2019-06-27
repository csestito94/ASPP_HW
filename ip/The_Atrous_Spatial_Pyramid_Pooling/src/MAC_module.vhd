-- This component performs 3x3 Convolution

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity MAC_module is
    port(
    clock : in std_logic;
    reset : in std_logic;
    ready : in std_logic;
    clock_enable : in std_logic;
    weight : in reg_array(WEIGHT_WIDTH-1 downto 0);
    win_in : in reg_array(WEIGHT_WIDTH-1 downto 0);
    pix_out : out std_logic_vector(DATA_WIDTH+11 downto 0));
end MAC_module;

architecture arch_MAC_module of MAC_module is

component mult_param is
    generic (N: integer:= 8);
    port ( 
    clock: in std_logic;
    reset: in std_logic;
    clock_enable: in std_logic;
    a: in std_logic_vector(N-1 downto 0); 
    b: in std_logic_vector(N-1 downto 0); 
    p: out std_logic_vector(2*N-1 downto 0)
    );
end component;

component adder_param is
    generic (N: integer:= 8);
    port ( 
    clock: in std_logic;
    reset: in std_logic;
    clock_enable: in std_logic;
    a: in std_logic_vector(N-1 downto 0); 
    b: in std_logic_vector(N-1 downto 0); 
    s: out std_logic_vector(N downto 0)
    );
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

type prod_array   is array(natural range <>) of std_logic_vector(DATA_WIDTH+7 downto 0);
type prod_array_1 is array(natural range <>) of std_logic_vector(DATA_WIDTH+8 downto 0);
type prod_array_2 is array(natural range <>) of std_logic_vector(DATA_WIDTH+9 downto 0);
type prod_array_3 is array(natural range <>) of std_logic_vector(DATA_WIDTH+10 downto 0);

signal prod_int : prod_array(WEIGHT_WIDTH-1 downto 0);
signal sum_1    : prod_array_1(3 downto 0);
signal sum_2    : prod_array_2(1 downto 0);
signal sum_3    : prod_array_3(0 downto 0);
signal prod_int_ext : std_logic_vector(DATA_WIDTH+10 downto 0);
signal prod_int_8_reg0 : std_logic_vector(DATA_WIDTH+10 downto 0);
signal prod_int_8_reg1 : std_logic_vector(DATA_WIDTH+10 downto 0);
signal prod_int_8_reg2 : std_logic_vector(DATA_WIDTH+10 downto 0);
signal clock_enable_int : std_logic;

begin

prod_int_ext <= "000" & prod_int(8);

clock_enable_int <= (ready and clock_enable);

MULTS : for i in 0 to WEIGHT_WIDTH-1 generate
    MULTX : mult_param 
    generic map(N => DATA_WIDTH) 
    port map(clock => clock, a => win_in(i), b => weight(8-i), clock_enable => clock_enable_int, reset => reset, p => prod_int(i));
end generate MULTS;

ADDS1 : for i in 0 to 3 generate
    ADD1X : adder_param 
    generic map(N => 2*DATA_WIDTH) 
    port map(a => prod_int(i), b => prod_int(i+4), clock => clock, clock_enable => clock_enable_int, reset => reset, s => sum_1(i));
end generate ADDS1;

ADDS2 : for i in 0 to 1 generate
    ADD2X : adder_param 
    generic map(N => 2*DATA_WIDTH+1) 
    port map(a => sum_1(i), b => sum_1(i+2), clock => clock, clock_enable => clock_enable_int, reset => reset, s => sum_2(i));
end generate ADDS2;

ADD3 : adder_param 
generic map(N => 2*DATA_WIDTH+2) 
port map(a => sum_2(0), b => sum_2(1), clock => clock, clock_enable => clock_enable_int, reset => reset, s => sum_3(0));

REG0 : reg_param 
generic map(N => 2*DATA_WIDTH+3) 
port map(clock => clock, reset => reset, clock_enable => clock_enable_int, data_in => prod_int_ext, data_out => prod_int_8_reg0);

REG1 : reg_param 
generic map(N => 2*DATA_WIDTH+3) 
port map(clock => clock, reset => reset, clock_enable => clock_enable_int, data_in => prod_int_8_reg0, data_out => prod_int_8_reg1);

REG2 : reg_param 
generic map(N => 2*DATA_WIDTH+3) 
port map(clock => clock, reset => reset, clock_enable => clock_enable_int, data_in => prod_int_8_reg1, data_out => prod_int_8_reg2);

ADD4 : adder_param 
generic map (N => 2*DATA_WIDTH+3) 
port map(a => sum_3(0), b => prod_int_8_reg2, clock => clock, clock_enable => clock_enable_int, reset => reset, s => pix_out);

end arch_MAC_module;

