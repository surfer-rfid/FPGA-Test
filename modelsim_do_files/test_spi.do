##################################################################################
##                                                                              ##
## Bench : Test SPI controller and peripheral modules                           ##
##                                                                              ##
## Filename: test_spi.do                                                        ##
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
## Test the SPI in loopback fashion. Do this in a quasi-BFM fashion using tasks ##
## for various operations.                                                      ##
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

vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/spi.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/spi_cntrlr.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/spi_prphrl.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/spi_prphrl_readout_ram.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/irq_merge.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/radio_sram_with_mux.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/radio_sram.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/txcancel_mem.v}
vlog -vlog01compat -work work +incdir+../../../rfidr_source_2021 {../../../rfidr_source_2021/wave_storage_ram.v}


vlog -vlog01compat -work work +incdir+../../../sim_tb/verilog_test_modules {../../../sim_tb/verilog_test_modules/test_spi.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver -L rtl_work -L work -L -voptargs="+acc"  test_spi

add wave -position insertpoint \
sim:/test_spi/cntrlr_cipo \
sim:/test_spi/cntrlr_cipo_sx1257_out \
sim:/test_spi/prphrl_copi_extl \
sim:/test_spi/prphrl_nps_extl \
sim:/test_spi/prphrl_pclk_extl \
sim:/test_spi/prphrl_copi_temp \
sim:/test_spi/prphrl_nps_temp \
sim:/test_spi/prphrl_pclk_temp \
sim:/test_spi/prphrl_copi_27p5 \
sim:/test_spi/prphrl_nps_27p5 \
sim:/test_spi/prphrl_pclk_27p5 \
sim:/test_spi/clk_pclk_nrf51822 \
sim:/test_spi/clk_4p5 \
sim:/test_spi/clk_27p5 \
sim:/test_spi/rst_n_27p5 \
sim:/test_spi/txcancel_data_4p5 \
sim:/test_spi/txcancel_data_aux_4p5 \
sim:/test_spi/txcancel_csel_4p5 \
sim:/test_spi/txcancel_rdy_4p5 \
sim:/test_spi/txcancel_data_temp \
sim:/test_spi/txcancel_data_aux_temp \
sim:/test_spi/txcancel_csel_temp \
sim:/test_spi/txcancel_rdy_temp \
sim:/test_spi/txcancel_data_27p5 \
sim:/test_spi/txcancel_data_aux_27p5 \
sim:/test_spi/txcancel_csel_27p5 \
sim:/test_spi/txcancel_rdy_27p5 \
sim:/test_spi/radio_running \
sim:/test_spi/wave_storage_running \
sim:/test_spi/wave_storage_done \
sim:/test_spi/radio_exit_code \
sim:/test_spi/radio_done \
sim:/test_spi/radio_running \
sim:/test_spi/tx_error \
sim:/test_spi/clk_36_valid \
sim:/test_spi/clk_36_running \
sim:/test_spi/prphrl_cipo \
sim:/test_spi/radio_sram_addr \
sim:/test_spi/radio_sram_wdata \
sim:/test_spi/radio_sram_we_data \
sim:/test_spi/txcancel_sram_addr \
sim:/test_spi/txcancel_sram_wdata \
sim:/test_spi/txcancel_sram_we_data \
sim:/test_spi/wvfm_sram_addr \
sim:/test_spi/cntrlr_nps_rdio \
sim:/test_spi/cntrlr_nps_dtc \
sim:/test_spi/cntrlr_pclk \
sim:/test_spi/cntrlr_copi_cap3 \
sim:/test_spi/cntrlr_copi_cap2 \
sim:/test_spi/cntrlr_copi_cap1 \
sim:/test_spi/cntrlr_copi_cap0_rdio \
sim:/test_spi/irq_spi \
sim:/test_spi/radio_ack \
sim:/test_spi/go_radio \
sim:/test_spi/irq_ack \
sim:/test_spi/radio_mode \
sim:/test_spi/sw_reset \
sim:/test_spi/wvfm_offset \
sim:/test_spi/clk_36_start \
sim:/test_spi/use_i \
sim:/test_spi/mcu_irq_pin \
sim:/test_spi/radio_sram_rdata \
sim:/test_spi/wvfm_sram_rdata \
sim:/test_spi/txcancel_sram_rdata \
sim:/test_spi/radio_sram_address_rx_ideal \
sim:/test_spi/radio_sram_address_tx_ideal \
sim:/test_spi/radio_sram_wdata_ideal \
sim:/test_spi/radio_sram_txrxaccess_ideal \
sim:/test_spi/radio_sram_wren_ideal \
sim:/test_spi/radio_sram_rdata_ideal \
sim:/test_spi/txcancel_mem_ideal_raddr \
sim:/test_spi/txcancel_mem_ideal_rdata \
sim:/test_spi/wave_ram_ideal_wdata \
sim:/test_spi/wave_ram_ideal_waddr \
sim:/test_spi/clk_36 \
sim:/test_spi/wave_ram_ideal_wren \
sim:/test_spi/loop_ram_init \
sim:/test_spi/dut/spi_prphrl0/state \
sim:/test_spi/dut/spi_prphrl0/load_prphrl_tx_buf \
sim:/test_spi/dut/spi_prphrl0/prphrl_tx_buf \
sim:/test_spi/dut/spi_prphrl0/is_wvfm_sram_addr \
sim:/test_spi/dut/spi_prphrl0/is_txcancel_sram_addr \
sim:/test_spi/dut/spi_prphrl0/is_write \
sim:/test_spi/dut/spi_prphrl0/txrx_cntr \
sim:/test_spi/dut/spi_cntrlr0/cntrlr_tx_bit_cntr \
sim:/test_spi/dut/spi_cntrlr0/cntrlr_tx_buf \
sim:/test_spi/dut/spi_cntrlr0/cntrlr_rx_buf \
sim:/test_spi/dut/cntrlr_spi_pending

view structure
view signals
run -all
