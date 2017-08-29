--------------------------------------------------------------------------------
-- Company: 
-- Engineer: Marcel Szewczyk
--
-- Create Date:   09:50:49 06/23/2013
-- Design Name:   
-- Module Name:   D:/XilinxPrj/clk_div/main_tb.vhd
-- Project Name:  clk_div
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: main
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY main_tb IS
END main_tb;
 
ARCHITECTURE behavior OF main_tb IS 
 
-- Component Declaration for the Unit Under Test (UUT)

COMPONENT main
PORT(
	main_clk : IN  std_logic;
	reset : IN  std_logic;
	glitch_req : IN  std_logic;
	clk_en : IN  std_logic;
	clk_en2 : IN  std_logic;
	driver_clk_out : OUT  std_logic;
	target_clk_out_inv : OUT  std_logic;
	target_clk_out_not_inv : OUT  std_logic;
	glitchless_clk : OUT  std_logic
);
END COMPONENT;


--Inputs
signal main_clk : std_logic := '0';
signal reset : std_logic := '0';
signal glitch_req : std_logic := '0';
signal clk_en : std_logic := '0';
signal clk_en2 : std_logic := '0';

--Outputs
signal driver_clk_out : std_logic;
signal target_clk_out_inv : std_logic;
signal target_clk_out_not_inv : std_logic;
signal glitchless_clk : std_logic;

-- Clock period definitions
constant main_clk_period : time := 10 ns;
constant clk_en_period : time := 10 ns;
constant clk_en2_period : time := 10 ns;
constant glitchless_clk_period : time := 10 ns;

BEGIN

-- Instantiate the Unit Under Test (UUT)
uut: main PORT MAP (
	main_clk => main_clk,
	reset => reset,
	glitch_req => glitch_req,
	clk_en => clk_en,
	clk_en2 => clk_en2,
	driver_clk_out => driver_clk_out,
	target_clk_out_inv => target_clk_out_inv,
	target_clk_out_not_inv => target_clk_out_not_inv,
	glitchless_clk => glitchless_clk
);

-- Clock process definition
main_clk_process :process
begin
	main_clk <= '0';
	wait for main_clk_period/2;
	main_clk <= '1';
	wait for main_clk_period/2;
end process;


-- Stimulus process
stim_proc: process
begin		
-- hold reset state for 10 ns
	wait for 10 ns;
	reset <= '1';		
	clk_en2 <= '1';
	wait for 20 ns;
	glitch_req <= '1';
	wait for main_clk_period*28;
	glitch_req <= '0';

	wait;
end process;

END;
