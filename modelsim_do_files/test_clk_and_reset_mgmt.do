##################################################################################
##                                                                              ##
## Bench : Test Clock and Reset Management                                      ##
##                                                                              ##
## Filename: test_clk_and_reset_mgmt.do                                         ##
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
##    This block contains the testbench for the clock and reset mgmt module.    ##
##    The clock and reset management modules are surrounded by a wrapper to     ##
##    ensure that their mutual verification is valid at the top level of the    ##
##    design.                                                                   ##
##                                                                              ##
##    Revisions:                                                                ##
##    090621 - Replaced tabs with 4-spaces. Added copyright to header.          ##
##    Changed file relative pathways and file names to most current version.    ##
##    This file is out of date and was not re-run after cleanup for release, so ##
##    please temper expectations for use accordingly.                           ##
##                                                                              ##
##################################################################################

transcript on

source ../../../rfidr_source_2021/internal_osc/simulation/mentor/msim_setup.tcl
source ../../../rfidr_source_2021/clk_gate_buf/simulation/mentor/msim_setup.tcl

if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/clk_and_reset_mgmt.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/clk_mgmt.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/reset_mgmt.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/clk_mgmt_div_by_8.v}

vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021/clk_gate_buf/simulation {../../../rfidr_source_2021/clk_gate_buf/simulation/clk_gate_buf.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021/clk_gate_buf/simulation/submodules {../../../rfidr_source_2021/clk_gate_buf/simulation/submodules/clk_gate_buf_altclkctrl_0.v}

vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021/internal_osc/simulation {../../../rfidr_source_2021/internal_osc/simulation/internal_osc.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021/internal_osc/simulation/submodules {../../../rfidr_source_2021/internal_osc/simulation/submodules/altera_int_osc.v}

vlog -vlog01compat -work work +incdir+../../../sim_tb/verilog_test_modules {../../../sim_tb/verilog_test_modules/test_clk_and_reset_mgmt.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_clk_and_reset_mgmt

add wave -position insertpoint \
sim:/test_clk_and_reset_mgmt/clk_36_in \
sim:/test_clk_and_reset_mgmt/clk_36_start \
sim:/test_clk_and_reset_mgmt/rst_n_ext \
sim:/test_clk_and_reset_mgmt/rst_4p5_sw \
sim:/test_clk_and_reset_mgmt/clk_36 \
sim:/test_clk_and_reset_mgmt/clk_4p5 \
sim:/test_clk_and_reset_mgmt/clk_27p5 \
sim:/test_clk_and_reset_mgmt/rst_n_36_in \
sim:/test_clk_and_reset_mgmt/rst_n_4p5 \
sim:/test_clk_and_reset_mgmt/rst_n_27p5 \
sim:/test_clk_and_reset_mgmt/dut/rst_n_55 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_valid \
sim:/test_clk_and_reset_mgmt/clk_36_valid_reg \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_running \
sim:/test_clk_and_reset_mgmt/clk_36_running_reg \
sim:/test_clk_and_reset_mgmt/clk_36_irq \
sim:/test_clk_and_reset_mgmt/loop_i \
sim:/test_clk_and_reset_mgmt/loop_j \
sim:/test_clk_and_reset_mgmt/edge_prev_4p5 \
sim:/test_clk_and_reset_mgmt/edge_dlta_4p5 \
sim:/test_clk_and_reset_mgmt/edge_prev_36 \
sim:/test_clk_and_reset_mgmt/edge_dlta_36 \
sim:/test_clk_and_reset_mgmt/dut/clk_4p5_unbuf \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_55 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_27p5_unbuf \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/state \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_resync_to_55_1 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_resync_to_55_2 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_running_resync_to_clk36_1 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_running_resync_to_clk36_2 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_running_resync_to_clk36_3 \
sim:/test_clk_and_reset_mgmt/dut/clk_mgmt0/clk_36_running_resync_to_clk4p5_3 \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_n_4p5_int \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_4p5_reg0 \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_4p5_reg1 \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_27p5_reg0 \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_27p5_reg1 \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_36_in_reg0 \
sim:/test_clk_and_reset_mgmt/dut/reset_mgmt0/rst_36_in_reg1

view structure
view signals
run -all
