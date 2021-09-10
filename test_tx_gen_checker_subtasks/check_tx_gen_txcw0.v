/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN SELECT Generation                                            //
//                                                                                     //
// Filename: check_tx_gen_txcw0.v                                                      //
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
//    Check that the proper TXCW0 command exits the TX GEN output.                     //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    check_tx_gen_txcw0;

    `include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    `include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_localparam_defs.v"
    
    //input(global) out_i_baseband_4p5

    integer    state_counter;
    
    reg    [3:0]    state_txcw0;
    reg    [3:0]    state_txcw0_next;
    
    begin
        state_txcw0      =    STATE_HI_TXCW0;
        state_counter    =    0;
        
        while(state_counter < HI_COUNT_CW0) begin
            @(negedge clk_4p5);
            
            //Default variable settings
            state_txcw0_next    =    state_txcw0;
            
            case(state_txcw0)
                STATE_HI_TXCW0: begin
                    if(out_i_baseband_4p5 == 1'b0)    begin
                        $display("Improper bit out during txcw0 packet at state_counter %d at time %t",state_counter,$realtime);
                        $stop;
                    end
                    state_counter    =    state_counter+1;
                end
                default: begin
                    $display("Got into a bad state in check_tx_gen_txcw0 at time %t",$realtime);
                    $stop;
                end
            endcase
        end    //end forever loop
        state_counter        =    0;
        $display("Successfully received a TXCW0 packet at time %t",$realtime);
    end
endtask