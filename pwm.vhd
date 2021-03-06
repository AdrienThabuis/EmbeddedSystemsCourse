-- Authors : Antoine Laurens, Adrien Thabuis, Hugo Viard
--
-- PWM with programmable period, duty cycle and polarity
--
-- ~ address :
-- 0x00 Enabling of the PWM
-- 0x01 Period
-- 0x02 Duty Cycle
-- 0x03 Polarity
-- 0x04 Clock divider upper counter limit (on 2 adresses)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY PWM IS
	PORT(
--   Avalon interfaces signals
      Clk : IN std_logic;
	  nReset : IN std_logic;
      Address : IN std_logic_vector (2 DOWNTO 0);
      ChipSelect: IN std_logic;
      Read : IN std_logic;
      Write : IN std_logic;
      ReadData : OUT std_logic_vector (7 DOWNTO 0);
      WriteData : IN std_logic_vector (7 DOWNTO 0);

--   PWM external interface
      PWMOut : OUT std_logic
   );
End ParallelPort;

ARCHITECTURE comp OF PWM IS
 --   signals for register access
   signal	sEnableOut: std_logic := '0'; -- PWM module desactivated by default
   signal   sPeriod:  std_logic_vector (7 DOWNTO 0);
   signal   sDutyCycle: std_logic_vector (7 DOWNTO 0);
   signal   sPolarity:  std_logic := '1';  -- High level polarity by default

   signal   sCounter: std_logic_vector (15 DOWNTO 0) := '0'; // See if sCounter has to be a signal or a variable
   signal 	sUpperClockDivider: std_logic_vector(15 DOWNTO 0) := X"03_E8";
   signal 	sSlowClock: std_logic; -- Internal signal - To Enable the Slow module clock


BEGIN

  --   PWM output value
	pPWM:
	process(sEnableOut,sSlowClock)
	begin

	end process pPWM;


  --   Process Write to registers
	pRegWr:
	process(Clk, nReset)
	begin
		if  nReset = '0' then
			sEnableOut <= '0';
			sPolarity <= '1';
			sDutyCycle <= (others => '0');    --   Input by default
			sPeriod <= (others => '0');    --   Input by default
			sUpperClockDivider <= (others => '0');    --   Input by default
		elsif rising_edge(Clk) then
			if ChipSelect = '1' and Write = '1' then --   Write cycle
					case Address(2 downto 0) is
						when "000" => sEnableOut <= WriteData(0); -- We take the LSB
						when "001" => sPeriod <= WriteData;
						when "010" => sDutyCycle <= WriteData;
						when "011" => sPolarity <= WriteData(0); -- We take the LSB
						when "100" => sUpperClockDivider(15 DOWNTO 8) <= WriteData;
						when "101" => sUpperClockDivider(7 DOWNTO 0) <= WriteData;
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process pRegWr;



	ClkDivider:
    process(Clk,nReset)
    begin
        if nReset = '0' then
            sCounter <= (others => '0');      -- reset counter when pressing reset
        elsif rising_edge(Clk) then
            if sCounter < sUpperClockDivider then
                sCounter <= std_logic_vector( unsigned(sCounter) + 1 );
                sSlowClock <= '0';
            elsif sCounter = sUpperClockDivider then
                sSlowClock <= '1';
                sCounter <= (others => '0');
            elsif sCounter > sUpperClockDivider then
                sCounter <= (others => '0');
            end if;
        end if;
    end process ClkDivider;


END comp;
