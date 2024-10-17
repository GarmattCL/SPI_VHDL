//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.02 
//Created Time: 2024-10-03 17:17:14
create_clock -name SPI_Master_Clk -period 10000 -waveform {0 5000} [get_ports {clk}]
