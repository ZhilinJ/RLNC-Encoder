library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Testbench is
end Testbench;

architecture Behavioral of Testbench is
component FSMs
generic(amount : integer :=1);
Port (
    clk : in std_logic;
    n : in natural;
    m : in natural;
    number : in natural;
    rst : in std_logic;
    start : in std_logic;
    finish : out std_logic;
    ci : in std_logic_vector(255 downto 0);  --coefficient matrix
    si : in std_logic_vector(255 downto 0);  --source matrix
    tout : out std_logic_vector(255 downto 0);  --transmission matrix
    nf : out std_logic;
    nd : out std_logic
 );
 end component;
 
signal clk : std_logic := '0';  
signal rst : std_logic := '0';
signal start : std_logic := '0';
signal finish : std_logic;
signal c : std_logic_vector(255 downto 0) := (others => '0');
signal s : std_logic_vector(255 downto 0) := (others => '0');
signal t : std_logic_vector(255 downto 0) := (others => '0');
signal n, m : natural;
signal number : natural;
signal nf, nd :std_logic;
constant t1:std_logic_vector(255 downto 0) := x"474BF567A95BDA48413F7F498C0D36545E71921C8BEBA1A93DB5CB390B53B2E0";
constant t2:std_logic_vector(255 downto 0) := x"5198038F78650F85D63F2851B6158CCAC6C9BA5A9C54DE686A2DAF5EE84CF034";
constant t3:std_logic_vector(255 downto 0) := x"CE5FDD8CA5BD5267F2486358ABCD9B837C331C6EEEC77C679C61F2A68AF3E31A";
constant t4:std_logic_vector(255 downto 0) := x"51a04e63c80a13eba588777516847b90abb8cd4774fb9aeed764586e9cccd939";



begin
uut : FSMs port map(clk=>clk, n=>n, m=>m, number=>number, rst=>rst, start=>start, finish=>finish, ci=>c, si=>s, tout=>t, nf=>nf, nd=>nd);

clk_process : process
begin
while true loop
  clk <= '1';
  wait for 10 ns;
  clk <= '0';
  wait for 10 ns;
end loop;
end process;

test : process
begin
rst<='1';
wait for 20 ns;
rst<='0';
start<='1';
wait for 20 ns;
start<='0';
n<=2;
m<=64;
number<=0;
c<=x"F859998900000000000000000000000000000000000000000000000000000000";
s<=x"2992E82DA1FF58F71B9217494E182C33A14D2C069025E3DF2B7F75D3B2AF8AD9";
wait until nd='1';
wait for 40 ns;
c<=(others=>'0');
s<=x"53B92060618F0BA6ABCECC0DD1361F2F4C47F448E998C91436E1DE8E5D7BBFD0";
wait for 40 ns;
s<=x"5FC00E398479626DF26024E415F3AF656E489D35618E034EBA646473F5D0871F";
wait for 40 ns;
s<=x"C69B616E55DA93E9452A6433E31C2B3379EA0BE7570EFDBBA4CD239AC6170EB9";
wait;
end process;

process
begin
    wait on t;
    wait for 1 ns;  
    assert t = t1
    report "Mismatch at time " & time'image(now) severity error;
    
    wait on t;
    wait for 1 ns;
    assert t = t2
    report "Mismatch at time " & time'image(now) severity error;
    
    wait on t;
    wait for 1 ns;
    assert t = t3
    report "Mismatch at time " & time'image(now) severity error;
    
    wait on t;
    wait for 1 ns;
    assert t = t4
    report "Mismatch at time " & time'image(now) severity error;
    wait;
end process;
end Behavioral;
