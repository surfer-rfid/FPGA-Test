/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load NAK Command                                                          //
//                                                                                     //
// Filename: load_rfidr_top_sram_nak.v                                                 //
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
//    Load a NAK command into the TX section of the radio SRAM                         //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_nak;

    `include "../../../sim_tb/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_localparam_defs.v"
    
    reg    [8:0]    radio_sram_addr_27p5;
    reg    [7:0]    radio_sram_wdata_27p5;
    
    begin
        radio_sram_addr_27p5        =    TX_RAM_ADDR_OFFSET_NAK  << 4;
        radio_sram_wdata_27p5       =    {DUMMY_ZERO,BEGIN_REGULAR};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {SINGLE_ONE,RTCAL};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {SINGLE_ZERO,SINGLE_ONE};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {SINGLE_ZERO,SINGLE_ZERO};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {SINGLE_ZERO,SINGLE_ZERO};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        //radio_sram_addr_27p5      =    radio_sram_addr_27p5+9'd1;
        //radio_sram_wdata_27p5     =    {END_PACKET,SINGLE_ZERO};
        //wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {NAK_END,SINGLE_ZERO};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {TXCW0,END_PACKET};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {TXCW0,TXCW0};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
    end
endtask