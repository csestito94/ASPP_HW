-- The Global Average Pooling control.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gap_fsm is
    port(
    clk: in std_logic;
    start : in std_logic;
    s_valid : in std_logic;
    clr : out std_logic;
    clr_mean : out std_logic;
    ce_acc : out std_logic;
    ce_mean : out std_logic;
    my_valid : out std_logic);
end gap_fsm;

architecture arch_gap_fsm of gap_fsm is

type state_type is (init,accumulate,wait_write,write_mean);
signal curr_state, next_state: state_type;

constant No_VALUES: integer := 40000; -- refers to fmap area(200x200 in this case)

signal s_valid_int : std_logic;

-- Pixel counter
signal count1 : unsigned(15 downto 0):= (others => '0');
signal reset1   : std_logic;
signal clock_enable1 : std_logic;
signal clock_enable1_int : std_logic;

begin

clock_enable1_int <= (s_valid_int and clock_enable1);
  
cnt1: process(clk)
begin
    if rising_edge(clk) then
        if (reset1 = '1') then
            count1 <= (others => '0');
        elsif (clock_enable1_int = '1') then
            count1 <= count1 + 1 ;
        end if;              
    end if;
end process;

state_reg_proc: process(clk)
begin
    if rising_edge(clk) then
        if start = '1' then
            curr_state <= init;
         else
            curr_state <= next_state;
        end if;
    end if;
end process;

next_state_logic: process(curr_state,s_valid,count1)
begin
    case curr_state is
        when init =>
            if (s_valid = '1') then
                next_state <= accumulate;
            else
                next_state <= init;
            end if;
        when accumulate =>
            if (count1 >= No_VALUES-2) then
                next_state <= wait_write;
            else
                next_state <= accumulate;
            end if;
        when wait_write =>
            if (count1 >= No_VALUES+2) then
                next_state <= write_mean;
            else
                next_state <= wait_write;
            end if;
        when write_mean =>
            next_state <= init;
    end case;
end process;

output_logic: process(curr_state,s_valid)
begin
    case curr_state is 
        when init =>
            clr <= '1';
            clr_mean <= '0';
            ce_acc <= '0';
            ce_mean <= '0';
            reset1 <= '1';
            clock_enable1 <= '0';
            s_valid_int <= s_valid;
        when accumulate =>
            clr <= '0';
            clr_mean <= '1';
            ce_acc <= '1';
            ce_mean <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            s_valid_int <= s_valid;
        when wait_write =>
            clr <= '0';
            clr_mean <= '0';
            ce_acc <= '1';
            ce_mean <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            s_valid_int <= '1';
        when write_mean =>
            clr <= '0';
            clr_mean <= '0';
            ce_acc <= '0';
            ce_mean <= '1';
            reset1 <= '0';
            clock_enable1 <= '1';
            s_valid_int <= '1';          
    end case;
end process;

my_valid <= s_valid_int;

end arch_gap_fsm;



