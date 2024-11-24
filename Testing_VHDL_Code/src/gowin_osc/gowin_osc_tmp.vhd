--Copyright (C)2014-2024 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--Tool Version: V1.9.10.02
--Part Number: GW1N-LV9QN88C6/I5
--Device: GW1N-9
--Device Version: C
--Created Time: Sun Nov 24 14:24:53 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_OSC
    port (
        oscout: out std_logic
    );
end component;

your_instance_name: Gowin_OSC
    port map (
        oscout => oscout
    );

----------Copy end-------------------
