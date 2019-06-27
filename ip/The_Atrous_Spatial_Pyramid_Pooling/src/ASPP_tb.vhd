-- Example testbench

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.all;
use IEEE.STD_LOGIC_ARITH.ALL;
library STD;
use STD.textio.all;

entity ASPP_tb is
--  Port ( );
end ASPP_tb;

architecture Behavioral of ASPP_tb is

component ASPP_net_top is
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
end component;

component write_to_file is
    generic(LOG_FILE: string := "res.log");
    port(
    aclk: in std_logic;
    ReLU_sel : in std_logic;
    m00_axis_tready: in std_logic;
    m00_axis_tvalid: in std_logic;
    m00_axis_tdata: in std_logic_vector(31 downto 0));
end component;

signal aclk            : std_logic;
signal aresetn         : std_logic;
signal start           : std_logic;
signal ReLU_sel        : std_logic;
signal m00_axis_tready : std_logic;
signal s00_axis_tvalid : std_logic;
signal s00_axis_tlast  : std_logic;
signal s00_axis_tdata  : std_logic_vector(31 downto 0);
signal s00_axis_tready : std_logic;
signal m00_axis_tvalid : std_logic;
signal m00_axis_tlast  : std_logic;
signal m00_axis_tdata  : std_logic_vector(31 downto 0);
signal s01_axis_tvalid : std_logic;
signal s01_axis_tlast  : std_logic;
signal s01_axis_tdata  : std_logic_vector(31 downto 0);
signal s01_axis_tready : std_logic;
signal fm_mean         : std_logic_vector(31 downto 0);

constant clkp : time := 10 ns; -- Modify according design timing limits

begin

dut : ASPP_net_top port map
        (aclk => aclk,
        aresetn => aresetn,
        start => start,
        ReLU_sel => ReLU_sel,
        m00_axis_tready => m00_axis_tready,
        s00_axis_tvalid => s00_axis_tvalid,
        s00_axis_tlast => s00_axis_tlast,
        s00_axis_tdata => s00_axis_tdata,
        s00_axis_tready => s00_axis_tready,
        m00_axis_tvalid => m00_axis_tvalid,
        m00_axis_tlast => m00_axis_tlast,
        m00_axis_tdata => m00_axis_tdata,
        s01_axis_tvalid => s01_axis_tvalid,
        s01_axis_tlast => s01_axis_tlast,
        s01_axis_tdata => s01_axis_tdata,
        s01_axis_tready => s01_axis_tready,
        fm_mean => fm_mean);
wf  : write_to_file port map
        (aclk => aclk,
        ReLU_sel => ReLU_sel,
        m00_axis_tready => m00_axis_tready,
        m00_axis_tvalid => m00_axis_tvalid,
        m00_axis_tdata => m00_axis_tdata);

clk_proc : process
begin
    aclk <= '0';
    wait for clkp/2;
    aclk <= '1';
    wait for clkp/2;
end process;

rst_proc : process
begin
    aresetn <= '0';
    wait for 10*clkp;
    aresetn <= '1';
    wait;
end process;

ReLU_sel_proc : process
begin
    ReLU_sel <= '0';
    wait for (10+10+40000)*clkp+5000*clkp;
    wait for 40000*clkp+5000*clkp;
    wait for (5+10)*clkp; 
    -- last 200x200 fmap sending
    ReLU_sel <= '1';
    wait;
end process;

mready_proc : process
begin
    m00_axis_tready <= '0';
    wait for (10+10+40000)*clkp+5000*clkp;
    wait for 40000*clkp+5000*clkp;
    wait for (5+10)*clkp; 
    -- last 200x200 fmap sending
    m00_axis_tready <= '1';   
    wait for (40000+2999)*clkp;
    -- mready goes suddenly down --
    m00_axis_tready <= '0';
    wait for 20*clkp;
    -- mready enabled again
    m00_axis_tready <= '1';    
    wait;
end process;

svalid_proc : process
begin
    s00_axis_tvalid <= '0';
    wait for (10+10)*clkp;
    -- 1st fmap sending started
    s00_axis_tvalid <= '1';
    wait for 4*clkp;
    -- svalid goes suddenly down
    s00_axis_tvalid <= '0';
    wait for 5*clkp;
    -- svalid enabled again
    s00_axis_tvalid <= '1';
    wait for (40000-4)*clkp;
    -- 1st fmap sending ended
    s00_axis_tvalid <= '0';
    wait for 5000*clkp;
    -- 2nd fmap sending started
    s00_axis_tvalid <= '1';
    wait for 38999*clkp;
    -- svalid goes suddenly down
    s00_axis_tvalid <= '0';
    wait for 10*clkp;
    -- svalid enabled again
    s00_axis_tvalid <= '1';
    wait for (40000-38999)*clkp;
    -- 2nd fmap sending ended
    s00_axis_tvalid <= '0';
    wait for 5000*clkp;
    -- 3rd fmap sending started
    s00_axis_tvalid <= '1';
    wait for 40000*clkp;
    -- 3rd fmap sendind ended
    s00_axis_tvalid <= '0';
    wait;
end process;

slast_proc : process
begin
    s00_axis_tlast <= '0';
    wait for ((10+10+39999)+5)*clkp;
    -- last 1st ifmap value
    s00_axis_tlast <= '1';
    wait for clkp;
    s00_axis_tlast <= '0';
    wait for ((5000+39999)+10)*clkp;
    -- last 2nd ifmap value
    s00_axis_tlast <= '1';
    wait for clkp;
    s00_axis_tlast <= '0';
    wait for ((5000+39999))*clkp;
    -- last 3rd ifmap value
    s00_axis_tlast <= '1';
    wait for clkp;
    s00_axis_tlast <= '0';
    wait;
end process;

-- Weights sending 
weights_proc : process
begin 
    start <= '1';
    s01_axis_tvalid <= '0';
    s01_axis_tlast <= '0';
    s01_axis_tdata <= (others => '0');
    wait for 10*clkp;
    start <= '0';
    wait for 5*clkp;
    s01_axis_tvalid <= '1';
    s01_axis_tdata <= std_logic_vector(to_signed(-128,32));
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(0,32));
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(64,32));    
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(-32,32));   
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(-1,32));
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(127,32));
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(-16,32));
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(8,32));
    wait for clkp;
    s01_axis_tdata <= std_logic_vector(to_signed(4,32));
    s01_axis_tlast <= '1';
    wait for clkp;
    s01_axis_tlast <= '0';
    s01_axis_tvalid <= '0';
    wait;
end process;

-- fmap sending
read_proc : process
    variable rdline : line;
    variable tmp : integer;  
    file vector_file_1 : text open read_mode is "C:\Users\Cristian\Dropbox\MATLAB\ifmap1.txt";        
    file vector_file_2 : text open read_mode is "C:\Users\Cristian\Dropbox\MATLAB\ifmap2.txt";        
    file vector_file_3 : text open read_mode is "C:\Users\Cristian\Dropbox\MATLAB\ifmap3.txt"; 
    --file vector_file_1 : text open read_mode is "my_directory\ifmap1.txt";        
    --file vector_file_2 : text open read_mode is "my_directory\ifmap2.txt";        
    --file vector_file_3 : text open read_mode is "my_directory\ifmap3.txt"; 
begin 
    s00_axis_tdata <= (others => '0');
    wait for (10+10)*clkp; 
    -- 1st ifmap (including unexpected svalid pause)
    for i in 0 to 4 loop
        readline(vector_file_1, rdline);
        read(rdline, tmp);
        s00_axis_tdata  <= CONV_STD_LOGIC_VECTOR(tmp,32);
        wait for clkp;
    end loop;
    wait for 5*clkp;
    while not endfile(vector_file_1) loop 
        readline(vector_file_1, rdline);
        read(rdline, tmp);
        s00_axis_tdata  <= CONV_STD_LOGIC_VECTOR(tmp,32);
        wait for clkp;
    end loop;
    wait for 5000*clkp;
    -- 2nd ifmap (including unexpected svalid pause)
    for i in 0 to 38999 loop
        readline(vector_file_2, rdline);
        read(rdline, tmp);
        s00_axis_tdata  <= CONV_STD_LOGIC_VECTOR(tmp,32);
        wait for clkp;
    end loop;   
    wait for 10*clkp; 
    while not endfile(vector_file_2) loop   
        readline(vector_file_2, rdline);
        read(rdline, tmp);
        s00_axis_tdata  <= CONV_STD_LOGIC_VECTOR(tmp,32);
        wait for clkp;
    end loop;    
    wait for 5000*clkp;
    -- 3rd ifmap 
    while not endfile(vector_file_3) loop   
        readline(vector_file_3, rdline);
        read(rdline, tmp);
        s00_axis_tdata  <= CONV_STD_LOGIC_VECTOR(tmp,32);
        wait for clkp;
    end loop;  
    wait;
end process;

end Behavioral;
