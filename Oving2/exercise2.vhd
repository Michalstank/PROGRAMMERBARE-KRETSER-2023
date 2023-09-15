library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exercise2 is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ena: in std_logic;
		cnt_sel: in std_logic;
		
		count: out std_logic_vector(9 downto 0)
	);
end entity;

architecture exercise2 of exercise2 is
begin	
	process(clk) is
		
		variable clk_c: integer range 0 to 5000001;
		
	begin	
		if rst = '0' then
			count <= "0000000001";
		elsif rising_edge(clk) then
			clk_c := clk_c + 1;
			
			if clk_c = 5000000 then
			
				clk_c := 0;
			
				if ena = '1' then
					if cnt_sel = '1' then
						-- LFSR COUNTING
						count(9 downto 1) 	<= count(8 downto 0);
						count(0) 				<= count(9) xor count(6) xor count(0);
					elsif cnt_sel = '0' then
						-- BINARY COUNTING
						count <= std_logic_vector(signed(count) + 1);
					end if;
				end if;
			end if;
		end if;
	end process;
end architecture;