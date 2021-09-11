##################################################################################
##                                                                              ##
## Bench : Test RFIDr FPGA top level Postfit                                    ##
##                                                                              ##
## Filename: test_rfidr_top_postfit.do                                          ##
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
##  Test the top level RFIDr with BFMs of an ideal waveform storage, NRF51822   ##
##  (MCU), and RFID tag/SX1257. This file focuses on overall connectivity, not  ##
##  feature support, so we won't test things like clocks stopping and starting. ##
##                                                                              ##
##    Revisions:                                                                ##
##    090621 - Replaced tabs with 4-spaces. Added copyright to header.          ##
##    Changed file relative pathways and file names to most current version.    ##
##    This file is out of date and was not re-run after cleanup for release, so ##
##    please temper expectations for use accordingly.                           ##
##                                                                              ##
##################################################################################

transcript on

#Run the .tcl files required by Mentor in order to include complex primitives like the internal oscillator and clock buffer
#source ../../../FPGA/rfidr_source_2021/internal_osc/simulation/mentor/msim_setup.tcl
#source ../../../FPGA/rfidr_source_2021/clk_gate_buf/simulation/mentor/msim_setup.tcl

if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work



#Include all of the design files
vlog -vlog01compat -work work +incdir+../../../FPGA/rfidr_source_2021 {../../../FPGA/quartus_project/simulation/modelsim/rfidr_top.vo}


#Include all of the BFMs instantiated as modules

vlog -vlog01compat -work work +incdir+../../../FPGA-Test/test_rfidr_top_subtasks {../../../FPGA-Test/test_rfidr_top_subtasks/sx1257_rx_and_tag_bfm.v}
vlog -vlog01compat -work work +incdir+../../../FPGA-Test/test_rfidr_top_subtasks {../../../FPGA-Test/test_rfidr_top_subtasks/sx1257_rx_and_tag_dtc_spi_bfm.v}
vlog -vlog01compat -work work +incdir+../../../FPGA-Test/test_rfidr_top_subtasks {../../../FPGA-Test/test_rfidr_top_subtasks/sx1257_tx_filters_bfm_rfidr_top.v}
vlog -vlog01compat -work work +incdir+../../../FPGA-Test/test_rfidr_top_subtasks {../../../FPGA-Test/test_rfidr_top_subtasks/sx1257_rx_and_tag_sdm_bfm.v}
vlog -vlog01compat -work work +incdir+../../../FPGA-Test/test_rfidr_top_subtasks {../../../FPGA-Test/test_rfidr_top_subtasks/sx1257_rx_and_tag_sx1257_spi_bfm.v}
vlog -vlog01compat -work work +incdir+../../../FPGA-Test/test_rfidr_top_subtasks {../../../FPGA-Test/test_rfidr_top_subtasks/sx1257_rx_and_tag_tx_refl_coeff.v}

#Reference the testbench and run

vlog -vlog01compat -work work +incdir+../../../FPGA-Test/verilog_test_modules {../../../FPGA-Test/verilog_test_modules/test_rfidr_top_postfit.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_rfidr_top_postfit

#Display top level signals

add wave -position insertpoint  \
sim:/test_rfidr_top_postfit/clk_36_extl \
sim:/test_rfidr_top_postfit/rst_n_extl \
sim:/test_rfidr_top_postfit/in_i_extl \
sim:/test_rfidr_top_postfit/in_q_extl \
sim:/test_rfidr_top_postfit/out_i_extl \
sim:/test_rfidr_top_postfit/out_q_extl \
sim:/test_rfidr_top_postfit/mcu_irq_extl \
sim:/test_rfidr_top_postfit/prphrl_pclk_extl \
sim:/test_rfidr_top_postfit/prphrl_cipo_extl \
sim:/test_rfidr_top_postfit/prphrl_copi_extl \
sim:/test_rfidr_top_postfit/prphrl_nps_extl \
sim:/test_rfidr_top_postfit/cntrlr_pclk_extl \
sim:/test_rfidr_top_postfit/cntrlr_copi_cap3_extl \
sim:/test_rfidr_top_postfit/cntrlr_copi_cap2_extl \
sim:/test_rfidr_top_postfit/cntrlr_copi_cap1_extl \
sim:/test_rfidr_top_postfit/cntrlr_copi_cap0_rdio_extl \
sim:/test_rfidr_top_postfit/cntrlr_cipo_extl \
sim:/test_rfidr_top_postfit/cntrlr_nps_rdio_extl \
sim:/test_rfidr_top_postfit/cntrlr_nps_dtc_extl \
sim:/test_rfidr_top_postfit/tx_go \
sim:/test_rfidr_top_postfit/radio_state

#Display signals under the first layer of hierarchy

#add wave -position insertpoint  \
#sim:/test_rfidr_top_postfit/rfidr_top0/rst_4p5_sw \
#sim:/test_rfidr_top_postfit/rfidr_top0/rst_n_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/rst_n_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/clk_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/clk_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/clk_36_start \
#sim:/test_rfidr_top_postfit/rfidr_top0/clk_36 \
#sim:/test_rfidr_top_postfit/rfidr_top0/clk_36_valid \
#sim:/test_rfidr_top_postfit/rfidr_top0/clk_36_running \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_busy_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_done_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_rdy_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_busy_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_done_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_rdy_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/wave_storage_done_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/wave_storage_running_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/wave_storage_done_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/wave_storage_running_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_go_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_ack_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_go_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_ack_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/prphrl_copi_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/prphrl_nps_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/prphrl_pclk_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_done \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_running \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_we_data_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_sram_we_data_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_wren \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_txrxaccess \
#sim:/test_rfidr_top_postfit/rfidr_top0/wvfm_go \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_go \
#sim:/test_rfidr_top_postfit/rfidr_top0/irq_ack \
#sim:/test_rfidr_top_postfit/rfidr_top0/rx_done \
#sim:/test_rfidr_top_postfit/rfidr_top0/tx_done \
#sim:/test_rfidr_top_postfit/rfidr_top0/last_tx_write \
#sim:/test_rfidr_top_postfit/rfidr_top0/rx_block \
#sim:/test_rfidr_top_postfit/rfidr_top0/rx_go \
#sim:/test_rfidr_top_postfit/rfidr_top0/tx_go \
#sim:/test_rfidr_top_postfit/rfidr_top0/rx_gain \
#sim:/test_rfidr_top_postfit/rfidr_top0/tx_gain \
#sim:/test_rfidr_top_postfit/rfidr_top0/tx_en \
#sim:/test_rfidr_top_postfit/rfidr_top0/tx_error_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/dc_ready_i \
#sim:/test_rfidr_top_postfit/rfidr_top0/dc_ready_q \
#sim:/test_rfidr_top_postfit/rfidr_top0/in_posedge_i \
#sim:/test_rfidr_top_postfit/rfidr_top0/in_posedge_q \
#sim:/test_rfidr_top_postfit/rfidr_top0/out_i_baseband_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/rst_n_36_in \
#sim:/test_rfidr_top_postfit/rfidr_top0/use_i_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/use_i_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/bit_decision_from_dr \
#sim:/test_rfidr_top_postfit/rfidr_top0/shift_rn16_from_dr \
#sim:/test_rfidr_top_postfit/rfidr_top0/shift_rn16_to_txgen \
#sim:/test_rfidr_top_postfit/rfidr_top0/shift_handle_from_dr \
#sim:/test_rfidr_top_postfit/rfidr_top0/shift_handle_to_txgen \
#sim:/test_rfidr_top_postfit/rfidr_top0/rn16_to_txgen \
#sim:/test_rfidr_top_postfit/rfidr_top0/handle_to_txgen \
#sim:/test_rfidr_top_postfit/rfidr_top0/irq_fsm \
#sim:/test_rfidr_top_postfit/rfidr_top0/irq_clock \
#sim:/test_rfidr_top_postfit/rfidr_top0/irq_spi

#Display multibit signals under the first layer of hierarchy
	
#add wave -position insertpoint -unsigned \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_exit_code_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_csel_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_exit_code_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_csel_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_mode_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_mode_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_num_tags_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_data_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_data_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_data_aux_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_data_aux_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_addr_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_sram_addr_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_address_tx \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_address_rx \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_wdata_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_sram_wdata_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_rdata_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/txcancel_sram_rdata_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_rdata_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_sram_wdata_4p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/wvfm_sram_addr \
#sim:/test_rfidr_top_postfit/rfidr_top0/wvfm_sram_rdata_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/wvfm_offset_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/tx_error_27p5 \
#sim:/test_rfidr_top_postfit/rfidr_top0/radio_state

#add wave -position insertpoint -decimal \
#sim:/test_rfidr_top_postfit/rfidr_top0/dc_i \
#sim:/test_rfidr_top_postfit/rfidr_top0/dc_q \
#sim:/test_rfidr_top_postfit/rfidr_top0/chfilt_i \
#sim:/test_rfidr_top_postfit/rfidr_top0/chfilt_q

add wave -position insertpoint \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/u_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/u_q \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/rx_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/rx_q \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/tx_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/tx_q \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/tx_net_refl_coeff_r \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/tx_net_refl_coeff_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/rx_gain

add wave -position insertpoint \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/u_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/u_q \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/v_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/v_q \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/y_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/y_q \

add wave -position insertpoint -unsigned \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/dtc_value_0 \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/dtc_value_1 \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/dtc_value_2 \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/dtc_value_3

#add wave -position insertpoint \
#sim:/test_rfidr_top_postfit/rfidr_top0/rn16_and_handle_shift_regs0/reg_rn16 \
#sim:/test_rfidr_top_postfit/rfidr_top0/rn16_and_handle_shift_regs0/reg_handle \
#sim:/test_rfidr_top_postfit/rfidr_top0/rn16_and_handle_shift_regs0/out_rn16 \
#sim:/test_rfidr_top_postfit/rfidr_top0/rn16_and_handle_shift_regs0/out_handle

add wave -position insertpoint \
sim:/test_rfidr_top_postfit/rfidr_top0/tx_gen0_aout_aq \
sim:/test_rfidr_top_postfit/out_i_extl \

add wave -position insertpoint -format analog-interpolated -height 100 -max 1 -min -1\
sim:/test_rfidr_top_postfit/tx_iir_i_out \
sim:/test_rfidr_top_postfit/tx_iir_q_out

add wave -position insertpoint \
sim:/test_rfidr_top_postfit/out_q_extl

add wave -position insertpoint -format analog-interpolated -height 100 -max 0.3 -min -0.3\
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/u_i \
sim:/test_rfidr_top_postfit/sx1257_rx_and_tag_bfm_0/sx1257_rx_and_tag_sdm_bfm_0/u_q

view structure
view signals
run -all
