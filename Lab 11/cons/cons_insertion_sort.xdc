## Clock signal: 100 MHz clock on Nexys A7
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }]


## Reset switch
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { reset }]


## Seven-segment cathodes
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { segA }]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { segB }]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { segC }]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { segD }]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { segE }]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { segF }]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { segG }]


## Seven-segment anodes
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { an0 }]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { an1 }]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { an2 }]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { an3 }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { an4 }]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { an5 }]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { an6 }]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { an7 }]