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

entity thunderbird_fsm is 
    port (
        i_clk, i_reset : in  std_logic;
        i_left, i_right : in  std_logic;
        o_lights_L : out std_logic_vector(2 downto 0);
        o_lights_R : out std_logic_vector(2 downto 0)
    );
end entity thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is
    signal S: std_logic_vector(7 downto 0) := "10000000"; -- Initial state OFF
    signal S_next: std_logic_vector(7 downto 0);
    signal o_LC, o_LB, o_LA, o_RA, o_RB, o_RC: std_logic;
begin
    -- Next-state logic
    process(i_clk, i_reset)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                S <= "10000000"; -- Reset to state OFF
            else
                S <= S_next;
            end if;
        end if;
    end process;

    -- Next-state equations based on the corrected state table
    S_next(7) <= (S(7) and i_left and i_right) or S(6) or S(3) or S(0); -- S7*
    S_next(6) <= S(7) and i_left and i_right; -- S6* (ON state)
    S_next(5) <= S(4); -- S5* (Following S4, could be part of a right turn sequence)
    S_next(4) <= S(5); -- S4* (Following S5, could be part of a right turn sequence)
    S_next(3) <= S(2); -- S3* (Following S2, could be part of a right turn sequence)
    S_next(2) <= (S(7) and i_left and not i_right) or S(1); -- S2* (L2 state or following S1)
    S_next(1) <= S(2) or (S(7) and i_left and not i_right); -- S1* (L3 state or following S2)
    S_next(0) <= S(1) or S(6); -- S0* (Following L3 or ON state)

    -- Output logic
    o_LC <= '1' when S(2) = '1' or S(1) = '1' or S(0) = '1' else '0';
    o_LB <= '1' when S(1) = '1' or S(0) = '1' else '0';
    o_LA <= '1' when S(0) = '1' else '0';
    o_RA <= '1' when S(5) = '1' or S(4) = '1' or S(3) = '1' else '0';
    o_RB <= '1' when S(4) = '1' or S(3) = '1' else '0';
    o_RC <= '1' when S(3) = '1' else '0';
    
    o_lights_L <= o_LC & o_LB & o_LA;
    o_lights_R <= o_RA & o_RB & o_RC;
end architecture thunderbird_fsm_arch;
