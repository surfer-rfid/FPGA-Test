/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Query Command                                                        //
//                                                                                     //
// Filename: load_rfidr_top_sram_query.v                                               //
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
//    Load a QUERY command into the TX section of the radio SRAM                       //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_query;
    
    input    [21:0]    query_bits;
    
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_localparam_defs.v"
    
    reg      [21:0]    query_vector;
    
    integer  loop_sram;
    
    reg      [8:0]    radio_sram_addr_27p5;
    reg      [7:0]    radio_sram_wdata_27p5;
    
    begin
        //query_vector              =    22'b1000_1_11_1_00_00_0_0111_01010;        //Command_DR_M_TRext_Sel_Session_Tgt_Q_CRC5 (CRC5 here is fake!!!!!)
        //Actually we will bring in query vector from a higher level so the higher level can enforce the same vector being used in both the 
        //SRAM loading and in the checker.
        query_vector                =    query_bits;
        
        radio_sram_addr_27p5        =    TX_RAM_ADDR_OFFSET_QUERY  << 4;
        radio_sram_wdata_27p5       =    {DUMMY_ZERO,BEGIN_REGULAR};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;            //Would C trick of {addr_offset,addr_incr=addr_incr+1} work here?
        radio_sram_wdata_27p5       =    {TRCAL,RTCAL};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
                
        for(loop_sram=0;loop_sram<11;loop_sram=loop_sram+1)    begin
            radio_sram_addr_27p5    =    radio_sram_addr_27p5+9'd1;
            radio_sram_wdata_27p5   =    {query_vector[20-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,query_vector[20-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        end
                
        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {TXCW0,END_PACKET};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
                
    end
endtask