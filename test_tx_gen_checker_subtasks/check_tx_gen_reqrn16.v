/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN REQ RN16 Generation                                          //
//                                                                                     //
// Filename: check_tx_gen_reqrn16.v                                                    //
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
//    Check that the proper REQ RN16 command exits the TX GEN output.                  //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    check_tx_gen_reqrn16;
    
    input    [15:0]    reqrn16_bits;
    
    //input(global)    out_i_baseband_4p5
    //input(global)    clk_4p5

    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_localparam_defs.v"
    
    integer            reqrn16_vector_pass;
    integer            state_counter;
    integer            length_reqrn16_vector_final;
    integer            bit_counter;
    
    reg      [23:0]    reqrn16_vector;
    reg      [15:0]    reqrn16_vector_crc16;
    reg      [39:0]    reqrn16_vector_final;
    reg      [3:0]     state_reqrn16;
    reg      [3:0]     state_reqrn16_next;
    reg                done_flag;
    
    begin
        reqrn16_vector                 =    {8'b1100_0001,reqrn16_bits};
        reqrn16_vector_pass            =    reqrn16_vector;
        check_tx_gen_generate_crc16(reqrn16_vector_pass,24,reqrn16_vector_crc16);
        reqrn16_vector_final           =    {reqrn16_vector,reqrn16_vector_crc16};
        length_reqrn16_vector_final    =    40;
        state_reqrn16                  =    STATE_HI_BEGIN;
        state_counter                  =    0;
        bit_counter                    =    0;
        done_flag                      =    1'b0;
        
        while(done_flag    ==    1'b0)    begin
            @(negedge clk_4p5);
            
            //Default variable settings
            state_reqrn16_next    =    state_reqrn16;
            
            case(state_reqrn16)
                STATE_HI_BEGIN: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_BEGIN_REGULAR)    begin
                        state_reqrn16_next    =    STATE_LO_BEGIN;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_LO_BEGIN: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_DELIMITER)    begin
                        state_reqrn16_next    =    STATE_HI_DUMMY_ZERO;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_HI_DUMMY_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ZERO)    begin
                        state_reqrn16_next    =    STATE_LO_DUMMY_ZERO;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_LO_DUMMY_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        state_reqrn16_next    =    STATE_HI_RTCAL;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_HI_RTCAL: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_RTCAL)    begin
                        state_reqrn16_next    =    STATE_LO_RTCAL;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_LO_RTCAL: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        if(reqrn16_vector_final[length_reqrn16_vector_final-1-bit_counter])    //bit_counter is zero here, we just include it in the code to make the code more uniform.
                            state_reqrn16_next    =    STATE_HI_ONE;
                        else
                            state_reqrn16_next    =    STATE_HI_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_ONE: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ONE)    begin
                        state_reqrn16_next    =    STATE_LO_ONE;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_LO_ONE: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        bit_counter=bit_counter+1;
                        if(length_reqrn16_vector_final-1-bit_counter < 0)
                            state_reqrn16_next    =    STATE_INTERPACKET;
                        else if(reqrn16_vector_final[length_reqrn16_vector_final-1-bit_counter])
                            state_reqrn16_next    =    STATE_HI_ONE;
                        else
                            state_reqrn16_next    =    STATE_HI_ZERO;    
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_HI_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= HI_COUNT_ZERO)    begin
                        state_reqrn16_next    =    STATE_LO_ZERO;
                        state_counter         =    0;
                    end    else begin
                        state_counter         =    state_counter+1;
                    end
                end
                STATE_LO_ZERO: begin
                    if(out_i_baseband_4p5 == 1'b1)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
                        $stop;
                    end
                    if(state_counter >= LO_COUNT_REGULAR)    begin
                        bit_counter=bit_counter+1;
                        if(length_reqrn16_vector_final-1-bit_counter < 0)
                            state_reqrn16_next    =    STATE_INTERPACKET;
                        else if(reqrn16_vector_final[length_reqrn16_vector_final-1-bit_counter])
                            state_reqrn16_next    =    STATE_HI_ONE;
                        else
                            state_reqrn16_next    =    STATE_HI_ZERO;
                        state_counter        =    0;
                    end    else begin
                        state_counter        =    state_counter+1;
                    end
                end
                STATE_INTERPACKET: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during reqrn16 packet at time %t",$realtime);
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
                    $display("Got into a bad state in check_tx_gen_reqrn16 at time %t",$realtime);
                    $stop;
                end
            endcase
            state_reqrn16    =    state_reqrn16_next;    //Update state variable    
        end    //end forever loop
        state_counter        =    0;
        $display("Successfully received a reqrn16 packet at time %t",$realtime);
    end
endtask