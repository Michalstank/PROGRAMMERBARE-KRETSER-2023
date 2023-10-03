library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exercise4 is
	generic(
		CODE: natural  := 4321
	);

	port(
		clk: 			in std_logic; -- Clock Signal
		rst: 			in std_logic; -- Reset Signal
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

architecture project of exercise4 is
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
	
	
	type states is (start, hex0_incr, hex1_incr, hex2_incr, hex3_incr, displayHex, openClose, reset);
	
	attribute fsm_state  : string;
	attribute fsm_state  of states: type is "one_hot";
	
	signal pr_state, nx_state: states;
	
	signal clk_cnt: natural;
	
begin

	-- State Transition
	process(all)
	begin
		if rst = '0' then
			
			pr_state <= reset;
			
		elsif rising_edge(clk) then
			
			pr_state <= nx_state;
			
		end if;
	end process;

	-- State Handler
	process(all)
	begin
		if rst = '0' then
			
			nx_state <= reset;
			
		elsif rising_edge(clk) then
			if ((clk_cnt mod F_CPU) = 0) then
				case pr_state is
					when start 			=> if seg_sel = "00" then
													nx_state <= hex0_incr;
												elsif seg_sel = "01" then
													nx_state <= hex1_incr;
												elsif seg_sel = "10" then
													nx_state <= hex2_incr;
												elsif seg_sel = "11" then
													nx_state <= hex3_incr;
												else 
													nx_state <= start;
												end if;
					
					when hex0_incr 	=> nx_state <= displayHex;
					
					when hex1_incr 	=> nx_state <= displayHex;
					
					when hex2_incr 	=> nx_state <= displayHex;
					
					when hex3_incr 	=> nx_state <= displayHex;
					
					when displayHex 	=> nx_state <= openClose;
					
					when openClose 	=> nx_state <= start;
					
					when reset 			=> nx_state <= start;
				end case;
			end if;
		end if;
	end process;

	-- Operation Handler
	process(all)
		
		variable hex0_mask: natural := 0;
		variable hex1_mask: natural := 0;
		variable hex2_mask: natural := 0;
		variable hex3_mask: natural := 0;
		
		variable SafeCode: string(1 to 4) := natural'image(code);
		
		variable codeValue: natural;
		
	begin
		if rst = '0' then
			
			hex0_mask := 0;
			hex1_mask := 0;
			hex2_mask := 0;
			hex3_mask := 0;
			codeValue := 0;
			
			open_led <= '1';
			
		elsif rising_edge(clk) then
			if ((clk_cnt mod F_CPU) = 0) then
				
				clk_cnt <= 0;
				
				case pr_state is
					when  start => 		open_led <= '0';
					
					when hex0_incr => 	if incr_key = '0' then
													hex0_mask := (hex0_mask + 1) mod 10;
												end if;
												open_led <= '0';
					
					when hex1_incr => 	if incr_key = '0' then
													hex1_mask := (hex1_mask + 1) mod 10;
												end if;
												open_led <= '0';
										
					when hex2_incr => 	if incr_key = '0' then
													hex2_mask := (hex2_mask + 1) mod 10;
												end if;
												open_led <= '0';
											
					when hex3_incr => 	if incr_key = '0' then
													hex3_mask := (hex3_mask + 1) mod 10;
												end if;
												open_led <= '0';
											
					when displayHex =>	if sw9 = '1' then
													hex0 <= displayValue(safeCode(1));
													hex1 <= displayValue(safeCode(2));
													hex2 <= displayValue(safeCode(3));
													hex3 <= displayValue(safeCode(4));
												else 
													hex0 <= displayValue(hex0_mask);
													hex1 <= displayValue(hex1_mask);
													hex2 <= displayValue(hex2_mask);
													hex3 <= displayValue(hex3_mask);
												end if;
												open_led <= '0';
											
					when openClose => 	codeValue := hex3_mask + 10 * hex2_mask + 100 * hex1_mask + 1000 * hex0_mask;
											
												if (sw0 = '1' and codeValue = code) then
													open_led <= '1';
												else
													open_led <= '0';
												end if;
									
					when reset =>			hex0_mask := 0;
												hex1_mask := 0;
												hex2_mask := 0;
												hex3_mask := 0;
												open_led <= '1';
												codeValue := 0;
				end case;
			end if;
			clk_cnt <= clk_cnt + 1;
		end if;
	end process;


end architecture;
