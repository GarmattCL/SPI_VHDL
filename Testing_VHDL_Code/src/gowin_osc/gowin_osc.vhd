--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--Tool Version: V1.9.10.02
--Part Number: GW1N-LV9QN88C6/I5
--Device: GW1N-9
--Device Version: C
--Created Time: Sun Nov 24 14:24:53 2024

library IEEE;
use IEEE.std_logic_1164.all;

entity Gowin_OSC is
    port (
        oscout: out std_logic
    );
end Gowin_OSC;

architecture Behavioral of Gowin_OSC is

    --component declaration
    component OSC
        generic (
            FREQ_DIV: in integer := 100;
            DEVICE: in string := "GW1N-4"
        );
        port (
            OSCOUT: out std_logic
        );
    end component;

begin
    osc_inst: OSC
        generic map (
            FREQ_DIV => 2,
            DEVICE => "GW1N-9C"
        )
        port map (
            OSCOUT => oscout
        );

end Behavioral; --Gowin_OSC
