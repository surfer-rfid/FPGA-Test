/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN CRC Generation                                               //
//                                                                                     //
// Filename: check_tx_gen_lock.v                                                       //
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
//    Check that the proper LOCK command exits the TX GEN output.                      //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    check_tx_gen_lock;
    
    input    [27:0]    lock_bits;
    input    [15:0]    handle_bits;
    //input(global) out_i_baseband_4p5

    `include   "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    `include   "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_localparam_defs.v"
    
    integer          state_counter;
    integer          length_lock_vector_final;
    integer          bit_counter;
    
    reg    [43:0]    lock_vector;
    reg    [15:0]    lock_vector_crc16;
    reg    [59:0]    lock_vector_final;

    reg    [3:0]     state_lock;
    reg    [3:0]     state_lock_next;
    reg              done_flag;
    
    begin
        lock_vector                 =    {lock_bits,handle_bits};
        length_lock_vector_final    =    60;
        check_tx_gen_generate_crc16({212'b0,lock_vector},44,lock_vector_crc16);
        lock_vector_final           =    {lock_vector,lock_vector_crc16};
        state_lock                  =    STATE_HI_BEGIN;
        state_counter               =    0;
        bit_counter                 =    0;
        done_flag                   =    1'b0;
        
        while(done_flag    ==    1'b0)    begin
            @(negedge clk_4p5);
            
            //Default variable settings
            state_lock_next    =    state_lock;
            
            case(state_lock)
                STATE_HI_BEGIN: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_BEGIN_REGULAR)    begin
                        state_lock_next      =    STATE_LO_BEGIN;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_BEGIN: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_DELIMITER)    begin
                        state_lock_next      =    STATE_HI_DUMMY_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_DUMMY_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ZERO)    begin
                        state_lock_next      =    STATE_LO_DUMMY_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_DUMMY_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        state_lock_next      =    STATE_HI_RTCAL;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_RTCAL: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_RTCAL)    begin
                        state_lock_next      =    STATE_LO_RTCAL;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_RTCAL: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        if(lock_vector_final[length_lock_vector_final-1-bit_counter])    //bit_counter is zero here, we just include it in the code to make the code more uniform.
                            state_lock_next  =    STATE_HI_ONE;
                        else
                            state_lock_next  =    STATE_HI_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_ONE: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ONE)    begin
                        state_lock_next      =    STATE_LO_ONE;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_LO_ONE: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        bit_counter=bit_counter+1;
                        if(length_lock_vector_final-1-bit_counter < 0)
                            state_lock_next    =    STATE_INTERPACKET;
                        else if(lock_vector_final[length_lock_vector_final-1-bit_counter])
                            state_lock_next    =    STATE_HI_ONE;
                        else
                            state_lock_next    =    STATE_HI_ZERO;
                        state_counter          =    0;
                    end    else begin
                        state_counter          =    state_counter+1;
                    end
                end
                STATE_HI_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ZERO)    begin
                        state_lock_next        =    STATE_LO_ZERO;
                        state_counter          =    0;
                    end    else begin
                        state_counter          =    state_counter+1;
                    end
                end
                STATE_LO_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        bit_counter=bit_counter+1;
                        if(length_lock_vector_final-1-bit_counter < 0)
                            state_lock_next    =    STATE_INTERPACKET;
                        else if(lock_vector_final[length_lock_vector_final-1-bit_counter])
                            state_lock_next    =    STATE_HI_ONE;
                        else
                            state_lock_next    =    STATE_HI_ZERO;
                        state_counter          =    0;
                    end    else begin
                        state_counter          =    state_counter+1;
                    end
                end
                STATE_INTERPACKET: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during lock packet at time %t",$realtime);
                        $stop;
                    end
                    if(tx_go == 1'b1)    begin
                        $display("tx_go was asserted during an interpacket space at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= EFFECTIVE_INTERPACKET_BITS)    begin
                        done_flag              =    1'b1;
                    end    else begin
                        state_counter          =    state_counter+1;
                    end
                end
                default: begin
                    $display("Got into a bad state in check_tx_gen_lock at time %t",$realtime);
                    $stop;
                end
            endcase
            state_lock    =    state_lock_next;    //Update state variable
        end    //end forever loop
        state_counter        =    0;
        $display("Successfully received a lock packet at time %t",$realtime);
    end
endtask