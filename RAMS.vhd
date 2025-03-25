-- Simple Dual-Port Block RAM with One Clock
-- From https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Simple-Dual-Port-Block-RAM-with-Single-Clock-VHDL
-- File:simple_dual_one_clock.vhd
-- RAM for the coefficient matrix

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity RAMS is
port(
clk : in std_logic;
ena : in std_logic;
enb : in std_logic;
wea : in std_logic;
addra : in std_logic_vector(7 downto 0);
addrb : in std_logic_vector(7 downto 0);
dia : in std_logic_vector(255 downto 0);
dob : out std_logic_vector(255 downto 0)
);
end RAMS;

architecture syn of RAMS is
type ram_type is array (63 downto 0) of std_logic_vector(255 downto 0);
shared variable RAM : ram_type;
begin
process(clk)
begin
if clk'event and clk = '1' then
if ena = '1' then
if wea = '1' then
RAM(conv_integer(addra)) := dia;
end if;
end if;
end if;
end process;

process(clk)
begin
if clk'event and clk = '1' then
if enb = '1' then
dob <= RAM(conv_integer(addrb));
end if;
end if;
end process;

end syn;
