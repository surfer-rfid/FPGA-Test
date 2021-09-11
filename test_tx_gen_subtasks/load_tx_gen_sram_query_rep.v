/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Query Rep Command                                                    //
//                                                                                     //
// Filename: load_tx_gen_sram_query_rep.v                                              //
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
//    Load a TX GEN command into the TX section of the radio SRAM                      //
//    This is done directly to the radio SRAM for a TX GEN only simulation.            //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_query_rep;

    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"

    reg                 done_flag;
    reg        [4:0]    query_rep_vector;
    
    begin
        done_flag                           =    1'b0;
        query_rep_vector                    =    4'b00_00;
        clk_ram                             =    1'b0;

        fork    
            begin
                while (done_flag == 1'b0)    begin
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                 =    1'b1;
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                 =    1'b0;                                    //When this ends, have it end low.
                end
            end
            begin
                @(negedge clk_ram);
                radio_sram_we_data_27p5     =    1'b1;
                radio_sram_addr_27p5        =    TX_RAM_ADDR_OFFSET_QRY_REP  << 4;
                radio_sram_wdata_27p5       =    {DUMMY_ZERO,BEGIN_REGULAR};
                @(negedge clk_ram);
                radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5       =    {query_rep_vector[3] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
                @(negedge clk_ram);
                radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5       =    {query_rep_vector[1] ? SINGLE_ONE : SINGLE_ZERO,query_rep_vector[2] ? SINGLE_ONE : SINGLE_ZERO};
                @(negedge clk_ram);
                radio_sram_addr_27p5        =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5       =    {END_PACKET,query_rep_vector[0] ? SINGLE_ONE : SINGLE_ZERO};
                @(negedge clk_ram);
                radio_sram_we_data_27p5     =    1'b0;
                @(negedge clk_ram);
                done_flag                   =    1'b1;
            end
        join
    end
endtask