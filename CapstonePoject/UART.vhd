library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART is
	generic(
		F_CPU: natural := 50_000_000;
		BAUD: natural := 9_600;
		BAUD_RATE: natural := 50_000_000/9_600;
		SAMPLE_RATE: natural := 50_000_000/(8*9_600)
	);
	
	port(
		clk: in std_logic;
		rstn: in std_logic;
		
		rx_signal: in std_logic;
		
		tx_signal: out std_logic := '1';
		
		-- Display of recived data
		display_hex1,
		display_hex2: out std_logic_vector(7 downto 0)
	);
end entity;


architecture UART_ARCH of UART is
	-------------------------- STATES --------------------------
	
	type rx_states is (idle,bit_sampling,byte_processing,display_state, buffer_state);
	signal state:  rx_states;
	
	type tx_states is (await, transmit);
	signal tx_state: tx_states := await;
	
	
	-------------------------- SIGNALS --------------------------
	
	-- Data Register
	signal UART_RX_DATA: std_logic_vector(7 downto 0) := 		"00000000";
	
	-- Sampling Register
	signal UART_RX_SAMPLE: std_logic_vector(7 downto 0) := 	"00000000";
	
	-- Status Register
	signal UART_RX_STATUS: std_logic_vector(3 downto 0) := 	"0001";
	
	/*
		0 - Wait For Startbit
		1 - Sampling
		2 - Transmiting Data
		3 - Read Data Ready
	*/
	
	-- Tx Transmit Register
	signal UART_TX_DATA: std_logic_vector(7 downto 0) := "00000000";
	
	signal UART_TX_BYTE_CNT: 	natural range 0 to 9:= 0;
	
	-- TX Module Counters
	signal UART_TX_CLK_CNT:		natural := 0;
		
	
	-- Clock Counter of Sampling Counter
	signal UART_RX_SAMPLE_CNT: natural := 0;
	
	signal UART_RX_BYTE_CNT: 	natural range 0 to 9:= 0;
	signal UART_RX_SMP_CNT: 	natural range 0 to 9:= 0;	
	
	--Detect Falling Edge
	signal rx_input: 	std_logic := '1';
	signal rx_prev:	std_logic := '1';
	
	
	-------------------------- FUNCTIONS --------------------------
	
	pure function display(input: std_logic_vector) return std_logic_vector is		
		
		variable output: std_logic_vector(7 downto 0) := "00000000";
		
	begin
		
		case input is
			when "0000" => output := "11000000"; -- Print 0
			when "0001" => output := "10110000"; -- Print 1
			when "0010" => output := "10100100"; -- Print 2
			when "0011" => output := "10110000"; -- Print 3
			when "0100" => output := "10011001"; -- Print 4
			when "0101" => output := "10010010"; -- Print 5
			when "0110" => output := "10000010"; -- Print 6
			when "0111" => output := "11111000"; -- Print 7
			when "1000" => output := "10000000"; -- Print 8
			when "1001" => output := "10010000"; -- Print 9
			when "1010" => output := "10001000"; -- Print A
			when "1011" => output := "10000011"; -- Print B
			when "1100" => output := "11000110"; -- Print C
			when "1101" => output := "10100001"; -- Print D
			when "1110" => output := "10000110"; -- Print E
			when "1111" => output := "10001110"; -- Print F
			when others => null;
		end case;
		
		return output;
		
	end function;
	
	--Check If High/Low
	pure function byte_value(input: std_logic_vector) return std_logic is
		
		variable output: std_logic;
		
	begin
		
		if to_integer(unsigned(input)) = 15 then
			output := '1';
		else
			output := '0';
		end if;
		
		return output;
	end function;
	
	
begin
	
	-- ###########################################################
	-- ###																	  ###
	-- ###							RX MODULE							  ###
	-- ###																	  ###
	-- ###########################################################
	
	-- Clock Dependent Input Detection For Clock Independent Signal
	process(all) is
	begin
		
		if rising_edge(clk) then
			
			rx_input <= rx_signal;
			
		end if;
		
	end process;
	
	rx_prev <= rx_input when rising_edge(clk);	
	
	-- Logic For which State To Change To
	State_Transitions: process(all)
	begin
		if rstn = '0' then
			state <= idle;
		elsif rising_edge(clk) then
			
			--Tired, Logic Probably Broke but me thinks it works
			case state is
				--Wait For Input				--Wait For Startbit Detection
				when idle 					=> if UART_RX_STATUS(0) = '1' then
														state <= idle;
													else
														state <= bit_sampling;
													end if;
					
				--Sample Input					-- If Sampling Bit Set To 1, Stay In State
				when bit_sampling 		=> if UART_RX_STATUS(1) = '1' then
														state <= bit_sampling;
													else
														state <= byte_processing;
													end if;
					
				--Process Sampled Input		-- If Byte Ready Print Out
				when byte_processing 	=> state <= buffer_state;
													
				when buffer_state				=> if UART_RX_STATUS(3) = '1' then
														state <= display_state;
													else 
														state <= bit_sampling;
													end if;
					
				--Display Input
				when display_state 		=> state <= idle;
				when others 				=> null;
			end case;
		end if;
	end process;
	
	-- Logic For what to do every State
	Value_Processing: process(all)
		
		variable limit: natural;
		
	begin
		if rstn = '0' then
			
			UART_RX_DATA 			<= "00000000";
			UART_RX_SAMPLE 		<= "00000000";
			UART_RX_BYTE_CNT 		<= 0;
			UART_RX_SAMPLE_CNT 	<= 0;
			
		elsif rising_edge(clk) then
			
			case state is				
				-- Idle State					-- Reset All Registers/Values
				when idle 					=> UART_RX_DATA 			<= "00000000";
													UART_RX_SAMPLE 		<= "00000000";
													UART_RX_BYTE_CNT 		<= 0;
													UART_RX_SAMPLE_CNT 	<= 0;
													
													-- BROKE ASS FALLING EDGE DETECTION
													if (rx_prev xor rx_input) = '1' and rx_prev = '1' then
														UART_RX_STATUS(0) <= '0';
														UART_RX_STATUS(1) <= '1';
													else 
														UART_RX_STATUS(0) <= '1';
													end if;
													
					
				-- Bit Sampling				-- Loop Over Input Signal
				when bit_sampling 		=> -- If Signal Is In The Middle Of The Bit 
													if (UART_RX_SAMPLE_CNT = SAMPLE_RATE/2) and (UART_RX_SMP_CNT <= 7) then
														
														UART_RX_SAMPLE(UART_RX_SMP_CNT) <= rx_signal;
														
													else
														
														NULL;
														
													end if;
													
													
													-- Increase/Reset Sample Counter
													if UART_RX_SAMPLE_CNT = SAMPLE_RATE then
														
														-- Reset Counter
														UART_RX_SAMPLE_CNT <= 0;
														
														-- If Count = 7 Exit State Switch to Byte Processing
														if UART_RX_SMP_CNT >= 7 then
															-- Exit Sampling State
															UART_RX_STATUS(1) <= '0';
															
															--Reset Counter
															UART_RX_SMP_CNT <= 0;
															
														else 
															--Increase Sample Count
															UART_RX_SMP_CNT <= UART_RX_SMP_CNT + 1;
															
															--Stay In Sampling State
															UART_RX_STATUS(1) <= '1';
														end if;
														
													else
														--Increase Sample Counter
														UART_RX_SAMPLE_CNT <= UART_RX_SAMPLE_CNT + 1;
														
														--Stay In Stampling State
														UART_RX_STATUS(1) <= '1';
													end if;
				
				-- Process Byte From Bit	-- Whenever Bit Recived Process Output Variable
													-- Seems To Work
				when byte_processing 	=>	UART_RX_DATA(UART_RX_BYTE_CNT) <= byte_value(UART_RX_SAMPLE(5 downto 2));
													
													UART_RX_SAMPLE <= "00000000";
													
													UART_RX_BYTE_CNT <= UART_RX_BYTE_CNT + 1;
													
													if UART_RX_BYTE_CNT >= 7 then
														
														UART_RX_BYTE_CNT <= 0;
														UART_RX_STATUS(3) <= '1';
														
													else
														
														UART_RX_STATUS(3) <= '0';
														
													end if;
				
				-- Code For Display			-- Display Hex Values
				when display_state	 	=> display_hex1 <= display(UART_RX_DATA(7 downto 4));
													display_hex2 <= display(UART_RX_DATA(3 downto 0));
													UART_RX_STATUS(3) <= '0';
													
				when others => NULL;
			end case;
		end if;
	end process;
	
	-- ###########################################################
	-- ###																	  ###
	-- ###							TX MODULE							  ###
	-- ###																	  ###
	-- ###########################################################
	
	-- Not Sure If Needed
	tx_state_transition: process(all)
	begin
		if rstn = '0' then
			
			tx_state <= await;
			--UART_TX_DATA <= "00000000";
			
			--UART_TX_BYTE_CNT <= 0;
			
		elsif rising_edge(clk) then
			case tx_state is			-- If Data Ready From RX
				when 		await 	=> if UART_RX_STATUS(3) = '1' then
												-- Change State to Transmit
												tx_state <= transmit;
												

											end if;
				
											-- If Done Transmiting Change To Await State
				when 		transmit => if UART_RX_STATUS(2) = '0' then
												tx_state <= await;
											end if;
				
				when others 		=> NULL;
			end case;
		end if;
	end process;
	
	-- When Data Ready Send It Out
	tx_mod: process(all)
	begin
		if rstn = '0' then
			UART_TX_DATA 	<= "00000000";
			
			UART_TX_BYTE_CNT <= 0;
			
		elsif rising_edge(clk) then
			case tx_state is
				
				-- Wait For Data Ready, So Do Nothing
				when 		await 	=> 	-- Copy Data To Send Out Over TX
												UART_TX_DATA <= UART_RX_DATA;
												
												tx_signal <= '1';
												
												if UART_RX_STATUS(3) = '1' then
													-- Change Status To Transmiting
													UART_RX_STATUS(2) <= '1';
												end if;
				
				-- Print Data To Tx Signal Line
				when 		transmit => if UART_TX_CLK_CNT >= BAUD_RATE then
												-- Reset Counter and Increase Byte Position
												UART_TX_BYTE_CNT 	<= UART_TX_BYTE_CNT + 1;
												UART_TX_CLK_CNT 	<= 0;
												
											else
											
												tx_signal <= UART_TX_DATA(UART_TX_BYTE_CNT);
												
												-- Increase Counter
												UART_TX_CLK_CNT <= UART_TX_CLK_CNT + 1;
												
											end if;
											
											
											
											-- If End Reached Change Output Signal To High And Exit Transmit State
											if UART_TX_BYTE_CNT > 7 then
											
												UART_RX_STATUS(2) <= '0';
												
												tx_signal <= '1';		
			
												UART_TX_CLK_CNT <= 0;
												UART_TX_BYTE_CNT <= 0;
											end if;
				
				when others 		=> NULL;
			end case;
		end if;
	end process;

end architecture;
