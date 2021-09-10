##################################################################################
##                                                                              ##
## Bench : Test TX Cancel - Test the TX cancellation by itself                  ##
##                                                                              ##
## Filename: test_tx_cancel.do                                                  ##
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
## This file takes input/output vectors from the 'top level' Octave simulation  ##
## so that we can just test the TX cancellation. We model the action of the     ##
## SPI controller engine with code.                                             ##
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

vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/tx_cancel.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/txcancel_mem.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/dtc_state_saturate.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/lpm_mult_dual.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/signed_saturate.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/lpm_add_ci.v}

vlog -vlog01compat -work work +incdir+../../../sim_tb/verilog_test_modules {../../../sim_tb/verilog_test_modules/test_tx_cancel.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_tx_cancel

add wave *
add wave -position insertpoint  \
sim:/test_tx_cancel/dut/mult_i_out \
sim:/test_tx_cancel/dut/mult_q_out \
sim:/test_tx_cancel/dut/mult_i_small_out \
sim:/test_tx_cancel/dut/mult_q_small_out \
sim:/test_tx_cancel/dut/abs_i_greater \
sim:/test_tx_cancel/dut/common_adder_out \
sim:/test_tx_cancel/dut/curr_error \
sim:/test_tx_cancel/dut/prev_error \
sim:/test_tx_cancel/dut/prev_error_flip \
sim:/test_tx_cancel/dut/prev_error_flipped \
sim:/test_tx_cancel/dut/step_vec1 \
sim:/test_tx_cancel/dut/step_vec1_next \
sim:/test_tx_cancel/dut/step_vec2 \
sim:/test_tx_cancel/dut/step_vec2_next \
sim:/test_tx_cancel/dut/state_cap1 \
sim:/test_tx_cancel/dut/state_cap2 \
sim:/test_tx_cancel/dut/state_cap1_next \
sim:/test_tx_cancel/dut/state_cap1_next_sat \
sim:/test_tx_cancel/dut/state_cap2_next \
sim:/test_tx_cancel/dut/state_cap2_next_sat \
sim:/test_tx_cancel/dut/loop_mode \
sim:/test_tx_cancel/dut/load_prev_error \
sim:/test_tx_cancel/dut/load_step_vec1 \
sim:/test_tx_cancel/dut/load_step_vec2 \
sim:/test_tx_cancel/dut/latch_step_vec1 \
sim:/test_tx_cancel/dut/latch_step_vec2

view structure
view signals
run -all
