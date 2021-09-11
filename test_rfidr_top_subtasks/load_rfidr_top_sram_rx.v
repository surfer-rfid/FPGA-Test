/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load RX Section of Radio SRAM                                             //
//                                                                                     //
// Filename: load_rfidr_top_sram_rx.v                                                  //
// Creation Date: Circa 9/2016                                                         //
// Author: Edward Keehr                                                                //
//                                                                                     //
// Copyright Superlative Semiconductor LLC 2021                                        //
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2         //
// You may redistribute and modify this documentation and make products                //
// using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).            //
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED                    //
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                        //
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2                  //
// for applicable conditions.                                                          //
//                                                                                     //
//  Description:                                                                       //
//    Load the RX section of the radio SRAM. This data tells the data recovery circuit //
//    how long the expected packet is for a given operation.                           //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_rx;

    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_rx_localparam_defs.v"
    
    reg    [8:0]    radio_sram_addr_27p5;
    reg    [7:0]    radio_sram_wdata_27p5;
    
    begin
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_RN16  << 4;
        radio_sram_wdata_27p5       =    8'd32;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_RN16_I  << 4;
        radio_sram_wdata_27p5       =    8'd16;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_PCEPC  << 4;
        radio_sram_wdata_27p5       =    8'd128;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_HANDLE  << 4;
        radio_sram_wdata_27p5       =    8'd32;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_WRITE  << 4;
        radio_sram_wdata_27p5       =    8'd17;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_READ  << 4;
        radio_sram_wdata_27p5       =    8'd129;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    RX_RAM_ADDR_OFFSET_LOCK  << 4;
        radio_sram_wdata_27p5       =    8'd17;
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
    end
endtask