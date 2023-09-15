library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exercise3 is
	port(
		clk:		in std_logic;
		rst:		in std_logic;
		data:		in std_logic;
		
		seq_found: 	out std_logic
	);
end entity;

architecture TEST of exercise3 is
	
	type state is (st_1, st_2, st_3, st_4, st_5);
	signal pr_state, nx_state: state;
	
begin

	process(all) is
	begin
		if rst = '1' then
			
			pr_state <= st_1;
			
		elsif rising_edge(clk) then
			
			pr_state <= nx_state;
			
		end if;
	end process;

	process(all) is
	begin
		case pr_state is
			when st_1 => 				if data = '1' then
								nx_state <= st_2;
								else
								nx_state <= st_1;
								end if;
								
								seq_found <= '0';
			
			when st_2 => 				if data = '0' then
								nx_state <= st_3;
								else
								nx_state <= st_1;
								end if;
								
								seq_found <= '0';
			
			when st_3 => 				if data = '1' then
								nx_state <= st_4;
								else
								nx_state <= st_1;
								end if;
								
								seq_found <= '0';
			
			when st_4 => 				if data = '1' then
								nx_state <= st_5;
								else
								nx_state <= st_3;
								end if;
								
								seq_found <= '0';
			
			when st_5 =>				if data = '1' then
								nx_state <= st_2;
								else
								nx_state <= st_1;
								end if;
								
								seq_found <= '1';
								
			when others => 				seq_found <= '0';
								nx_state <= st_1;
		end case;
	end process;
end architecture;
