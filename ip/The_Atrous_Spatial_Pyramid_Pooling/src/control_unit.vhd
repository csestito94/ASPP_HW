-- This FSM controls the whole IP

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_unit is
    generic(
    SW_LATENCY: integer := 4825; -- ((k-1)/2)*(col+1) + 1(mux reg)
    MAC_LATENCY : integer := 5; -- 1 mult + 4 add 
    FRAME_LATENCY : integer := 40000; -- fmap row*col
    CNT_SIZE_BIN : integer := 16); -- ceil(log2(sw_lat+MAC_lat+fr_lat))
    port(
    clock : in std_logic;
    reset : in std_logic;
    ReLU_sel : in  std_logic;
    m_ready : in std_logic;
    s_valid : in std_logic;
    s_last : in std_logic;
    reset_int : out std_logic;
    clock_enable_atrous : out std_logic;
    clock_enable_MAC : out std_logic;
    clock_enable_acc : out std_logic;
    clock_enable_ReLU : out std_logic;
    ena : out std_logic;
    wea : out std_logic_vector(0 downto 0);
    addra : out std_logic_vector(15 downto 0);
    rstb : out std_logic;
    enb : out std_logic;
    addrb : out std_logic_vector(15 downto 0);
    s_ready : out std_logic;
    m_valid : out std_logic;
    m_last : out std_logic;
    my_svalid : out std_logic;
    my_mready : out std_logic);
end control_unit;

architecture arch_control_unit of control_unit is

type state_type is 
(init,waiting_stream,buffer_filling,padd_atrous_enabled,MAC_enabled,oldmap_reading_enabled,
fmaps_accumul_enabled,fmap_writing_enabled,wait_1,stream_ended,reading_ended,writing_ended,
ReLU_enabled,ofmap_sending,pause1_axisdown,wait_2,last_stream_ended,pause2_axisdown,last_ofmap_value);

signal curr_state, next_state: state_type;

signal valid_int, ready_int : std_logic;
signal enable_axis : std_logic;

-- General counter
signal count1 : unsigned(CNT_SIZE_BIN-1 downto 0):= (others => '0');
signal reset1   : std_logic;
signal clock_enable1 : std_logic;
signal clock_enable1_int : std_logic;

-- Read Addresses counter
signal count2 : unsigned(15 downto 0):= (others => '0');
signal reset2   : std_logic;
signal clock_enable2 : std_logic;
signal clock_enable2_int : std_logic;

-- Write Addresses counter
signal count3 : unsigned(15 downto 0):= (others => '0');
signal reset3   : std_logic;
signal clock_enable3 : std_logic;
signal clock_enable3_int : std_logic;

constant sw_lat : unsigned(CNT_SIZE_BIN-1 downto 0) := to_unsigned(SW_LATENCY,CNT_SIZE_BIN);
constant MAC_lat : unsigned(CNT_SIZE_BIN-1 downto 0) := to_unsigned(MAC_LATENCY,CNT_SIZE_BIN);
constant fr_lat : unsigned(CNT_SIZE_BIN-1 downto 0) := to_unsigned(FRAME_LATENCY,CNT_SIZE_BIN);
    
begin
enable_axis <= (valid_int and ready_int);
clock_enable1_int <= (enable_axis and clock_enable1);
clock_enable2_int <= (enable_axis and clock_enable2);
clock_enable3_int <= (enable_axis and clock_enable3);
   
cnt1: process(clock)
begin
    if rising_edge(clock) then
        if (reset1 = '1') then
            count1 <= (others => '0');
        elsif (clock_enable1_int = '1') then
            count1 <= count1 + 1 ;
        end if;              
    end if;
end process;

cnt2: process(clock)
begin
    if rising_edge(clock) then
        if (reset2 = '1') then
            count2 <= (others => '0');
        elsif (clock_enable2_int = '1') then
            count2 <= count2 + 1 ;
        end if;              
    end if;
end process;

cnt3: process(clock)
begin
    if rising_edge(clock) then
        if (reset3 = '1') then
            count3 <= (others => '0');
        elsif (clock_enable3_int = '1') then
            count3 <= count3 + 1 ;
        end if;              
    end if;
end process;

state_reg_proc: process(clock)
begin
    if rising_edge(clock) then
        if reset = '1' then
            curr_state <= init;
         else
            curr_state <= next_state;
        end if;
    end if;
end process;

next_state_logic: process(curr_state,m_ready,s_valid,count1,ReLU_sel,s_last)
begin
    case curr_state is
        when init =>
            next_state <= waiting_stream;
        when waiting_stream =>
            if (s_valid = '1') then
                next_state <= buffer_filling;
            else
                next_state <= waiting_stream;
            end if;
        when buffer_filling =>
            if (count1 >= sw_lat-2) then
                next_state <= padd_atrous_enabled;
            else
                next_state <= buffer_filling;
            end if;
        when padd_atrous_enabled =>
            if (count1 >= sw_lat) then
                next_state <= MAC_enabled;
            else 
                next_state <= padd_atrous_enabled;
            end if;
        when MAC_enabled =>
            if (count1 >= sw_lat+MAC_lat-2) then
                next_state <= oldmap_reading_enabled;
            else   
                next_state <= MAC_enabled;
            end if;
        when oldmap_reading_enabled =>
            if (count1 >= sw_lat+MAC_lat) then
                next_state <= fmaps_accumul_enabled;
            else
                next_state <= oldmap_reading_enabled;
            end if;
        when fmaps_accumul_enabled =>
            if (ReLU_sel = '0') then
                if (count1 >= sw_lat+MAC_lat+3) then
                    next_state <= fmap_writing_enabled;
                else
                    next_state <= fmaps_accumul_enabled;
                end if;
            else
                if (count1 >= sw_lat+MAC_lat+3) then
                    next_state <= ReLU_enabled;
                else
                    next_state <= fmaps_accumul_enabled;
                end if;
            end if;
        when fmap_writing_enabled =>
            if (s_last = '1') then
                next_state <= wait_1;
            else
                next_state <= fmap_writing_enabled;
            end if;
        when wait_1 =>
            next_state <= stream_ended;
        when stream_ended =>
            if (count1 >= sw_lat+MAC_lat+fr_lat) then
                next_state <= reading_ended;
            else
                next_state <= stream_ended;
            end if;
        when reading_ended =>
            if (count1 >= sw_lat+MAC_lat+fr_lat+3) then
                next_state <= writing_ended;
            else
                next_state <= reading_ended;
            end if;
        when writing_ended =>
            next_state <= init;
        when ReLU_enabled =>
            if (m_ready = '1' and s_valid = '1') then
                if (count1 >= sw_lat+MAC_lat+2+3) then
                    next_state <= ofmap_sending;
                else
                    next_state <= ReLU_enabled;
                end if;
            else
                next_state <= ReLU_enabled;
            end if;
        when ofmap_sending =>
            if (m_ready = '1' and s_valid = '1') then
                if (s_last = '1') then
                    next_state <= wait_2;
                else
                    next_state <= ofmap_sending;
                end if;
            else
                next_state <= pause1_axisdown;
            end if;
        when pause1_axisdown =>
            if (m_ready = '1' and s_valid = '1') then
                next_state <= ofmap_sending;
            else
                next_state <= pause1_axisdown;
            end if;
        when wait_2 =>
            next_state <= last_stream_ended;
        when last_stream_ended =>
            if (m_ready = '1') then
                if (count1 >= sw_lat+MAC_lat+2+3+(fr_lat-1)) then
                    next_state <= last_ofmap_value;
                else
                    next_state <= last_stream_ended;
                end if;
            else
                next_state <= pause2_axisdown;
            end if;
        when pause2_axisdown =>
            if (m_ready = '1') then
                next_state <= last_stream_ended;
            else
                next_state <= pause2_axisdown;
            end if;
        when last_ofmap_value =>
            next_state <= init;  
    end case;
end process;
        
output_logic: process(curr_state,s_valid,m_ready)
begin
    case curr_state is
        when init =>
            reset_int <= '1';
            clock_enable_atrous <= '0';
            clock_enable_MAC <= '0';
            clock_enable_acc <= '0';
            clock_enable_ReLU <= '0';
            s_ready <= '0';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '1';
            clock_enable1 <= '0';
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '1';
            enb <= '0';
            reset2 <= '1';
            clock_enable2 <= '0';
            valid_int <= '0';
            ready_int <= '0';
        when waiting_stream =>
            reset_int <= '0';
            clock_enable_atrous <= '0';
            clock_enable_MAC <= '0';
            clock_enable_acc <= '0';
            clock_enable_ReLU <= '0'; 
            s_ready <= '1';           
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '1';   
            clock_enable1 <= '0';
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '1';
            enb <= '0';
            reset2 <= '1';
            clock_enable2 <= '0';
            valid_int <= s_valid;
            ready_int <= '1';
        when buffer_filling =>
            reset_int <= '0';
            clock_enable_atrous <= '0';
            clock_enable_MAC <= '0';
            clock_enable_acc <= '0';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '1';
            enb <= '0';
            reset2 <= '1';
            clock_enable2 <= '0';
            valid_int <= s_valid;
            ready_int <= '1';          
        when padd_atrous_enabled =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '0';
            clock_enable_acc <= '0';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';   
            clock_enable1 <= '1';  
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '1';
            enb <= '0';
            reset2 <= '1';
            clock_enable2 <= '0';
            valid_int <= s_valid;
            ready_int <= '1';
        when MAC_enabled =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '0';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '1';
            enb <= '0';
            reset2 <= '1';
            clock_enable2 <= '0';
            valid_int <= s_valid;
            ready_int <= '1';
        when oldmap_reading_enabled =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '0';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';
            valid_int <= s_valid;
            ready_int <= '1';
        when fmaps_accumul_enabled =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';  
            ena <= '0';
            wea <= "0";
            reset3 <= '1';
            clock_enable3 <= '0';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';   
            valid_int <= s_valid;
            ready_int <= '1';   
        when fmap_writing_enabled =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';  
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';  
            valid_int <= s_valid;
            ready_int <= '1';
        when wait_1 =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '0';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';  
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';
            valid_int <= '1';
            ready_int <= '1';         
        when stream_ended =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '0';
            s_ready <= '0';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';  
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1'; 
            valid_int <= '1';
            ready_int <= '1';
        when reading_ended =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '0';
            s_ready <= '0';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '0';
            reset2 <= '0';
            clock_enable2 <= '0';
            valid_int <= '1';
            ready_int <= '1';   
        when writing_ended =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '0';
            s_ready <= '0';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '0';
            wea <= "0";
            reset3 <= '0';
            clock_enable3 <= '0';
            rstb <= '0';
            enb <= '0';
            reset2 <= '0';
            clock_enable2 <= '0';  
            valid_int <= '1';
            ready_int <= '1'; 
        when ReLU_enabled =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';  
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';     
            valid_int <= s_valid;
            ready_int <= m_ready;
        when ofmap_sending =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '1';
            m_valid <= '1';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';     
            valid_int <= s_valid;
            ready_int <= m_ready;
        when pause1_axisdown =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '1';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';     
            valid_int <= s_valid;
            ready_int <= m_ready;       
        when wait_2 =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '1';
            m_valid <= '1';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';    
            valid_int <= '1';
            ready_int <= m_ready;
        when last_stream_ended =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '0';
            m_valid <= '1';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';          
            valid_int <= '1';
            ready_int <= m_ready;    
        when pause2_axisdown =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '0';
            m_valid <= '0';
            m_last <= '0';
            reset1 <= '0';
            clock_enable1 <= '1';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '1';
            reset2 <= '0';
            clock_enable2 <= '1';          
            valid_int <= '0';
            ready_int <= m_ready;              
        when last_ofmap_value =>
            reset_int <= '0';
            clock_enable_atrous <= '1';
            clock_enable_MAC <= '1';
            clock_enable_acc <= '1';
            clock_enable_ReLU <= '1';
            s_ready <= '1';
            m_valid <= '1';
            m_last <= '1';
            reset1 <= '1';
            clock_enable1 <= '0';
            ena <= '1';
            wea <= "1";
            reset3 <= '0';
            clock_enable3 <= '1';
            rstb <= '0';
            enb <= '0';
            reset2 <= '0';
            clock_enable2 <= '0'; 
            valid_int <= '1';
            ready_int <= m_ready;  
    end case;
    
end process;  
      
addra <= std_logic_vector(count3);
addrb <= std_logic_vector(count2);     

my_svalid <= valid_int;
my_mready <= ready_int;
    
end arch_control_unit;

