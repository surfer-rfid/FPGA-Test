/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Req_RN Handle Variant Command                                        //
//                                                                                     //
// Filename: load_tx_gen_sram_reqhdl.v                                                 //
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
//    Load a REQ_RN (handle variant) command into the TX section of the radio SRAM     //
//    This is done directly to the radio SRAM for a TX GEN only simulation.            //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_reqhdl;

    `include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    
    reg                done_flag;
    
    begin
        done_flag                          =    1'b0;
        clk_ram                            =    1'b0;
        fork    
            begin
                while (done_flag == 1'b0)    begin
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                =    1'b1;
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                =    1'b0;
                end
            end
            begin
                @(negedge clk_ram);
                radio_sram_we_data_27p5    =    1'b1;
                radio_sram_addr_27p5       =    TX_RAM_ADDR_OFFSET_REQHDL  << 4;
                radio_sram_wdata_27p5      =    {DUMMY_ZERO,BEGIN_REGULAR};
                @(negedge clk_ram);
                radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5      =    {SINGLE_ONE,RTCAL};
                @(negedge clk_ram);
                radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5      =    {SINGLE_ZERO,SINGLE_ONE};
                @(negedge clk_ram);
                radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5      =    {SINGLE_ZERO,SINGLE_ZERO};
                @(negedge clk_ram);
                radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5      =    {SINGLE_ZERO,SINGLE_ZERO};
                @(negedge clk_ram);
                radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5      =    {INSERT_RN16,SINGLE_ONE};
                @(negedge clk_ram);
                radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5      =    {END_PACKET,INSERT_CRC16};
                @(negedge clk_ram);
                radio_sram_we_data_27p5    =    1'b0;
                @(negedge clk_ram);
                done_flag                  =    1'b1;
            end
        join
    end
endtask