-- The Atrous Spatial Pyramid Pooling - Top Level

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.array_def.all;

entity ASPP_net_top is
    port(
    aclk            : in  std_logic;
    aresetn         : in  std_logic;
    -- From PS
    start           : in  std_logic; 
    ReLU_sel        : in  std_logic;
    -- fmap port
    m00_axis_tready : in  std_logic;
    s00_axis_tvalid : in  std_logic;
    s00_axis_tlast  : in  std_logic;
    s00_axis_tdata  : in  std_logic_vector(31 downto 0);
    s00_axis_tready : out std_logic;
    m00_axis_tvalid : out std_logic;
    m00_axis_tlast  : out std_logic;
    m00_axis_tdata  : out std_logic_vector(31 downto 0);
    -- weights port
    s01_axis_tvalid : in  std_logic;
    s01_axis_tlast  : in  std_logic;
    s01_axis_tdata  : in  std_logic_vector(31 downto 0);
    s01_axis_tready : out std_logic;
    -- global average pooling
    fm_mean         : out std_logic_vector(31 downto 0)); 
end ASPP_net_top;

architecture arch_ASPP_net_top of ASPP_net_top is

component control_unit is
    generic(
    SW_LATENCY: integer := 28; 
    MAC_LATENCY : integer := 5; 
    FRAME_LATENCY : integer := 64; 
    CNT_SIZE_BIN : integer := 7); 
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
end component;

component multiplexer_2to1_param is
    generic(N : integer := 8);
    port(
    input_1 : in std_logic_vector(N-1 downto 0);
    input_2 : in std_logic_vector(N-1 downto 0);
    selector : in std_logic;
    output : out std_logic_vector(N-1 downto 0));
end component;

component buffer_win_param is
    generic(
    KE : integer := 49;
    COL : integer := 200);
    port(
    clock : in std_logic;
    reset : in std_logic;
    clock_enable : in std_logic;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    win_out : out reg_array(KE*KE-1 downto 0));
end component;

component padd_atrous_param is
    generic(
    KE : integer := 49;
    COL : integer := 200;
    CNTB : integer := 8);
    port(
    clock : in std_logic;
    reset : in std_logic;
    ready : in std_logic;
    clock_enable : in std_logic;
    win_in : in reg_array(KE*KE-1 downto 0);
    win_out : out win_array);
end component;

component weights_unit is
    port(
    clock : in std_logic;
    start : in std_logic;
    valid : in std_logic;
    last : in std_logic;
    ready : out std_logic;
    coeff : in std_logic_vector(DATA_WIDTH-1 downto 0);
    weight_v : out win_array);
end component;

component parallel_MAC_param is
    port(
    clock: in std_logic;
    reset: in std_logic;
    ready: in std_logic;
    clock_enable: in std_logic;
    weight_v: in win_array;
    win_in_v: in win_array;
    pix_out_v: out conv_array(RATE_WIDTH-1 downto 0));
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

component fmaps_accum is
    port (
    clock : in std_logic;
    reset : in std_logic;
    ready : in std_logic;
    clock_enable : in std_logic;
    a_v: in reg_array(RATE_WIDTH-1 downto 0);
    b_v: in reg_array(RATE_WIDTH-1 downto 0);
    out_v: out reg_array(RATE_WIDTH-1 downto 0));
end component;

component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    rstb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END component;

component parallel_ReLU_param is
    port(
    clock : in std_logic;
    reset : in std_logic;
    ReLU_sel : in std_logic; 
    ready : in std_logic;
    clock_enable : in std_logic;
    data_in_v : in reg_array(RATE_WIDTH-1 downto 0);
    data_out_v : out reg_array(RATE_WIDTH-1 downto 0));
end component;

component global_average_pooling is
    generic(N: integer := 24);
    port(
    clk: in std_logic;
    start: in std_logic;
    s_valid: in std_logic;
    din: in std_logic_vector(N-1 downto 0);
    dout: out std_logic_vector(31 downto 0));
end component;

signal reset_int, clock_enable_atrous, clock_enable_MAC, clock_enable_acc, clock_enable_ReLU : std_logic;
signal stream_int, stream_int_reg : std_logic_vector(DATA_WIDTH-1 downto 0);
signal win_out_int : reg_array(2400 downto 0); -- modify according to KE; in this case KE = 49. => KE*KE=2401
signal win_out_int_int: win_array;
signal weight_v: win_array;
signal pix_out_int_v: conv_array(RATE_WIDTH-1 downto 0);
signal out_int_v: reg_array(RATE_WIDTH-1 downto 0);
signal out_int_v_reg: reg_array(RATE_WIDTH-1 downto 0);

signal out_grp : std_logic_vector(31 downto 0); -- according to the AXI4-Stream Word Size
signal out_grp_grp : std_logic_vector(31 downto 0);
signal out_grp_grp_reg : std_logic_vector(31 downto 0);
signal old_map : std_logic_vector(31 downto 0);

signal ofm_v: reg_array(RATE_WIDTH-1 downto 0);
signal ofm_flatten : std_logic_vector(31 downto 0);

signal ena : std_logic;
signal ena_int : std_logic;
signal wea : std_logic_vector(0 downto 0);
signal wea_int : std_logic_vector(0 downto 0);
signal addra : std_logic_vector(15 downto 0); -- according to the nearest power of 2 of the number of addresses 
signal rstb : std_logic;
signal enb : std_logic;
signal enb_int : std_logic;
signal addrb : std_logic_vector(15 downto 0);

signal svalid_int : std_logic;
signal mready_int : std_logic;
signal enable_int : std_logic;

signal din_pool: std_logic_vector(23 downto 0); -- stream_int_reg extention according to the AXI4 Word Size

begin

enable_int <= svalid_int and mready_int;

CU : control_unit 
    generic map 
        (SW_LATENCY => 4825, 
        MAC_LATENCY => 5, 
        FRAME_LATENCY => 40000, 
        CNT_SIZE_BIN => 16) 
    port map
        (clock => aclk, 
        reset => start, 
        ReLU_sel => ReLU_sel, 
        m_ready => m00_axis_tready, 
        s_valid => s00_axis_tvalid, 
        s_last => s00_axis_tlast, 
        reset_int => reset_int, 
        clock_enable_atrous => clock_enable_atrous, 
        clock_enable_MAC => clock_enable_MAC, 
        clock_enable_acc => clock_enable_acc, 
        clock_enable_ReLU => clock_enable_ReLU, 
        ena => ena, 
        wea => wea, 
        addra => addra, 
        rstb => rstb, 
        enb => enb, 
        addrb => addrb, 
        s_ready => s00_axis_tready, 
        m_valid => m00_axis_tvalid, 
        m_last => m00_axis_tlast, 
        my_svalid => svalid_int, 
        my_mready => mready_int);
        
MUX : multiplexer_2to1_param 
    generic map(N => DATA_WIDTH) 
    port map
        (input_1 => s00_axis_tdata(DATA_WIDTH-1 downto 0), 
        input_2 => (others => '0'), 
        selector => s00_axis_tvalid, 
        output => stream_int);

RMUX : reg_param 
    generic map(N => DATA_WIDTH) 
    port map
        (clock => aclk, 
        reset => reset_int, 
        clock_enable => enable_int, 
        data_in => stream_int, 
        data_out => stream_int_reg);
        
SW : buffer_win_param 
    generic map
        (KE => 49, 
        COL => 200)
    port map
        (clock => aclk, 
        reset => reset_int, 
        clock_enable => enable_int, 
        data_in => stream_int_reg, 
        win_out => win_out_int);
        
AW : padd_atrous_param 
    generic map
        (KE => 49, 
        COL => 200, 
        CNTB => 8) 
    port map
        (clock => aclk, 
        reset => reset_int, 
        ready => enable_int, 
        clock_enable => clock_enable_atrous, 
        win_in => win_out_int, 
        win_out => win_out_int_int);
    
WU : weights_unit 
    port map
        (clock => aclk, 
        start => start, 
        valid => s01_axis_tvalid, 
        last => s01_axis_tlast, 
        ready => s01_axis_tready, 
        coeff => s01_axis_tdata(DATA_WIDTH-1 downto 0), 
        weight_v => weight_v);
        
CONV: parallel_MAC_param 
    port map
        (clock => aclk,
        reset => reset_int,
        ready => enable_int,
        clock_enable => clock_enable_MAC,
        weight_v => weight_v,
        win_in_v => win_out_int_int,
        pix_out_v => pix_out_int_v);
        
ACC : fmaps_accum 
    port map
    (clock => aclk, 
    reset => reset_int, 
    ready => enable_int, 
    clock_enable => clock_enable_acc, 
    a_v(0) => pix_out_int_v(0)(19 downto 12),
    a_v(1) => pix_out_int_v(1)(19 downto 12),
    a_v(2) => pix_out_int_v(2)(19 downto 12),
    a_v(3) => pix_out_int_v(3)(19 downto 12),
    b_v(0) => old_map(7 downto 0),
    b_v(1) => old_map(15 downto 8), 
    b_v(2) => old_map(23 downto 16),
    b_v(3) => old_map(31 downto 24),
    out_v => out_int_v);
     
out_grp <= out_int_v(3)&out_int_v(2)&out_int_v(1)&out_int_v(0);
--out_grp <= out_int_v(RATE_WIDTH-1)&out_int_v(RATE_WIDTH-2)&...&out_int_v(0);

enb_int <= enb and enable_int;
ena_int <= ena and enable_int;
wea_int(0) <= ena and enable_int;

BRAM_MUX : multiplexer_2to1_param 
    generic map(N => 32) 
    port map
        (input_1 => (others => '0'), 
        input_2 => out_grp, 
        selector => ReLU_sel, 
        output => out_grp_grp);

RMUX_BRAM : 
    reg_param 
    generic map(N => 32) 
    port map
        (clock => aclk, 
        reset => reset_int, 
        clock_enable => enable_int, 
        data_in => out_grp_grp, 
        data_out => out_grp_grp_reg);
        
BRAM : blk_mem_gen_0 
    port map
        (clka => aclk, 
        ena => ena, 
        wea => wea, 
        addra => addra, 
        dina => out_grp_grp_reg, 
        clkb => aclk, 
        rstb => rstb, 
        enb => enb_int, 
        addrb => addrb, 
        doutb => old_map);
        
RRELU : for i in 0 to RATE_WIDTH-1 generate
    RRELUi: reg_param 
            generic map(N => DATA_WIDTH) 
            port map
                (clock => aclk, 
                reset => reset_int, 
                clock_enable => enable_int, 
                data_in => out_int_v(i), 
                data_out => out_int_v_reg(i));
end generate RRELU;

RELU: parallel_ReLU_param 
    port map
        (clock => aclk, 
        reset => reset_int, 
        ReLU_sel => ReLU_sel, 
        ready => enable_int, 
        clock_enable => clock_enable_ReLU, 
        data_in_v => out_int_v_reg,
        data_out_v => ofm_v);
 
ofm_flatten <= ofm_v(3)&ofm_v(2)&ofm_v(1)&ofm_v(0);
--ofm_flatten <= ofm_v(RATE_WIDTH-1)&ofm_v(RATE_WIDTH-2)&...&ofm_v(0);

RCF : reg_param 
    generic map(N => 32) 
    port map
        (clock => aclk, 
        reset => reset_int, 
        clock_enable => enable_int, 
        data_in => ofm_flatten, 
        data_out => m00_axis_tdata);

din_pool <= "0000000000000000" & stream_int_reg;

GAP: global_average_pooling 
    generic map (N => 24) 
    port map
        (clk => aclk,
        start => start,
        s_valid => s00_axis_tvalid,
        din => din_pool,
        dout => fm_mean);        

end arch_ASPP_net_top;
