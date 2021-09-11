/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN SELECT Generation                                            //
//                                                                                     //
// Filename: check_tx_gen_select.v                                                     //
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
//    Check that the proper SELECT command exits the TX GEN output.                    //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    check_tx_gen_select;
    
    input    [27:0]    select_bits;
    input    [31:0]    seed;
    //input(global)    out_i_baseband_4p5

    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_localparam_defs.v"
    
    integer          seed_intl;
    integer          state_counter;
    integer          length_select_vector_final;
    integer          bit_counter;
    
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
    reg    [15:0]    select_vector_crc16;
    reg    [140:0]   select_vector_final;
    reg    [3:0]     state_select;
    reg    [3:0]     state_select_next;
    reg              done_flag;
    
    begin
        seed_intl                     =    seed;
        select_vector_begin           =    select_bits;
        select_vector_middle0         =    {$random(seed_intl)} % (2**16);            //96-bit EPC
        select_vector_middle1         =    {$random(seed_intl)} % (2**16);            //96-bit EPC
        select_vector_middle2         =    {$random(seed_intl)} % (2**16);            //96-bit EPC
        select_vector_middle3         =    {$random(seed_intl)} % (2**16);            //96-bit EPC
        select_vector_middle4         =    {$random(seed_intl)} % (2**16);            //96-bit EPC
        select_vector_middle5         =    {$random(seed_intl)} % (2**16);            //96-bit EPC
        select_vector_end             =    1'b0;                                      //The 16-b CRC is computed by the TX_GEN
        select_vector_half1           =    {select_vector_begin,select_vector_middle0,select_vector_middle1,select_vector_middle2};
        select_vector_half2           =    {select_vector_middle3,select_vector_middle4,select_vector_middle5,select_vector_end};
        select_vector                 =    {select_vector_half1,select_vector_half2};
        check_tx_gen_generate_crc16({131'b0,select_vector},125,select_vector_crc16);
        select_vector_final           =    {select_vector,select_vector_crc16};
        length_select_vector_final    =    141;
        state_select                  =    STATE_HI_BEGIN;
        state_counter                 =    0;
        bit_counter                   =    0;
        done_flag                     =    1'b0;
        
        while(done_flag    ==    1'b0)    begin
            @(negedge clk_4p5);
            
            //Default variable settings
            state_select_next    =    state_select;
            
            case(state_select)
                STATE_HI_BEGIN: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_BEGIN_SELECT)    begin
                        state_select_next    =    STATE_LO_BEGIN;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_BEGIN: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_DELIMITER)    begin
                        state_select_next    =    STATE_HI_DUMMY_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_DUMMY_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ZERO)    begin
                        state_select_next    =    STATE_LO_DUMMY_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_DUMMY_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        state_select_next    =    STATE_HI_RTCAL;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_RTCAL: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_RTCAL)    begin
                        state_select_next    =    STATE_LO_RTCAL;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_RTCAL: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        if(select_vector_final[length_select_vector_final-1-bit_counter])    //bit_counter is zero here, we just include it in the code to make the code more uniform.
                            state_select_next    =    STATE_HI_ONE;
                        else
                            state_select_next    =    STATE_HI_ZERO;
                        state_counter            =    0;
                    end    else begin
                        state_counter            =    state_counter+1;
                    end
                end
                STATE_HI_ONE: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ONE)    begin
                        state_select_next    =    STATE_LO_ONE;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_ONE: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        bit_counter=bit_counter+1;
                        if(length_select_vector_final-1-bit_counter < 0)
                            state_select_next    =    STATE_INTERPACKET;
                        else if(select_vector_final[length_select_vector_final-1-bit_counter])
                            state_select_next    =    STATE_HI_ONE;
                        else
                            state_select_next    =    STATE_HI_ZERO;
                        state_counter            =    0;
                    end    else begin
                        state_counter            =    state_counter+1;
                    end
                end
                STATE_HI_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ZERO)    begin
                        state_select_next    =    STATE_LO_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        bit_counter=bit_counter+1;
                        if(length_select_vector_final-1-bit_counter < 0)
                            state_select_next    =    STATE_INTERPACKET;
                        else if(select_vector_final[length_select_vector_final-1-bit_counter])
                            state_select_next    =    STATE_HI_ONE;
                        else
                            state_select_next    =    STATE_HI_ZERO;
                        state_counter            =    0;
                    end    else begin
                        state_counter            =    state_counter+1;
                    end
                end
                STATE_INTERPACKET: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during select packet at time %t",$realtime);
                        $stop;
                    end
                    if(tx_go == 1'b1)    begin
                        $display("tx_go was asserted during an interpacket space at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= EFFECTIVE_INTERPACKET_BITS)    begin
                        done_flag            =    1'b1;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                default: begin
                    $display("Got into a bad state in check_tx_gen_select at time %t",$realtime);
                    $stop;
                end
            endcase
            state_select    =    state_select_next;    //Update state variable
            
        end    //end forever loop
        state_counter    =    0;
        $display("Successfully received a SELECT packet at time %t",$realtime);
    end
endtask