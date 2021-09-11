##################################################################################
##                                                                              ##
## Bench : Test CDR - test the clock and data recovery system by itself         ##
##                                                                              ##
## Filename: test_cdr.do                                                        ##
## Creation Date: 12/7/2015                                                     ##
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
##    Test the clock and data recovery circuit using a number of stimuli waves  ##
##    obtained from Octave (Big waves, little waves, saturating waves). Check   ##
## contents of the destination SRAM to see if they indeed match Octave results  ##
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

vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/cdr_top_w_sram_test_only.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/cdr_top.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/radio_sram_with_mux.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/radio_sram.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/clk_rcvy.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/data_rcvy.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/crc_ccitt16_rx.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/lpm_add_ci.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/flip_mux_main_lut.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/flip_mux_alt.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/swap_mux.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/thresh_slope_comparisons.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/timer_comparisons.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/signed_saturate.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/cr_phase_det.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/cr_freq_det.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/cr_period_sdm.v}

vlog -vlog01compat -work work +incdir+../../../FPGA-Test/verilog_test_modules {../../../FPGA-Test/verilog_test_modules/test_cdr.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_cdr

add wave -position insertpoint  \
sim:/test_cdr/in_i \
sim:/test_cdr/in_q \
sim:/test_cdr/sample_i_ideal \
sim:/test_cdr/clk_cdr \
sim:/test_cdr/rst_n \
sim:/test_cdr/go \
sim:/test_cdr/clk_spi \
sim:/test_cdr/done \
sim:/test_cdr/bit_decision \
sim:/test_cdr/shift_rn16 \
sim:/test_cdr/shift_handle \
sim:/test_cdr/num_errors_sample \
sim:/test_cdr/num_errors_sram_byte \
sim:/test_cdr/sim_pass_top

add wave -position insertpoint -unsigned \
sim:/test_cdr/sram_byte_ideal \
sim:/test_cdr/radio_state \
sim:/test_cdr/sram_address_fromspi \
sim:/test_cdr/sram_wren_fromspi \
sim:/test_cdr/sram_data_fromspi \
sim:/test_cdr/sram_data_tospi

add wave -position insertpoint -unsigned \
sim:/test_cdr/dut_cdr_sram/sram_address_fromcdr \
sim:/test_cdr/dut_cdr_sram/sram_wren_fromcdr \
sim:/test_cdr/dut_cdr_sram/sram_data_fromcdr \
sim:/test_cdr/dut_cdr_sram/sram_address_fromspi \
sim:/test_cdr/dut_cdr_sram/sram_wren_fromspi \
sim:/test_cdr/dut_cdr_sram/sram_data_fromspi

add wave -position insertpoint  \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/tank_lsb \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/freq_delta \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/phase_delta \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/phase_delta_counter \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/state \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/data_edge_block \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/data_edge_block_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/data_edge \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/data_prev

add wave -position insertpoint -unsigned \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/period \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/counter \
sim:/test_cdr/dut_cdr_sram/dut_cdr/cr_main/counter_next

add wave -position insertpoint  \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_main \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_main_0_abs \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_main_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_main_store \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_main_0 \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_main_0_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_alt \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_alt_0_flipd \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_alt_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_alt_0 \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/integ_alt_0_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/in_main \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/in_alt \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/crc_shift \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/crc16/shift_reg_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/crc16/crc_out_next

add wave -position insertpoint -unsigned \
sim:/test_cdr/dut_cdr_sram/dut_cdr/sample \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/flip \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sqwv \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/crc_ok \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/state_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/done_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_address_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_wren_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_todata_out_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_address \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_wren \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_todata_out \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/wd_timer_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/locked_timer_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/prev_slope_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/prev_slope_next_val \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/over_idle_thresh \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/over_locked_thresh \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/peak_detect_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/prev_slope \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/peak_detect \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/align_val \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/burn \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/clr_n_crc \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/glue \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/exit_code \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/exit_code_next \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/peak_space_vec \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sclr_integs_mainalt_0 \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sclr_integs_mainalt \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/clkena_integs_mainalt \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sclr_integs_store \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/clkena_integs_store \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/wd_timer_clr \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/locked_timer_clr \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_address_load \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_address_loadval \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/state_curr \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/wd_timer \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/locked_timer \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/bit_counter_dn \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/bit_counter_dn_load \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sram_fromdata_in \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/bit_counter_dn_dec9 \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/bit_counter_dn_dec1 \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/bit_counter_up \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/bit_8_counter \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/space_counter \
sim:/test_cdr/dut_cdr_sram/dut_cdr/dr/sym_counter

view structure
view signals
run -all
