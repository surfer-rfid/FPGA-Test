/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load LOCK Command                                                         //
//                                                                                     //
// Filename: load_tx_gen_sram_lock.v                                                   //
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
//    Load a LOCK command into the TX section of the radio SRAM                        //
//    This is done directly to the radio SRAM for a TX GEN only simulation.            //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_lock;
    
    input    [27:0]    lock_bits;
    
    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    
    reg                done_flag;
    reg      [7:0]     lock_vector_begin;
    reg      [19:0]    lock_vector_end;
    reg      [27:0]    lock_vector;
    
    integer            loop_sram;
    
    begin
        done_flag              =    1'b0;
        clk_ram                =    1'b0;
        //lock_vector_begin    =    8'b11000101;
        //lock_vector_end      =    {$random(seed_intl)} % (2^20);            //20-bit random data //DUH, where is the input for the seed?!?!
        //lock_vector          =    {lock_vector_begin,lock_vector_end};
        lock_vector            =    lock_bits;
        
        fork    
            begin
                while (done_flag == 1'b0)    begin
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                    =    1'b1;
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                    =    1'b0;
                end
            end
            begin
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b1;
                radio_sram_addr_27p5           =    TX_RAM_ADDR_OFFSET_LOCK  << 4;
                radio_sram_wdata_27p5          =    {DUMMY_ZERO,BEGIN_REGULAR};
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {lock_vector[27] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
                for(loop_sram=0;loop_sram<13;loop_sram=loop_sram+1)    begin                            //We should find a way to determine the loop length based on the specified bit string
                    @(negedge clk_ram);
                    radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                    radio_sram_wdata_27p5      =    {lock_vector[25-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,lock_vector[25-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
                end
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {INSERT_HANDLE,lock_vector[0] ? SINGLE_ONE : SINGLE_ZERO};
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {END_PACKET,INSERT_CRC16};
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b0;
                @(negedge clk_ram);
                done_flag                      =    1'b1;
            end
        join
    end
endtask