-- This components accumulates intermediate fmaps

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity fmaps_accum is
    port (
    clock : in std_logic;
    reset : in std_logic;
    ready : in std_logic;
    clock_enable : in std_logic;
    a_v: in reg_array(RATE_WIDTH-1 downto 0);
    b_v: in reg_array(RATE_WIDTH-1 downto 0);
    out_v: out reg_array(RATE_WIDTH-1 downto 0));
end fmaps_accum;

architecture arch_fmaps_accum of fmaps_accum is

attribute use_dsp : string;
attribute use_dsp of arch_fmaps_accum : architecture is "true";

-- Modify according to RATE_WIDTH 

signal a0_r,b0_r,out0_r : signed(DATA_WIDTH-1 downto 0); 
signal a1_r,b1_r,out1_r : signed(DATA_WIDTH-1 downto 0); 
signal a2_r,b2_r,out2_r : signed(DATA_WIDTH-1 downto 0); 
signal a3_r,b3_r,out3_r : signed(DATA_WIDTH-1 downto 0); 
--signal ak_r,bk_r,outk_r : signed(DATA_WIDTH-1 downto 0); 
signal clock_enable_int : std_logic;

begin

clock_enable_int <= ready and clock_enable;

process(clock)
begin
    if (rising_edge(clock)) then
        if reset = '1' then
            a0_r <= (others => '0');
            b0_r <= (others => '0');
            a1_r <= (others => '0');
            b1_r <= (others => '0');
            a2_r <= (others => '0');
            b2_r <= (others => '0');
            a3_r <= (others => '0');
            b3_r <= (others => '0');
            --ak_r <= (others => '0');
            --bk_r <= (others => '0');
            out0_r <= (others => '0');
            out1_r <= (others => '0');
            out2_r <= (others => '0');
            out3_r <= (others => '0');
            --outk_r <= (others => '0');
        elsif (clock_enable_int = '1') then
            a0_r <= signed(a_v(0));
            b0_r <= signed(b_v(0));
            a1_r <= signed(a_v(1));
            b1_r <= signed(b_v(1));
            a2_r <= signed(a_v(2));
            b2_r <= signed(b_v(2));
            a3_r <= signed(a_v(3));
            b3_r <= signed(b_v(3));
            --ak_r <= signed(a_v(k));
            --bk_r <= signed(b_v(k));
            out0_r <= a0_r + b0_r;
            out1_r <= a1_r + b1_r;
            out2_r <= a2_r + b2_r;
            out3_r <= a3_r + b3_r;
            --outk_r <= ak_r + bk_r;    
        end if;
    end if;
end process;

out_v(0) <= std_logic_vector(out0_r);
out_v(1) <= std_logic_vector(out1_r);
out_v(2) <= std_logic_vector(out2_r);
out_v(3) <= std_logic_vector(out3_r);
--out_v(k) <= std_logic_vector(outk_r);

end arch_fmaps_accum;

