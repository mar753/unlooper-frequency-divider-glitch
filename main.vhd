----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Marcel Szewczyk
-- 
-- Create Date:    15:37:43 03/31/2013 
-- Design Name: 	Unlooper v2 clock divider and glitch logic
-- Module Name:    main - Behavioral 
-- Project Name: 
-- Target Devices: XC9536XL
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
Port ( 
	main_clk : in  STD_LOGIC;
	reset : in STD_LOGIC;
	glitch_req : in  STD_LOGIC; 
	clk_en : in  STD_LOGIC; 
	clk_en2 : in  STD_LOGIC; 
	driver_clk_out : out  STD_LOGIC; 
	target_clk_out_inv : out  STD_LOGIC; 
	target_clk_out_not_inv : out STD_LOGIC;
	glitchless_clk : out  STD_LOGIC 
	);
end main;

architecture Behavioral of main is
signal counter : std_logic; -- 1 bit counter (div4) GL #1
signal counter2 : std_logic_vector(2 downto 0); -- 3 bit counter (div7_rising) DRIVER
signal counter3 : std_logic_vector(2 downto 0); -- 3 bit counter (div7_falling) DRIVER
signal counter4 : std_logic_vector(1 downto 0); -- 2 bit counter (div8) GL #2
signal counter5 : std_logic_vector(4 downto 0); -- 5 bit counter (div56) TARGET

signal div2_tmp : std_logic;
signal div4_tmp : std_logic;
signal div7_falling_tmp : std_logic;
signal div7_rising_tmp : std_logic;
signal div7_ored_tmp : std_logic;
signal div7_tmp : std_logic;
signal start_div7_falling : std_logic;
signal div8_tmp : std_logic;
signal div56_tmp : std_logic;

signal glitch_queue : std_logic;
signal start_glitch : std_logic;
signal stop_glitch : std_logic;
signal stop_glitch2 : std_logic;
signal stop_glitch3 : std_logic;
signal mux_sync_signal : std_logic_vector(2 downto 0);
signal clk_en_sync : std_logic;
signal clk_en2_sync : std_logic;

begin

div2: process(main_clk, reset) -- 50MHz
begin
	if(reset = '0') then
		div2_tmp <= '0';
	elsif(rising_edge(main_clk)) then	
		div2_tmp <= not div2_tmp;
	end if;
end process; 

div4: process(main_clk, reset) -- 25MHz
begin
	if(reset = '0') then
		counter <= '0';
		div4_tmp <= '0';
	elsif(rising_edge(main_clk)) then
		if(counter = '0') then
			div4_tmp <= not div4_tmp;
		end if;
		counter <= not counter;
	end if;
end process; 

div7_rising: process(main_clk, reset)
begin
	if(reset = '0') then
		counter2 <= "000";
		div7_rising_tmp <= '0';
		start_div7_falling <= '0';
	elsif(rising_edge(main_clk)) then	
		if(counter2 = "000") then
			counter2 <= "110";
			div7_rising_tmp <= '1';			
		else
			counter2 <= std_logic_vector(unsigned(counter2)-1);
			div7_rising_tmp <= '0';
		end if;
		start_div7_falling <= '1';
	end if;
end process; 

div7_falling: process(main_clk, reset)
begin
	if(reset = '0') then
		counter3 <= "000";
		div7_falling_tmp <= '0';
	elsif(falling_edge(main_clk)) then	
		if(start_div7_falling = '1') then --zalezne od poprzedniego procesu
			if(counter3 = "101") then
				counter3 <= "011";
				div7_falling_tmp <= '1';			
			else
				counter3 <= std_logic_vector(unsigned(counter3)-1);
				div7_falling_tmp <= '0';
			end if;
		end if;
	end if;
end process;

div7_ored_tmp <= div7_falling_tmp or div7_rising_tmp;

div7: process(div7_ored_tmp, reset) -- 14,286 MHz
begin
	if(reset = '0') then
		div7_tmp <= '0';
	elsif(rising_edge(div7_ored_tmp)) then	
		div7_tmp <= not div7_tmp;
	end if;
end process;

div8: process(main_clk, reset) -- 12,5MHz
begin
	if(reset = '0') then
		counter4 <= "00";
		div8_tmp <= '0';
	elsif(rising_edge(main_clk)) then	
		if(counter4 = "00") then
			counter4 <= "11";
			div8_tmp <= not div8_tmp;			
		else
			counter4 <= std_logic_vector(unsigned(counter4)-1);
		end if;
	end if;
end process; 

div56: process(main_clk, reset) -- 1,786 MHz
begin
	if(reset = '0') then
		counter5 <= "00000";
		div56_tmp <= '0';
	elsif(rising_edge(main_clk)) then
		if(counter5 = "00000") then
			counter5 <= "11011"; 
			div56_tmp <= not div56_tmp;		
		else		
			counter5 <= std_logic_vector(unsigned(counter5)-1);
		end if;
	end if;
end process; 

glitch_in_queue: process(reset, glitch_req, stop_glitch, stop_glitch2, stop_glitch3)
begin
	if(reset = '0' or stop_glitch = '1' or stop_glitch2 = '1' or stop_glitch3 = '1') then
		glitch_queue <= '0';
	elsif(rising_edge(glitch_req)) then
		glitch_queue <= '1';			
	end if;
end process;

start: process(reset, div56_tmp, stop_glitch, stop_glitch2, stop_glitch3)
begin
	if(reset = '0' or stop_glitch = '1' or stop_glitch2 = '1' or stop_glitch3 = '1') then
		start_glitch <= '0';
	elsif(rising_edge(div56_tmp)) then	
		if(glitch_queue = '1') then			
			start_glitch <= '1';	
		end if;
	end if;
end process;

stop: process(reset, div4_tmp, start_glitch)
begin
	if(reset = '0' or start_glitch = '0') then
		stop_glitch <= '0';
	elsif(rising_edge(div4_tmp)) then
		if(start_glitch = '1' and clk_en_sync = '1' and clk_en2_sync = '1') then
			stop_glitch <= '1';		
		end if;
	end if;
end process;

stop2: process(reset, div2_tmp, start_glitch)
begin
	if(reset = '0' or start_glitch = '0') then
		stop_glitch2 <= '0';
	elsif(rising_edge(div2_tmp)) then
		if(start_glitch = '1' and clk_en_sync = '1' and clk_en2_sync = '0') then
			stop_glitch2 <= '1';		
		end if;
	end if;
end process;

stop3: process(reset, div8_tmp, start_glitch)
begin
	if(reset = '0' or start_glitch = '0') then
		stop_glitch3 <= '0';
	elsif(rising_edge(div8_tmp)) then
		if(start_glitch = '1' and clk_en_sync = '0' and clk_en2_sync = '1') then
			stop_glitch3 <= '1';		
		end if;
	end if;
end process;

turn_on_clk_delay_1_cycle: process(reset, div56_tmp) --opoznienie o jeden cykl zegara div56 po pojawieniu sie sygnalu clk_en(2)
begin
	if(reset = '0') then
		clk_en_sync <= '0';
		clk_en2_sync <= '0';
	elsif(rising_edge(div56_tmp)) then				
		clk_en_sync <= clk_en;
		clk_en2_sync <= clk_en2;		
	end if;
end process;

mux_sync_signal <= start_glitch & clk_en_sync & clk_en2_sync;
with mux_sync_signal select
target_clk_out_inv <= 
						'1' WHEN "000",
						not div56_tmp WHEN "001",
						not div56_tmp WHEN "010",
						not div56_tmp WHEN "011",
						'1' WHEN "100",
						not div8_tmp WHEN "101", --12,5MHz
						not div2_tmp WHEN "110", --50MHz
						not div4_tmp WHEN "111", --25MHz
						'X' WHEN OTHERS;
						
with mux_sync_signal select
target_clk_out_not_inv <=
						'0' WHEN "000",
						div56_tmp WHEN "001",
						div56_tmp WHEN "010",
						div56_tmp WHEN "011",
						'0' WHEN "100",
						div8_tmp WHEN "101", --12,5MHz
						div2_tmp WHEN "110", --50MHz
						div4_tmp WHEN "111", --25MHz
						'X' WHEN OTHERS;
					
with mux_sync_signal select  --sygnal do T1 (nieodwrocony)
glitchless_clk <= 
						'0' WHEN "000",
						div56_tmp WHEN OTHERS;

driver_clk_out <= div7_tmp;

end Behavioral;
