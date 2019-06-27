-- This component performs the Rectified Linear Unit Activation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity ReLU_compute is
    port(
    clock : in std_logic;
    reset : in std_logic;
    ReLU_sel : in std_logic; 
    ready : in std_logic;
    clock_enable : in std_logic;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
end ReLU_compute;

architecture arch_ReLU_compute of ReLU_compute is

component multiplexer_2to1_sel2bit_param is
    generic(N : integer := 8);
    port(
    input_1 : in std_logic_vector(N-1 downto 0);
    input_2 : in std_logic_vector(N-1 downto 0);
    selector : in std_logic_vector(1 downto 0);
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

signal data_out_int: std_logic_vector(DATA_WIDTH-1 downto 0);
signal selector_int: std_logic_vector(1 downto 0);
signal clock_enable_int: std_logic;

begin

selector_int <= ReLU_sel & data_in(DATA_WIDTH-1);
clock_enable_int <= ready and clock_enable;

MUX : multiplexer_2to1_sel2bit_param generic map(N => DATA_WIDTH) port map(input_1 => data_in, input_2 => (others => '0'), selector => selector_int, output => data_out_int); 
REG : reg_param generic map(N => DATA_WIDTH) port map(clock => clock, reset => reset, clock_enable => clock_enable_int, data_in => data_out_int, data_out => data_out);

end arch_ReLU_compute;

