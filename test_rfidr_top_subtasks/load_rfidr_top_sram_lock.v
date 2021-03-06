/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load LOCK Command                                                         //
//                                                                                     //
// Filename: load_rfidr_top_sram_lock.v                                                //
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
//    Load a  LOCK command into the TX section of the radio SRAM                       //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_lock;
    
    input    [27:0]    lock_bits;
    
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_localparam_defs.v"
    
    reg      [7:0]     lock_vector_begin;
    reg      [19:0]    lock_vector_end;
    reg      [27:0]    lock_vector;

    integer            loop_sram;
    
    reg      [8:0]     radio_sram_addr_27p5;
    reg      [7:0]     radio_sram_wdata_27p5;
    
    begin
        //lock_vector_begin          =    8'b11000101;
        //lock_vector_end            =    {$random(seed_intl)} % (2^20);    //20-bit random data //DUH, where is the input for the seed?!?!
        //lock_vector                =    {lock_vector_begin,lock_vector_end};
        lock_vector                  =    lock_bits;
        
        radio_sram_addr_27p5         =    TX_RAM_ADDR_OFFSET_LOCK  << 4;
        radio_sram_wdata_27p5        =    {DUMMY_ZERO,BEGIN_REGULAR};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);

        radio_sram_addr_27p5         =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5        =    {lock_vector[27] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        for(loop_sram=0;loop_sram<13;loop_sram=loop_sram+1)    begin   //We should find a way to determine the loop length based on the specified bit string
            radio_sram_addr_27p5     =    radio_sram_addr_27p5+9'd1;
            radio_sram_wdata_27p5    =    {lock_vector[25-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,lock_vector[25-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        end
        radio_sram_addr_27p5         =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5        =    {INSERT_HANDLE,lock_vector[0] ? SINGLE_ONE : SINGLE_ZERO};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5         =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5        =    {END_PACKET,INSERT_CRC16};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
    end
endtask