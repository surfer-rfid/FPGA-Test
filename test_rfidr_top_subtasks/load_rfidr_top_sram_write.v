/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Write Command                                                        //
//                                                                                     //
// Filename: load_rfidr_top_sram_write.v                                               //
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
//    Load a complete WRITE command into the TX section of the radio SRAM.             //
//    This function calls sub-write commands which each handle 16 bits at a time.      //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_rfidr_top_sram_write;

    input    [9:0]     write_packet_bits;
    input    [31:0]    seed;
    
    //Include the write_16b file at the top level test module
    //`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_write_16b.v"
    
    integer            seed_intl;
    reg      [15:0]    data [0:5];
    
    begin
        seed_intl    =    seed;
        data[0]      =    {$random(seed_intl)} % (2**16);
        data[1]      =    {$random(seed_intl)} % (2**16);
        data[2]      =    {$random(seed_intl)} % (2**16);
        data[3]      =    {$random(seed_intl)} % (2**16);
        data[4]      =    {$random(seed_intl)} % (2**16);
        data[5]      =    {$random(seed_intl)} % (2**16);
        $display("Loaded write 16b %b at time %t",data[0],$realtime);
        load_rfidr_top_sram_write_16b(write_packet_bits,8'h20,data[0],3'b000,1'b0);    //EPC address is by bit as opposed to by byte, see Page 44/152, Fig. 6.19 of v2.0 of RFID spec.
        $display("Loaded write 16b %b at time %t",data[1],$realtime);
        load_rfidr_top_sram_write_16b(write_packet_bits,8'h30,data[1],3'b001,1'b0);
        $display("Loaded write 16b %b at time %t",data[2],$realtime);
        load_rfidr_top_sram_write_16b(write_packet_bits,8'h40,data[2],3'b010,1'b0);
        $display("Loaded write 16b %b at time %t",data[3],$realtime);
        load_rfidr_top_sram_write_16b(write_packet_bits,8'h50,data[3],3'b011,1'b0);
        $display("Loaded write 16b %b at time %t",data[4],$realtime);
        load_rfidr_top_sram_write_16b(write_packet_bits,8'h60,data[4],3'b100,1'b0);
        $display("Loaded write 16b %b at time %t",data[5],$realtime);
        load_rfidr_top_sram_write_16b(write_packet_bits,8'h70,data[5],3'b101,1'b1);
    end
endtask