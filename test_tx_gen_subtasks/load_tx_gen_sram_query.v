/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Query Command                                                        //
//                                                                                     //
// Filename: load_tx_gen_sram_query.v                                                  //
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
//    This is done directly to the radio SRAM for a TX GEN only simulation.            //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_query;
    
    input    [21:0]      query_bits;
    
    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    
    reg                  done_flag;
    reg        [21:0]    query_vector;
    
    integer    loop_sram;
    
    begin
        done_flag                              =    1'b0;
        //query_vector                         =    22'b1000_1_11_1_00_00_0_0111_01010;        //Command_DR_M_TRext_Sel_Session_Tgt_Q_CRC5 (CRC5 here is fake!!!!!)
        //Actually we will bring in query vector from a higher level so the higher level can enforce the same vector being used in both the 
        //SRAM loading and in the checker.
        query_vector                           =    query_bits;
        clk_ram                                =    1'b0;
        
        fork    
            begin
                while (done_flag == 1'b0)    begin
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                    =    1'b1;
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                    =    1'b0;    //When this ends, have it end low.
                end
            end
            begin
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b1;
                radio_sram_addr_27p5           =    TX_RAM_ADDR_OFFSET_QUERY  << 4;
                radio_sram_wdata_27p5          =    {DUMMY_ZERO,BEGIN_REGULAR};
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;            //Would C trick of {addr_offset,addr_incr=addr_incr+1} work here?
                radio_sram_wdata_27p5          =    {TRCAL,RTCAL};
                for(loop_sram=0;loop_sram<11;loop_sram=loop_sram+1)    begin
                    @(negedge clk_ram);
                    radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                    radio_sram_wdata_27p5      =    {query_vector[20-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,query_vector[20-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
                end
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {TXCW0,END_PACKET};
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b0;
                @(negedge clk_ram);
                done_flag                      =    1'b1;
            end
        join
    end
endtask