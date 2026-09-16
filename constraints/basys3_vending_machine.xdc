## ============================================================================
## File: basys3_vending_machine.xdc
## Description: Xilinx Design Constraints (XDC) for Digilent Basys 3 Board
## Target Part: xc7a35tcpg236-1
## Target Standard: LVCMOS33
## ============================================================================

## Device Configuration Properties
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock signal (100 MHz Oscillator)
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

## Switches
set_property PACKAGE_PIN V17 [get_ports {sw_prod_sel[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_prod_sel[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw_prod_sel[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_prod_sel[1]}]

set_property PACKAGE_PIN W16 [get_ports {sw_coin_denom[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_coin_denom[0]}]
set_property PACKAGE_PIN W17 [get_ports {sw_coin_denom[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_coin_denom[1]}]
set_property PACKAGE_PIN W15 [get_ports {sw_coin_denom[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_coin_denom[2]}]

set_property PACKAGE_PIN V15 [get_ports btn_online_ack]
set_property IOSTANDARD LVCMOS33 [get_ports btn_online_ack]

set_property PACKAGE_PIN W14 [get_ports {sw_online_status[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_online_status[0]}]
set_property PACKAGE_PIN W13 [get_ports {sw_online_status[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw_online_status[1]}]

## Admin Switches (SW15, SW14, SW13)
set_property PACKAGE_PIN R2 [get_ports sw_admin_en]
set_property IOSTANDARD LVCMOS33 [get_ports sw_admin_en]
set_property PACKAGE_PIN T1 [get_ports sw_admin_next]
set_property IOSTANDARD LVCMOS33 [get_ports sw_admin_next]
set_property PACKAGE_PIN U1 [get_ports sw_admin_restock]
set_property IOSTANDARD LVCMOS33 [get_ports sw_admin_restock]

## Pushbuttons
set_property PACKAGE_PIN U18 [get_ports btn_rst]
set_property IOSTANDARD LVCMOS33 [get_ports btn_rst]
set_property PACKAGE_PIN U17 [get_ports btn_select]
set_property IOSTANDARD LVCMOS33 [get_ports btn_select]
set_property PACKAGE_PIN T18 [get_ports btn_coin]
set_property IOSTANDARD LVCMOS33 [get_ports btn_coin]
set_property PACKAGE_PIN W19 [get_ports btn_cancel]
set_property IOSTANDARD LVCMOS33 [get_ports btn_cancel]
set_property PACKAGE_PIN T17 [get_ports btn_online_trigger]
set_property IOSTANDARD LVCMOS33 [get_ports btn_online_trigger]

## LEDs
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]

## 7-Segment Display Cathodes
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

set_property PACKAGE_PIN V7 [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]

## 7-Segment Display Anodes
set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
