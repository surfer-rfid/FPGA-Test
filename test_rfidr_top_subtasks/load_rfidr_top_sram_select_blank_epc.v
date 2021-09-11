/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Select Command                                                       //
//                                                                                     //
// Filename: load_rfidr_top_sram_select_blank_epc.v                                    //
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
//    Load a SELECT command with a blank EPC into the TX section of the radio SRAM     //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_select_blank_epc;

    input    [27:0]    select_blank_bits;

    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_localparam_defs.v"
    
    integer    loop_sram;
    
    reg    [27:0]    select_vector_begin;
    reg    [15:0]    select_vector_middle0;
    reg    [15:0]    select_vector_middle1;
    reg    [15:0]    select_vector_middle2;
    reg    [15:0]    select_vector_middle3;
    reg    [15:0]    select_vector_middle4;
    reg    [15:0]    select_vector_middle5;
    reg              select_vector_end;
    reg    [75:0]    select_vector_half1;
    reg    [48:0]    select_vector_half2;
    reg    [124:0]   select_vector;
    
    reg    [8:0]     radio_sram_addr_27p5;
    reg    [7:0]     radio_sram_wdata_27p5;
    
    begin
        loop_sram                   =    0;
        //select_vector_begin       =    28'b1010_100_010_01_00100000_01100000;    //This is sort-of made up, targeting just a match of a 96-bit EPC
        select_vector_begin         =    select_blank_bits;
        select_vector_middle0       =    16'b0;                                    //96-bit blank EPC
        select_vector_middle1       =    16'b0;                                    //96-bit blank EPC
        select_vector_middle2       =    16'b0;                                    //96-bit blank EPC
        select_vector_middle3       =    16'b0;                                    //96-bit blank EPC
        select_vector_middle4       =    16'b0;                                    //96-bit blank EPC
        select_vector_middle5       =    16'b0;                                    //96-bit blank EPC
        select_vector_end           =    1'b0;                                     //The 16-b CRC is computed by the TX_GEN
        select_vector_half1         =    {select_vector_begin,select_vector_middle0,select_vector_middle1,select_vector_middle2};
        select_vector_half2         =    {select_vector_middle3,select_vector_middle4,select_vector_middle5,select_vector_end};
        select_vector               =    {select_vector_half1,select_vector_half2};
        
        radio_sram_addr_27p5        =    TX_RAM_ADDR_OFFSET_SEL_2 << 4;
        radio_sram_wdata_27p5       =    {DUMMY_ZERO,BEGIN_SELECT};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {select_vector[124] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        
        for(loop_sram=0;loop_sram<62;loop_sram=loop_sram+1)    begin                            //We should find a way to determine the loop length based on the specified bit string
            radio_sram_addr_27p5    =    radio_sram_addr_27p5+9'd1;
            radio_sram_wdata_27p5   =    {select_vector[122-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,select_vector[122-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
        end
        
        radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
        radio_sram_wdata_27p5       =    {END_PACKET,INSERT_CRC16};
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b0,radio_sram_addr_27p5},radio_sram_wdata_27p5,8'b0000_0000);
    end
endtask