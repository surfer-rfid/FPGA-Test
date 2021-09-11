##################################################################################
##                                                                              ##
## Bench : Test input I/Q wave storage feature                                  ##
##                                                                              ##
## Filename: test_wave_storage.do                                               ##
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
##    Test the waveform storage module using 1-bit patterns from the top level  ##
##    Octave DSP simulation. Load up the RAM in the waveform storage module,    ##
##    then read it out.                                                         ##
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

vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/wave_storage.v}
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/rfidr_source_2021/wave_storage_ram.v}

vlog -vlog01compat -work work +incdir+../../../FPGA-Test/verilog_test_modules {../../../FPGA-Test/verilog_test_modules/test_wave_storage.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_wave_storage

add wave -position insertpoint  \
sim:/test_wave_storage/in_i \
sim:/test_wave_storage/out_i \
sim:/test_wave_storage/in_q \
sim:/test_wave_storage/out_q \
sim:/test_wave_storage/clk_36 \
sim:/test_wave_storage/rst_n \
sim:/test_wave_storage/go \
sim:/test_wave_storage/clk_spi \
sim:/test_wave_storage/clk_spi_en \
sim:/test_wave_storage/done \
sim:/test_wave_storage/running \
sim:/test_wave_storage/done_ideal \
sim:/test_wave_storage/running_ideal \
sim:/test_wave_storage/data_in_fid \
sim:/test_wave_storage/data_in_fid_2 \
sim:/test_wave_storage/scan_in_rslt \
sim:/test_wave_storage/num_errors_done \
sim:/test_wave_storage/num_errors_running \
sim:/test_wave_storage/num_errors_sram_i \
sim:/test_wave_storage/num_errors_sram_q \
sim:/test_wave_storage/sim_pass_top

add wave -position insertpoint -unsigned \
sim:/test_wave_storage/wait_offset \
sim:/test_wave_storage/sram_address_fromspi \
sim:/test_wave_storage/start_index \
sim:/test_wave_storage/stop_index \
sim:/test_wave_storage/sim_counter \
sim:/test_wave_storage/playback_counter

add wave -position insertpoint -binary \
sim:/test_wave_storage/dut_wave_storage/shift_reg \
sim:/test_wave_storage/sram_data_tospi

add wave -position insertpoint -unsigned \
sim:/test_wave_storage/dut_wave_storage/wrclocken \
sim:/test_wave_storage/dut_wave_storage/wren \
sim:/test_wave_storage/dut_wave_storage/wraddress \
sim:/test_wave_storage/dut_wave_storage/wait_idx \
sim:/test_wave_storage/dut_wave_storage/smpl_idx \
sim:/test_wave_storage/dut_wave_storage/state \
sim:/test_wave_storage/dut_wave_storage/done_next \
sim:/test_wave_storage/dut_wave_storage/load_ctr \
sim:/test_wave_storage/dut_wave_storage/wait_idx_clear \
sim:/test_wave_storage/dut_wave_storage/smpl_idx_clear \
sim:/test_wave_storage/dut_wave_storage/load_ctr_clear

view structure
view signals
run -all
