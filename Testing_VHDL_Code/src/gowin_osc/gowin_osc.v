//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.10.02
//Part Number: GW1N-LV9QN88C6/I5
//Device: GW1N-9
//Device Version: C
//Created Time: Sun Nov 24 12:10:10 2024

module Gowin_OSC (oscout);

output oscout;

OSC osc_inst (
    .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 10;
defparam osc_inst.DEVICE = "GW1N-9C";

endmodule //Gowin_OSC
