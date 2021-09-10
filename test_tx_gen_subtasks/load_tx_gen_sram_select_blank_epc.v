/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Select Command                                                       //
//                                                                                     //
// Filename: load_tx_gen_sram_select_blank_epc.v                                       //
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
//    This is done directly to the radio SRAM for a TX GEN only simulation.            //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_select_blank_epc;

    input    [27:0]    select_blank_bits;

    `include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    
    reg        done_flag;
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
    
    begin
        loop_sram                =    0;
        done_flag                =    1'b0;
        //select_vector_begin    =    28'b1010_100_010_01_00100000_01100000;    //This is sort-of made up, targeting just a match of a 96-bit EPC
        select_vector_begin      =    select_blank_bits;
        select_vector_middle0    =    16'b0;                                    //96-bit blank EPC
        select_vector_middle1    =    16'b0;                                    //96-bit blank EPC
        select_vector_middle2    =    16'b0;                                    //96-bit blank EPC
        select_vector_middle3    =    16'b0;                                    //96-bit blank EPC
        select_vector_middle4    =    16'b0;                                    //96-bit blank EPC
        select_vector_middle5    =    16'b0;                                    //96-bit blank EPC
        select_vector_end        =    1'b0;                                     //The 16-b CRC is computed by the TX_GEN
        select_vector_half1      =    {select_vector_begin,select_vector_middle0,select_vector_middle1,select_vector_middle2};
        select_vector_half2      =    {select_vector_middle3,select_vector_middle4,select_vector_middle5,select_vector_end};
        select_vector            =    {select_vector_half1,select_vector_half2};
        clk_ram                  =    1'b0;
        
        fork
            begin
                while (done_flag == 1'b0)    begin
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                  =    1'b1;
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                  =    1'b0;                                    //When this ends, have it end low.
                end
            end
            begin
                @(negedge clk_ram);
                radio_sram_we_data_27p5      =    1'b1;                                    //This is an access of a global variable in the top level of the simulation
                radio_sram_addr_27p5         =    TX_RAM_ADDR_OFFSET_SEL_BLNK << 4;
                radio_sram_wdata_27p5        =    {DUMMY_ZERO,BEGIN_SELECT};
                @(negedge clk_ram);
                radio_sram_addr_27p5         =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5        =    {select_vector[124] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
                for(loop_sram=0;loop_sram<62;loop_sram=loop_sram+1)    begin               //We should find a way to determine the loop length based on the specified bit string
                    @(negedge clk_ram);
                    radio_sram_addr_27p5     =    radio_sram_addr_27p5+9'd1;
                    radio_sram_wdata_27p5    =    {select_vector[122-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,select_vector[122-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
                end
                @(negedge clk_ram);
                radio_sram_addr_27p5         =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5        =    {END_PACKET,INSERT_CRC16};
                @(negedge clk_ram);
                radio_sram_we_data_27p5      =    1'b0;
                @(negedge clk_ram);
                done_flag                    =    1'b1;
            end
        join
    end
endtask