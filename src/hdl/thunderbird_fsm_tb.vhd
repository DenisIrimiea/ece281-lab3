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
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
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
 
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
    component thunderbird_fsm is 
        port(
            i_clk      : in  std_logic;
            i_reset    : in  std_logic;
            i_left     : in  std_logic;
            i_right    : in  std_logic;
            o_lights_L : out  std_logic_vector(2 downto 0);
            o_lights_R : out  std_logic_vector(2 downto 0)
        );
    end component;

    signal i_clk   : std_logic := '0';
    signal i_reset : std_logic := '0';
    signal i_left  : std_logic := '0';
    signal i_right : std_logic := '0';
    signal o_lights_L : std_logic_vector(2 downto 0);
    signal o_lights_R : std_logic_vector(2 downto 0);
    constant clk_period : time := 10 ns;
    
begin 
    uut: thunderbird_fsm port map (
        i_clk      => i_clk,
        i_reset    => i_reset,
        i_left     => i_left,
        i_right    => i_right,
        o_lights_L => o_lights_L,
        o_lights_R => o_lights_R
    );

    -- Clock process
    clk_process: process
    begin
        while true loop
            i_clk <= '0';
            wait for clk_period / 2;
            i_clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Test process
    sim_proc : process
    begin
        -- Reset the FSM
        i_reset <= '1';
        wait for clk_period * 2;  -- Ensure reset is captured
        i_reset <= '0';
        wait for clk_period * 2;  -- Wait for FSM to move out of the reset state

        -- Scenario 1: No turn signal, taillights should be off
        i_left  <= '0';
        i_right <= '0';
        wait for clk_period * 10;  -- Wait to ensure FSM has processed the input
        assert o_lights_L = "000" and o_lights_R = "000" report "Incorrect taillights state when no turn signal" severity failure;

        -- Scenario 2: Activate Left Turn Signal
i_left <= '1';
i_right <= '0';
wait for clk_period * 10;  -- Adjust the time as needed based on your FSM design
assert o_lights_L /= "000" report "Left turn signal did not activate correctly" severity failure;
assert o_lights_R = "000" report "Right turn signal should be off during left turn signal" severity failure;
i_left <= '0';  -- Turn off the left signal
wait for clk_period * 2;

-- Scenario 3: Activate Right Turn Signal
i_left <= '0';
i_right <= '1';
wait for clk_period * 10;  -- Adjust the time as needed
assert o_lights_R /= "000" report "Right turn signal did not activate correctly" severity failure;
assert o_lights_L = "000" report "Left turn signal should be off during right turn signal" severity failure;
i_right <= '0';  -- Turn off the right signal
wait for clk_period * 2;

---- Scenario 4: Activate Hazard Lights (Both Signals)
--i_left <= '1';
--i_right <= '1';
--wait for clk_period * 10;  -- Adjust the time as needed
--assert (o_lights_L /= "000" and o_lights_R /= "000") report "Hazard lights did not activate correctly" severity failure;
--i_left <= '0';
--i_right <= '0';
--wait for clk_period * 2;

-- Scenario 5: Switching directly from left to right signal
i_left <= '1';
i_right <= '0';
wait for clk_period * 5;  -- Halfway through the left signal
i_left <= '0';
i_right <= '1';
wait for clk_period * 10;  -- Allow full cycle for right signal
assert o_lights_R /= "000" report "Right turn signal did not activate correctly after left signal" severity failure;
assert o_lights_L = "000" report "Left turn signal should be off when right turn signal is activated" severity failure;

        -- Additional scenarios should be added here following the same structure
        -- Ensure to reset the inputs and provide adequate wait times between different scenarios

        wait;  -- Hold simulation
    end process;
end test_bench;
