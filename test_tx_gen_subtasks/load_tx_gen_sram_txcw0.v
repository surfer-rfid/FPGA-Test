/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load TXCW0 Command                                                        //
//                                                                                     //
// Filename: load_tx_gen_sram_txcw0.v                                                  //
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
//    Load a TXCW0 command into the TX section of the radio SRAM.                      //
//    Recall that TXCW0=transmit a continuous wave for about 1.8ms.                    //
//    This is done directly to the radio SRAM for a TX GEN only simulation.            ..
//                                                                                     //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_txcw0;

    `include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    
    reg        done_flag;
    //reg      clk_ram;
    
    begin
        done_flag                              =    1'b0;
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
            //Load TXCW0
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b1;
                radio_sram_addr_27p5           =    TX_RAM_ADDR_OFFSET_TXCW0  << 4;
                radio_sram_wdata_27p5          =    {END_PACKET,TXCW0};
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b0;
                @(negedge clk_ram);
                done_flag                      =    1'b1;
            end
        join
    end
endtask