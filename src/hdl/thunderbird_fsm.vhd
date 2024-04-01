--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 xxx State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 10000000
--|                  ON    | 01000000
--|                  R1    | 00100000
--|                  R2    | 00010000
--|                  R3    | 00001000
--|                  L1    | 00000100
--|                  L2    | 00000010
--|                  L3    | 00000001
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is 
  port(
          i_clk, i_reset  : in    std_logic;
          i_left, i_right : in    std_logic;
          o_lights_L      : out   std_logic_vector(2 downto 0);
          o_lights_R      : out   std_logic_vector(2 downto 0)
      );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 
   signal f_Q     : std_logic_vector(7 downto 0) := "10000000"; 
   signal f_Q_next: std_logic_vector(7 downto 0);
-- CONSTANTS ------------------------------------------------------------------
   signal o_LC, o_LB, o_LA, o_RA, o_RB, o_RC : std_logic;

begin
process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                f_Q <= "10000000"; -- Reset to OFF state
            else
                f_Q <= f_Q_next;   -- Update state
            end if;
        end if;
    end process;
	-- CONCURRENT STATEMENTS --------------------------------------------------------	
process(f_Q, i_left, i_right)
        begin
            -- Default next state is the current state
            f_Q_next <= f_Q;  
            case f_Q is
                when "10000000" =>  -- OFF state
                    if i_left = '1' and i_right = '0' then
                        f_Q_next <= "01000000";  -- Transition to L1
                    elsif i_right = '1' and i_left = '0' then
                        f_Q_next <= "00010000";  -- Transition to R1
                    elsif i_left = '1' and i_right = '1' then
                        f_Q_next <= "00000001";  -- Transition to ON (hazard)
                    end if;
                when "01000000" =>  -- L1 state
                    if i_left = '1' then
                        f_Q_next <= "00100000";  -- Transition to L2
                    else
                        f_Q_next <= "10000000";  -- Back to OFF
                    end if;
                when "00100000" =>  -- L2 state
                    if i_left = '1' then
                        f_Q_next <= "00001000";  -- Transition to L3
                    else
                        f_Q_next <= "10000000";  -- Back to OFF
                    end if;
                when "00001000" =>  -- L3 state
                    if i_left = '1' then
                        f_Q_next <= "01000000";  -- Cycle back to L1
                    else
                        f_Q_next <= "10000000";  -- Back to OFF
                    end if;
                when "00010000" =>  -- R1 state
                    if i_right = '1' then
                        f_Q_next <= "00000100";  -- Transition to R2
                    else
                        f_Q_next <= "10000000";  -- Back to OFF
                    end if;
                when "00000100" =>  -- R2 state
                    if i_right = '1' then
                        f_Q_next <= "00000010";  -- Transition to R3
                    else
                        f_Q_next <= "10000000";  -- Back to OFF
                    end if;
                when "00000010" =>  -- R3 state
                    if i_right = '1' then
                        f_Q_next <= "00010000";  -- Cycle back to R1
                    else
                        f_Q_next <= "10000000";  -- Back to OFF
                    end if;
                when "00000001" =>  -- ON state (hazard)
                    if i_left = '0' and i_right = '0' then
                        f_Q_next <= "10000000";  -- Back to OFF
                    else
                        f_Q_next <= "00000001";  -- Stay in ON (hazard)
                    end if;
                when others =>
                    f_Q_next <= "10000000"; -- Failsafe to OFF state
            end case;
        end process;	
    ---------------------------------------------------------------------------------
 o_LC <= '1' when f_Q(0) = '1' or f_Q(1) = '1' else '0';
        o_LB <= '1' when f_Q(0) = '1' or (f_Q(6) = '1' and f_Q(5) = '1') else '0';
        o_LA <= '1' when f_Q(1) = '1' or f_Q(6) = '1' else '0';
        o_RA <= '1' when f_Q(1) = '1' or f_Q(3) = '1' else '0';
        o_RB <= '1' when f_Q(1) = '1' or f_Q(2) = '1' else '0';
        o_RC <= '1' when f_Q(1) = '1' or f_Q(4) = '1' else '0';
o_lights_L <= o_LC & o_LB & o_LA;
o_lights_R <= o_RA & o_RB & o_RC;
  
  end thunderbird_fsm_arch;	