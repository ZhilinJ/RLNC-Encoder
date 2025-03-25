----------------------------------------------------------------------------------
--Top level entity with two fsms design
----------------------------------------------------------------------------------
--Zhilin Jin
--03.2025
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

entity FSMs is
  generic(
    amount : integer:=7);
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
    nf : out std_logic;
    nd : out std_logic;
    tout : out std_logic_vector(255 downto 0)  --transmission matrix
 );
end FSMs;

architecture Behavioral of FSMs is
component ALU
port(
  clk : in std_logic;
  rst : in std_logic;
  c : in std_logic_vector(7 downto 0);
  s : in std_logic_vector(7 downto 0);
  t : in std_logic_vector(7 downto 0);
  y : out std_logic_vector(7 downto 0));
end component;

component RAMC
port(
  clk : in std_logic;
  ena : in std_logic;
  enb : in std_logic;
  wea : in std_logic;
  addra : in std_logic_vector(7 downto 0);
  addrb : in std_logic_vector(7 downto 0);
  dia : in std_logic_vector(255 downto 0);
  dob : out std_logic_vector(255 downto 0));
end component;

component RAMS
port(
  clk : in std_logic;
  ena : in std_logic;
  enb : in std_logic;
  wea : in std_logic;
  addra : in std_logic_vector(7 downto 0);
  addrb : in std_logic_vector(7 downto 0);
  dia : in std_logic_vector(255 downto 0);
  dob : out std_logic_vector(255 downto 0));
end component;
  
--sel signal
signal selc, sels, selt, selc_next, sels_next, selt_next, selt_last : integer range 1 to 32 := 32;
--signal for ALU
signal co, so, tou : std_logic_vector(255 downto 0):=(others=>'0');
signal data_c, data_s, data_t, alu_result, data_t_next: std_logic_vector(7 downto 0):=(others=>'0');
--address signal
signal addrac, addrbc, addras, addrbs, addrat, addrbt, addrct, addrct_last, addrcto, addrbc_last, addrbs_last : std_logic_vector(7 downto 0) := "00000000";
--enable signal
signal enac, enbc, enas, enbs, enat, enbt, enct, weac, weas, weat, enalu : std_logic := '0';
--counter signal
signal cnt4c, cnt4s, cnt4c_next, cnt4s_next, cnt4cmax, cnt4smax, cnt, cnt_next, cnt1, cnt1_next : integer := 0;
--cntcalc
signal cnt_calc, cnt_calc_next : integer := 0;
--finish
signal write_done, calc_finish, done, done_next: std_logic := '0';
--ijk
signal i, j, k, i_next, j_next, k_next, i_last, j_last, k_last : integer := 0;
--record
type flowdata is record
  n : natural;
  m : natural;
  ss : natural;
  se : natural;
  cs : natural;
  ce : natural;
  rdyc : std_logic ;
  rdys : std_logic ;
end record flowdata;
type flowarray is array (0 to amount+1) of flowdata;
signal flows : flowarray:= (others => (0, 0, 0, 0, 0, 0, '0', '0'));
signal flows_next, flows_last : flowarray:= (others => (0, 0, 0, 0, 0, 0, '0', '0'));
--pointer
signal wpc, wps, wpc_next, wps_next, calcptrnm, calcptr_nextnm, calcptrnn, calcptr_nextnn, rp : integer := 0;
--state
type state_type is (IDLE1, IDLE2, Pa, Pb, WRITEa, WRITEb, CALCa, CALCb, RST1, RST2, CLEARa, CLEARb, CLEARc);
signal current_state1, next_state1, current_state2, next_state2, last_state2: state_type;
signal temp, temp_next : std_logic_vector(255 downto 0):=(others=>'0');
signal test, test_next : integer := 0;
signal rd : std_logic_vector(0 to amount) := (others=>'0');
type fnt is array (0 to amount) of integer;
signal fn : fnt := (others=>0);
signal sd, spass, cpass : std_logic := '0';
signal atws, atwc : std_logic_vector(0 to 255) := (others =>'1');
signal nf_next, nd_next, nf1, nd1 : std_logic := '0';

begin

memc : RAMC port map(clk=>clk, ena=>enac, enb=>enbc, wea=>weac, addra=>addrac, addrb=>addrbc, dia=>ci, dob=>co);
mems : RAMS port map(clk=>clk, ena=>enas, enb=>enbs, wea=>weas, addra=>addras, addrb=>addrbs, dia=>si, dob=>so);
alu1 : ALU port map(clk=>clk, rst=>rst, c=>data_c, s=>data_s, t=>data_t, y=>alu_result);


process(clk, rst)
begin
if rst='1' then
nf1<='0';
nd1<='0';
elsif rising_edge(clk) then
nf1<=nf_next;
nd1<=nd_next;
end if;
end process;

process(all)
begin
if current_state1 = WRITEb and sd = '1' then
nf_next <= '1';
else
nf_next <= '0';
end if;
nf<=nf1;

if cpass='1' and spass='1' then
nd_next <= '1';
else
nd_next <= '0';
end if;
nd<=nd1;
end process;
-------------------------------------------------------write fsm----------------------------------------------------------------
process(clk, rst)
begin
if rst = '1' then
  flows <= (others => (0, 0, 0, 0, 0, 0, '0', '0'));
  current_state1 <= RST1;
elsif rising_edge(clk) then
  current_state1 <= next_state1;
  cnt4c <= cnt4c_next;
  cnt4s <= cnt4s_next;
  cnt <= cnt_next;
  wpc <= wpc_next;
  wps <= wps_next;
  flows_last <= flows;
  flows <= flows_next;
  cnt1 <= cnt1_next;
end if;
end process;

process(all)
begin
case current_state1 is
  when RST1 =>
    next_state1 <= IDLE1;
    
  when IDLE1 =>
    if start = '1' then
      next_state1 <= Pa;
    else
      next_state1 <= IDLE1;
    end if;
    
  when Pa =>
    next_state1 <= Pb;
  
  when Pb =>
    if spass = '1' and cpass = '1' then
      next_state1 <= WRITEa;
    else
      next_state1 <= Pa;
    end if;
    
  when WRITEb =>
    if write_done = '1' then
      next_state1 <= IDLE1;
    elsif sd = '1' then
      next_state1 <= Pa;
    else
      next_state1 <= WRITEa;
    end if;
  
  when WRITEa =>
    next_state1 <= WRITEb;
    
  when others =>
    next_state1 <= IDLE1;
end case;
end process;

process(all)
begin
addras <= (others=>'0');
addrac <= (others=>'0');
cnt4c_next <= cnt4c;
cnt4s_next <= cnt4s;
cnt_next <= cnt;
flows_next <= flows;
weac <= '0';
enac <= '0';
weas <= '0';
enas <= '0';

case current_state1 is
  when RST1 =>
    cnt4c_next <= 0;
    cnt4s_next <= 0;
    wpc_next <= 0;
    wps_next <= 0;
    write_done <= '0';
    
    
  when IDLE1 =>
    cnt4c_next <= 0;
    cnt4s_next <= 0;
    wpc_next <= 0;
    wps_next <= 0;
    write_done <= '0';
  
  when Pa =>
    cnt4c_next<=0;
    cnt4s_next<=0;
    if number = 0 then
      flows_next(number).ss <= 0;
    else 
      flows_next(number).ss <= (flows(number-1).se + 1) mod 64;
    end if;
    
    if n*m mod 32=0 then
    flows_next(number).se <= (flows_next(number).ss + n*m/32 -1) mod 64;
    else
    flows_next(number).se <= (flows_next(number).ss + n*m/32) mod 64;
    end if;
    
    if number = 0 then
      flows_next(number).cs <= 0;
    else 
      flows_next(number).cs <= (flows(number-1).ce + 1) mod 64;
    end if;
    
    if n*n mod 32 = 0 then
    flows_next(number).ce <= (flows_next(number).cs + n*n/32-1) mod 64;
    else
    flows_next(number).ce <= (flows_next(number).cs + n*n/32) mod 64;
    end if;
    
    if rd(cnt) = '1' then
      if flows(cnt).ss <= flows(cnt).se then
        atws(flows(cnt).ss to flows(cnt).se) <= (others => '1');
      elsif flows(cnt).ss > flows(cnt).se then
        atws(flows(cnt).ss to 255) <= (others => '1');
        atws(0 to flows(cnt).se) <= (others => '1');
      end if;
    end if;
    
    if rd(cnt) = '1' then
      if flows(cnt).cs <= flows(cnt).ce then
        atwc(flows(cnt).cs to flows(cnt).ce) <= (others => '1');
      elsif flows(cnt).cs > flows(cnt).ce then
        atwc(flows(cnt).cs to 255) <= (others => '1');
        atwc(0 to flows(cnt).ce) <= (others => '1');
      end if;
    end if;
    
    if rd(cnt) = '1' then
      cnt_next <= cnt+1;
    end if;
  
    sd <= '0';
    
  when Pb =>
    if number = 0 then
      spass <= '1';
      cpass <= '1';
    else
      if flows(number).ss<=flows(number).se then
        if (and atws(flows(number).ss to flows(number).se)) = '1' then
          spass <= '1';
        else
          spass <= '0';
        end if;
      elsif flows(number).ss>flows(number).se then
        if ((and atws(flows(number).ss to 255)) and (and atws(0 to flows(number).se))) = '1' then
          spass <= '1';
        else
          spass <= '0';
        end if;
      end if;
      
      if flows(number).cs<=flows(number).ce then
        if (and atwc(flows(number).cs to flows(number).ce)) = '1' then
          cpass <= '1';
        else
          cpass <= '0';
        end if;
      elsif flows(number).cs>flows(number).ce then
        if ((and atwc(flows(number).cs to 255)) and (and atwc(0 to flows(number).ce))) = '1' then
          cpass <= '1';
        else
          cpass <= '0';
        end if;
      end if;
    end if;
    
  when WRITEa =>
    cpass <= '0';
    spass <= '0';
    weac <= '1';
    enac <= '1';
    weas <= '1';
    enas <= '1';
    flows_next(number).rdyc <= flows(number).rdyc;
    flows_next(number).rdys <= flows(number).rdys;
    
    flows_next(number).n <= n;
    flows_next(number).m <= m;
    
    
    if ((flows_next(number).n*flows_next(number).n) mod 32) = 0 then
    cnt4cmax <= (flows_next(number).n*flows_next(number).n)/32-1;
    else
    cnt4cmax <= (flows_next(number).n*flows_next(number).n)/32;
    end if;
    
    if (flows_next(number).n*flows_next(number).m) mod 32 = 0 then
    cnt4smax <= (flows_next(number).n*flows_next(number).m)/32-1;
    else
    cnt4smax <= (flows_next(number).n*flows_next(number).m)/32;
    end if;
    
    if cnt4c = cnt4cmax then
      cnt4c_next <= 0;
      flows_next(number).rdyc <= '1';
    else
      cnt4c_next <= cnt4c+1;
    end if;
    
    if flows_next(number).rdyc='1' and flows_next(number).rdys='0' then
      wpc_next <= wpc;
    else
      wpc_next <= (wpc+1) mod 64;
    end if;
    
    if cnt4s = cnt4smax then
      cnt4s_next <= 0;
      flows_next(number).rdys <= '1';
    else
      cnt4s_next <= cnt4s+1;
    end if;
    
    if flows_next(number).rdys='1' and flows_next(number).rdyc='0' then
      wps_next <= wps;
    else
      wps_next <= (wps+1) mod 64;
    end if;
    
    if flows_last(number).rdys='1' and flows_last(number).rdyc='0' then
      weas <= '0';
      enas <= '0';
    end if;
    
    if flows_last(number).rdyc='1' and flows_last(number).rdys='0' then
      weac <= '0';
      enac <= '0';
    end if;

    
    if flows_next(amount-1).rdyc='1' and flows_next(amount-1).rdys='1' then
      write_done <= '1';
    else
      write_done <= '0';
    end if;
    
    
    addras <= std_logic_vector(to_unsigned(wps, 8));  
    addrac <= std_logic_vector(to_unsigned(wpc, 8));
    
    
    if flows_next(number).rdyc='1' and flows_next(number).rdys='1' then
      sd <= '1';
      cnt1_next<=cnt1+1;
    else
      sd <= '0';
      cnt1_next<=cnt1;
    end if;
    
    
      if flows(number).ss <= flows(number).se then
        atws(flows(number).ss to flows(number).se) <= (others => '0');
      elsif flows(number).ss > flows(number).se then
        atws(flows(number).ss to 255) <= (others => '0');
        atws(0 to flows(number).se) <= (others => '0');
      end if;
      
      if flows(number).cs <= flows(number).ce then
        atwc(flows(number).cs to flows(number).ce) <= (others => '0');
      elsif flows(number).cs > flows(number).ce then
        atwc(flows(number).cs to 255) <= (others => '0');
        atwc(0 to flows(number).ce) <= (others => '0');
      end if;
      
      
  when WRITEb =>    
    addras <= std_logic_vector(to_unsigned(wps, 8));  
    addrac <= std_logic_vector(to_unsigned(wpc, 8));
  when others =>
    null;
end case;
end process;

-------------------------------------------------------calc fsm----------------------------------------------------------------
process(clk, rst)
begin
if rst = '1' then
  current_state2 <= RST2;
  i <= 0;
  j <= 0;
  k <= 0;
  
  cnt_calc <= 0;
  calcptrnm <= 0;
  calcptrnn <= 0;
elsif rising_edge(clk) then
  last_state2 <= current_state2;
  current_state2 <= next_state2;
  addrbc_last<=addrbc;
  addrbs_last<=addrbs;
  selt_last<=selt;
  i_last<=i;
    j_last<=j;
    k_last<=k;
  i <= i_next;
  j <= j_next;
  k <= k_next;
  test <= test_next;
  done <= done_next;
  addrcto <= addrct_last;
  addrct_last <= addrct;
  cnt_calc <= cnt_calc_next;
  calcptrnm <= calcptr_nextnm;
  calcptrnn <= calcptr_nextnn;
end if;
end process;

process(all)
begin
case current_state2 is 
  when RST2 =>
    next_state2 <= IDLE2;
    
  when IDLE2 =>
    if flows(cnt_calc).rdyc='1' and flows(cnt_calc).rdys='1' then
      next_state2 <= CALCa;
    else
      next_state2 <= IDLE2;
    end if;
  
    
  when CALCa =>
    next_state2 <= CALCb;
    
  when CALCb =>
    if done = '1' then
      next_state2 <= IDLE2;
    elsif test = 32*flows(cnt_calc).n-1 then
      next_state2 <= CLEARa;
    else
      next_state2 <= CALCa;
    end if;
  
  when CLEARa =>
    next_state2 <= CLEARb;
    
  when CLEARb =>
    next_state2 <= CALCa;
    
  when others =>
    null;
end case;
end process;

process(all)
begin
addrbc <= addrbc_last;
addrbs <= addrbs_last;
test_next<=test;
k_next <= k;
j_next <= j;
i_next <= i;
cnt_calc_next<=cnt_calc;
calcptr_nextnm <= calcptrnm;
calcptr_nextnn <= calcptrnn;
enbc <= '1';
enbs <= '1';
done_next <= done;
enalu <= '0';
case current_state2 is
  when RST2 =>
    k_next <= 0;
    j_next <= 0;
    i_next <= 0;
    calcptr_nextnm <= 0;
    calcptr_nextnn <= 0;
    cnt_calc_next <= 0;
    done_next <=  '0';
    
  when IDLE2 =>
    test_next <= 0;
    done_next <= '0';
    temp<=(others=>'0');
    k_next <= 0;
    j_next <= 0;
    i_next <= 0;

  when CALCa =>
    if k = flows(cnt_calc).n-1 then
      k_next <= 0;
      if j= flows(cnt_calc).m-1 then
        j_next <= 0;
        if i = flows(cnt_calc).n-1 then
          i_next <= 0;
          done_next <= '1';
          cnt_calc_next <= cnt_calc+1;
          if (flows(cnt_calc).n*flows(cnt_calc).m) mod 32 = 0 then
            calcptr_nextnm <= (calcptrnm+(flows(cnt_calc).n*flows(cnt_calc).m)/32)mod 64;
          else
            calcptr_nextnm <= (calcptrnm+(flows(cnt_calc).n*flows(cnt_calc).m)/32+1)mod 64;
          end if;
          if (flows(cnt_calc).n*flows(cnt_calc).n) mod 32 = 0 then
            calcptr_nextnn <= (calcptrnn+(flows(cnt_calc).n*flows(cnt_calc).n)/32) mod 64;
          else
            calcptr_nextnn <= (calcptrnn+(flows(cnt_calc).n*flows(cnt_calc).n)/32+1) mod 64;
          end if;
        else
          i_next <= i+1;
        end if;
      else
        j_next <= j+1;
      end if;
    else
      k_next <= k+1;
    end if;
    

    
    addrbc <= std_logic_vector(to_unsigned(((flows(cnt_calc).n*i+k)/32+calcptrnn) mod 64, 8));
    addrbs <= std_logic_vector(to_unsigned(((flows(cnt_calc).m*k+j)/32+calcptrnm) mod 64, 8));
    selc <= 32-((flows(cnt_calc).n*i+k) mod 32);
    sels <= 32-((flows(cnt_calc).m*k+j) mod 32);
    selt <= 32-((flows(cnt_calc).m*i+j) mod 32);
    data_c <= co(selc*8-1 downto (selc-1)*8);
    data_s <= so(sels*8-1 downto (sels-1)*8);
    data_t <= temp(selt*8-1 downto (selt-1)*8);    
    
  when CALCb =>
    addrbc <= std_logic_vector(to_unsigned(((flows(cnt_calc).n*i+k)/32+calcptrnn) mod 64, 8));
    addrbs <= std_logic_vector(to_unsigned(((flows(cnt_calc).m*k+j)/32+calcptrnm) mod 64, 8));
    selc <= 32-((flows(cnt_calc).n*i_last+k_last) mod 32);
    sels <= 32-((flows(cnt_calc).m*k_last+j_last) mod 32);
    selt <= 32-((flows(cnt_calc).m*i_last+j_last) mod 32);
        temp(selt*8-1 downto (selt-1)*8) <= alu_result;
      test_next <= test + 1;
      
    if done = '1' then
      selt <= selt_last;
      tout <= temp;
      rd(cnt_calc-1) <= '1';
    end if;


  when CLEARa =>
    tout <= temp;
    test_next <= 0;
  
  when CLEARb =>
    temp <= (others => '0');
    
  when others =>
    null;
  
end case;
end process;
end Behavioral;

