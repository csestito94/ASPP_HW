-- Global constants & types

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package array_def is
       
    constant DATA_WIDTH : integer := 8; 
    constant WEIGHT_WIDTH : integer := 9;
    constant RATE_WIDTH : integer := 4;  
    
    type reg_array is array (natural range <>) of std_logic_vector (DATA_WIDTH-1 downto 0);
    type rate_array is array (natural range <>) of natural;
    type win_array is array(RATE_WIDTH-1 downto 0) of reg_array(WEIGHT_WIDTH-1 downto 0);
    constant R: rate_array(RATE_WIDTH-1 downto 0) := (6,12,18,24);
    
    type conv_array is array (natural range <>) of std_logic_vector(DATA_WIDTH+11 downto 0);
    
end array_def;

package body array_def is
end array_def;

