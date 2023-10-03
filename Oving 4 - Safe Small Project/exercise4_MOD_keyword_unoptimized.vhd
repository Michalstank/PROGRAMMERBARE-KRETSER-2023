library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exercise4 is
	generic(
		--F_CPU: natural := 1; -- 50 000 000 / 10, Update every 1s
		CODE: natural  := 4321
	);
	port(
		clk: 			in std_logic; -- Clock Signal
		rst_n: 		in std_logic; -- Reset Signal
		incr_key: 	in std_logic; -- Increase Num Button
		
		-- Switches
		sw0: 			in std_logic; 							-- Safe Open/Close
		sw9: 			in std_logic;							-- Display Code/Nums
		seg_sel: 	in std_logic_vector(1 downto 0); -- Select Num
		
		-- Status Led
		open_led: 	out std_logic;
		
		-- Numeric Display
		hex0,
		hex1,
		hex2,
		hex3: 		out std_logic_vector (7 downto 0)
	);
end entity;

architecture balls of exercise4 is

	pure function displayValue(n: natural) return std_logic_vector is
		
		variable mem: std_logic_vector(7 downto 0);
		
	begin
	
	case n is
		when 0 => 		mem := "11000000";
		when 1 => 		mem := "11111001";
		when 2 => 		mem := "10100100";
		when 3 => 		mem := "10110000";
		when 4 => 		mem := "10011001";
		when 5 => 		mem := "10010010";
		when 6 => 		mem := "10000010";
		when 7 => 		mem := "11111000";
		when 8 => 		mem := "10000000";
		when 9 => 		mem := "10010000";
		when others => mem := "11000000";
	end case;
	
	return mem;
	
	end function;
	
	pure function displayValue(n: character) return std_logic_vector is
		
		variable mem: std_logic_vector(7 downto 0);
		
	begin
	
	case n is
		when '0' => 		mem := "11000000";
		when '1' => 		mem := "11111001";
		when '2' => 		mem := "10100100";
		when '3' => 		mem := "10110000";
		when '4' => 		mem := "10011001";
		when '5' => 		mem := "10010010";
		when '6' => 		mem := "10000010";
		when '7' => 		mem := "11111000";
		when '8' => 		mem := "10000000";
		when '9' => 		mem := "10010000";
		when others => 	mem := "11000000";
	end case;
	
	return mem;
	
	end function;

	signal 	hex0_mask,
				hex1_mask,
				hex2_mask,
				hex3_mask: natural := 0;
				
	signal	SafeCode: string(1 to 4) := natural'image(Code);

	signal 	CodeSum: natural;
	
begin

	process(all)
	begin
		if rst_n = '0' then
			
			hex0_mask <= 0;
			hex1_mask <= 0;
			hex2_mask <= 0;
			hex3_mask <= 0;
			
			open_led <= '1';
			
		elsif rising_edge(clk) then
			--Increment Button
			if incr_key = '0' then
				
				case seg_sel is
					when "00" => 	hex0_mask <= (hex0_mask + 1) MOD 10;
					when "01" =>  	hex1_mask <= (hex1_mask + 1) MOD 10;
					when "10" =>  	hex2_mask <= (hex2_mask + 1) MOD 10;
					when "11" =>  	hex3_mask <= (hex3_mask + 1) MOD 10;
					when others => null;
				end case;
			end if;
			
			--Open Close Switch
			if sw0 = '0' then
				
				CodeSum <= hex0_mask + hex1_mask * 10 + hex2_mask * 100 + hex3_mask * 1000;
				
				if (CODE = CodeSum) then
					open_led <= '1';
				else
					--Code Missmatch
					open_led <= '0';
				end if;
			else
				open_led <= '0';
			end if;
			
			--Display Code/Input
			if sw9 = '0' then
				--SHOW INPUT
				hex3 <= displayValue(hex3_mask);
				hex2 <= displayValue(hex2_mask);
				hex1 <= displayValue(hex1_mask);
				hex0 <= displayValue(hex0_mask);
				
			else
				--SHOW CODE
				hex3 <= displayValue(SafeCode(1));
				hex2 <= displayValue(SafeCode(2));
				hex1 <= displayValue(SafeCode(3));
				hex0 <= displayValue(SafeCode(4));
			end if;
			
			
		end if;
	end process;
end architecture;
