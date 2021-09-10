/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Query Rep Command                                                    //
//                                                                                     //
// Filename: load_rfidr_top_sram_query_rep.v                                           //
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
//    Load a QUERY REP command into the TX section of the radio SRAM                   //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_query_rep;

    `include "../../../sim_tb/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_localparam_defs.v"

    reg    [4:0]    query_rep_vector;
    
    reg    [8:0]    radio_sram_addr_27p5;
    reg    [7:0]    radio_sram_wdata_27p5;
    
    begin
        query_rep_vector            =    4'b00_00;

        radio_sram_addr_27p5        =    TX_RAM_ADDR_OFFSET_QRY_REP  << 4;
        radio_sram_wdata_27p5       =    {DUMMY_ZERO,BEGIN_REGULAR};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {query_rep_vector[3] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {query_rep_vector[1] ? SINGLE_ONE : SINGLE_ZERO,query_rep_vector[2] ? SINGLE_ONE : SINGLE_ZERO};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {END_PACKET,query_rep_vector[0] ? SINGLE_ONE : SINGLE_ZERO};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

    end
endtask