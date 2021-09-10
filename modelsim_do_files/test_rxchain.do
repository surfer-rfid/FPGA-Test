##################################################################################
##                                                                              ##
## Bench : Test RX Chain: decimation filter and channel filter                  ##
##                                                                              ##
## Filename: test_rxchain.do                                                    ##
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
##  Test the dec. and chnl. filter with the I/O waveforms obtained from MATLAB  ##
##  Check for bit-exactness.                                                    ##
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

vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/rxchain.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/cic_8.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/dec_128.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/chnl_filt.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/chnl_filt_dfii.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/chnl_filt_dfii_onemult.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/signed_saturate.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/lpm_mult_const.v}

vlog -vlog01compat -work work +incdir+../../../sim_tb/verilog_test_modules {../../../sim_tb/verilog_test_modules/test_rxchain.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_rxchain

add wave *
add wave -position insertpoint  \
sim:/test_rxchain/rxchain_freq1/cic8_out

view structure
view signals
run -all
