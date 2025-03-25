-- mul_gf256_tb.vhd
-- ---------------------------------------------------
-- TB: Full multiplier in GF(2^8)
-- ---------------------------------------------------
--
-- Exhaustive test for multiplier in GF(2^8) with the
-- characteristic polynomial:
-- P(x) = 285 <edit stim gen for other polynomials>
--
-- ---------------------------------------------------
-- William Wulff
-- 02.2025
-- ---------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.env.finish;
use std.textio.all;

entity mul_gf256_tb is
--
end entity mul_gf256_tb;

architecture tb of mul_gf256_tb is
  signal a : std_logic_vector(7 downto 0);
  signal b : std_logic_vector(7 downto 0);
  signal y : std_logic_vector(7 downto 0);

  signal clk : std_logic;
begin
  MUL : entity work.MUL
    port map (
      clk => clk,
      a => a,
      b => b,
      y => y
      );
  
  process
    file text_file : text open read_mode is "stimulus.txt";
    variable text_line : line;
    variable rtn : boolean;

    variable a_stim : integer;
    variable b_stim : integer;
    variable y_stim : integer;
  begin
    while not endfile(text_file) loop
      clk <= '0';
      
      readline(text_file, text_line);

      if text_line.all'length = 0 or text_line.all(1) = '#' then
        next;
      end if;

      read(text_line, a_stim, rtn);
      assert rtn
        report "Read 'A' failed for line: " & text_line.all
        severity failure;

      read(text_line, b_stim, rtn);
      assert rtn
        report "Read 'B' failed for line: " & text_line.all
        severity failure;

      read(text_line, y_stim, rtn);
      assert rtn
        report "Read 'Y' failed for line: " & text_line.all
        severity failure;

      a <= std_logic_vector(to_unsigned(a_stim, a'length));
      b <= std_logic_vector(to_unsigned(b_stim, b'length));     
      clk <= '1';
      
      wait for 1 ns;

      report "" & integer'image(a_stim) & " * " & integer'image(b_stim) & " = " & integer'image(to_integer(unsigned(y)));
      
      assert y = std_logic_vector(to_unsigned(y_stim, y'length))
        report "Incorrect result! Should be: " & integer'image(y_stim);
    end loop;

    finish;
    
  end process;
end architecture tb;       
