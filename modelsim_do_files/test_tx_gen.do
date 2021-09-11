##################################################################################
##                                                                              ##
## Bench : Test TX Gen and Radio FSM                                            ##
##                                                                              ##
## Filename: test_tx_gen.do                                                     ##
## Creation Date: circa 9/2016                                                  ##
## Author: Edward Keehr                                                         ##
##                                                                              ##
## Copyright Superlative Semiconductor LLC 2021                                 ##
## This source describes Open Hardware and is licensed under the CERN-OHL-P v2  ##
## You may redistribute and modify this documentation and make products         ##
## using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).     ##
## This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED             ##
## WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                 ##
## AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2           ##
## for applicable conditions.                                                   ##
##                                                                              ##
## Description:                                                                 ##
##    Test the TX generation circuit along with the real TX RAM and Radio FSM   ##
##    and RN16/Handle transfer registers. Use tasks to create BFMs for the RAM  ##
##    loading, data recovery, ideal playback, and comparison functions.         ##
##    Also we will test the top level FSM!!!!                                   ##
##                                                                              ##
##    Revisions:                                                                ##
##    090621 - Replaced tabs with 4-spaces. Added copyright to header.          ##
##    Changed file relative pathways and file names to most current version.    ##
##    This file is out of date and was not re-run after cleanup for release, so ##
##    please temper expectations for use accordingly.                           ##
##                                                                              ##
##################################################################################

transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/tx_gen.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/rn16_and_handle_shift_regs.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/radio_sram_with_mux.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/radio_fsm.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/rfidr_fsm.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/radio_sram.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/crc_ccitt16_tx.v}


vlog -vlog01compat -work work +incdir+../../../FPGA-Test/verilog_test_modules {../../../FPGA-Test/verilog_test_modules/test_tx_gen.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_tx_gen

add wave -position insertpoint \
sim:/test_tx_gen/radio_sram_rdata_4p5 \
sim:/test_tx_gen/rn16_to_txgen \
sim:/test_tx_gen/handle_to_txgen \
sim:/test_tx_gen/radio_state \
sim:/test_tx_gen/tx_go \
sim:/test_tx_gen/tx_en \
sim:/test_tx_gen/clk_4p5 \
sim:/test_tx_gen/rst_n_4p5 \
sim:/test_tx_gen/bit_decision_from_dr \
sim:/test_tx_gen/shift_rn16_from_dr \
sim:/test_tx_gen/shift_handle_from_dr \
sim:/test_tx_gen/radio_sram_address_rx \
sim:/test_tx_gen/radio_sram_addr_27p5 \
sim:/test_tx_gen/clk_ram \
sim:/test_tx_gen/radio_sram_wdata_4p5 \
sim:/test_tx_gen/radio_sram_wdata_27p5 \
sim:/test_tx_gen/radio_sram_txrxaccess \
sim:/test_tx_gen/radio_sram_wren \
sim:/test_tx_gen/radio_sram_we_data_27p5 \
sim:/test_tx_gen/radio_go_4p5 \
sim:/test_tx_gen/radio_mode_4p5 \
sim:/test_tx_gen/radio_mode_temp \
sim:/test_tx_gen/radio_mode_27p5 \
sim:/test_tx_gen/rx_done \
sim:/test_tx_gen/radio_go \
sim:/test_tx_gen/radio_done_27p5 \
sim:/test_tx_gen/irq_ack \
sim:/test_tx_gen/rst_n_27p5 \
sim:/test_tx_gen/clk_27p5 \
sim:/test_tx_gen/shift_rn16_to_txgen \
sim:/test_tx_gen/shift_handle_to_txgen \
sim:/test_tx_gen/radio_sram_address_tx \
sim:/test_tx_gen/out_i_baseband_4p5 \
sim:/test_tx_gen/tx_done \
sim:/test_tx_gen/last_tx_write \
sim:/test_tx_gen/tx_error_4p5 \
sim:/test_tx_gen/rx_block \
sim:/test_tx_gen/rx_go \
sim:/test_tx_gen/rx_gain \
sim:/test_tx_gen/tx_go \
sim:/test_tx_gen/tx_en \
sim:/test_tx_gen/tx_gain \
sim:/test_tx_gen/wvfm_go \
sim:/test_tx_gen/radio_busy_4p5 \
sim:/test_tx_gen/radio_busy_27p5 \
sim:/test_tx_gen/radio_exit_code_4p5 \
sim:/test_tx_gen/radio_done_4p5 \
sim:/test_tx_gen/radio_go_27p5 \
sim:/test_tx_gen/radio_running \
sim:/test_tx_gen/radio_done \
sim:/test_tx_gen/mcu_irq_pin \
sim:/test_tx_gen/tx_gen0/state \
sim:/test_tx_gen/tx_gen0/sram_flag \
sim:/test_tx_gen/tx_gen0/sram_in_data \
sim:/test_tx_gen/tx_gen0/sram_address \
sim:/test_tx_gen/tx_gen0/sram_address_reg \
sim:/test_tx_gen/tx_gen0/hi_cntr \
sim:/test_tx_gen/tx_gen0/lo_cntr \
sim:/test_tx_gen/tx_gen0/hi \
sim:/test_tx_gen/tx_gen0/crc_out_bit \
sim:/test_tx_gen/tx_gen0/calc_crc \
sim:/test_tx_gen/tx_gen0/shift_crc_bits \
sim:/test_tx_gen/tx_gen0/crc_tx/crc_reg \
sim:/test_tx_gen/tx_gen0/crc_tx/crc_reg_next \
sim:/test_tx_gen/tx_gen0/crc_tx/new_crc \
sim:/test_tx_gen/rn16_and_handle_shift_regs0/reg_rn16 \
sim:/test_tx_gen/rn16_and_handle_shift_regs0/reg_handle \
sim:/test_tx_gen/bit_decision_from_dr \
sim:/test_tx_gen/shift_rn16_from_dr \
sim:/test_tx_gen/shift_handle_from_dr

view structure
view signals
run -all
