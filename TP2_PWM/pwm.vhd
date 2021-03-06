-- Authors : Antoine Laurens, Adrien Thabuis, Hugo Viard
--
-- PWM with programmable period, duty cycle and polarity
--
--
-- 5 address :
-- 00 Enabling of the PWM
-- 01 Period
-- 02 Duty Cycle
-- 03 Polarity
-- 04 Clock divider upper counter limit (on 2 adresses)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY PWMPort IS
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
End PWMPort;

ARCHITECTURE comp OF PWMPort IS
 --   signals for register access
   signal	sEnablePWM: std_logic;
   signal   sPeriod:  std_logic_vector (7 DOWNTO 0);
   signal   sDutyCycle: std_logic_vector (7 DOWNTO 0);
   signal   sPolarity:  std_logic;
   signal   sCounterPWM: std_logic_vector (7 DOWNTO 0);

   signal   sCounterClk: std_logic_vector (15 DOWNTO 0);
   signal 	sUpperClockDivider: std_logic_vector(15 DOWNTO 0);
   signal 	sSlowClk: std_logic; -- Internal signal


BEGIN

  --   PWM output value
	pPWM:
	process(sEnablePWM,sSlowClk,Clk)
	begin
		if rising_edge(Clk) and sEnablePWM = '1'  then
			if sSlowClk = '1' then
				if sCounterPWM < sPeriod then
					sCounterPWM <= std_logic_vector( unsigned(sCounterPWM) + 1 );
				else
					sCounterPWM <= X"00";
				end if;
				if sCounterPWM < sDutyCycle then
					PWMOut <= sPolarity;
				else
					PWMOut <= not sPolarity;
				end if;
			end if;
		end if;
	end process pPWM;


  --   Process Write to registers
	pRegWr:
	process(Clk, nReset)
	begin
		if  nReset = '0' then
			sEnablePWM <= '0';
			sPolarity <= '1';
			sDutyCycle <= (others => '0');    --   Input by default
			sPeriod <= (others => '0');    --   Input by default
			sUpperClockDivider <= (others => '0');    --   Input by default
		elsif rising_edge(Clk) then
			if ChipSelect = '1' and Write = '1' then --   Write cycle
				case Address(2 downto 0) is
					when "000" => sEnablePWM <= WriteData(0); -- We take the LSB
					when "001" => sPeriod <= WriteData;
					when "010" => sDutyCycle <= WriteData;
					when "011" => sPolarity <= WriteData(0); -- We take the LSB
					when "100" => sUpperClockDivider(15 DOWNTO 8) <= WriteData;
					when "101" => sUpperClockDivider(7 DOWNTO 0) <= WriteData;
					when others => null;
				end case;
			end if;
		end if;
	end process pRegWr;


	--   Read Process to registers
	pRegRd:
	process(Clk)
	begin
		if  rising_edge(Clk) then
			ReadData <= (others => '0');  --   default value
			if ChipSelect= '1' and Read = '1' then --   Read cycle
				case Address(2 downto 0) is
					when "000" => ReadData(0) <= sEnablePWM; -- We take the LSB
					when "001" => ReadData <= sPeriod;
					when "010" => ReadData <= sDutyCycle;
					when "011" => ReadData(0) <= sPolarity; -- We take the LSB
					when "100" => ReadData <= sUpperClockDivider(15 DOWNTO 8);
					when "101" => ReadData <= sUpperClockDivider(7 DOWNTO 0);
					when others => null;
				end case;
			end if;
		end if;
	end process pRegRd;


	  --	Process Clock Divider
	ClkDivider:
    process(Clk,sEnablePWM)
    begin
        if rising_edge(Clk) and sEnablePWM = '1' then
            if sCounterClk < sUpperClockDivider then
                sCounterClk <= std_logic_vector( unsigned(sCounterClk) + 1 );
                sSlowClk <= '0';
            elsif sCounterClk = sUpperClockDivider then
                sSlowClk <= '1';
                sCounterClk <= (others => '0');
            elsif sCounterClk > sUpperClockDivider then
                sCounterClk <= (others => '0');
            end if;
        end if;
    end process ClkDivider;


END comp;
