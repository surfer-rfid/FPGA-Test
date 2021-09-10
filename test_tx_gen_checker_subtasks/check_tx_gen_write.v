/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN WRITE Generation                                             //
//                                                                                     //
// Filename: check_tx_gen_write.v                                                      //
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
//    Check that the proper WRITE subsegment command exits the TX GEN output.          //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    check_tx_gen_write;

    input    [9:0]     write_packet_bits;
    input    [31:0]    seed_data_bits;
    input    [31:0]    seed_rn16_bits;
    input    [15:0]    handle_bits;
    input    [2:0]     wpc;
    
    //Include this file at the top level simulation module
    //`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_write_16b.v"
    
    integer            seed_data_bits_intl;
    integer            seed_rn16_bits_intl;
    
    reg    [15:0]      data        [0:5];
    reg    [15:0]      rn16        [0:5];
    
    begin
        seed_data_bits_intl        =    seed_data_bits;
        seed_rn16_bits_intl        =    seed_rn16_bits;
        
        data[0]        =    {$random(seed_data_bits_intl)} % 2**16;
        data[1]        =    {$random(seed_data_bits_intl)} % 2**16;
        data[2]        =    {$random(seed_data_bits_intl)} % 2**16;
        data[3]        =    {$random(seed_data_bits_intl)} % 2**16;
        data[4]        =    {$random(seed_data_bits_intl)} % 2**16;
        data[5]        =    {$random(seed_data_bits_intl)} % 2**16;
        
        rn16[0]        =    {$random(seed_rn16_bits_intl)} % 2**16;
        rn16[1]        =    {$random(seed_rn16_bits_intl)} % 2**16;
        rn16[2]        =    {$random(seed_rn16_bits_intl)} % 2**16;
        rn16[3]        =    {$random(seed_rn16_bits_intl)} % 2**16;
        rn16[4]        =    {$random(seed_rn16_bits_intl)} % 2**16;
        rn16[5]        =    {$random(seed_rn16_bits_intl)} % 2**16;
        
        //$display("wpc is %d at time %t",wpc,$realtime);
        
        case(wpc)
          0:    begin    check_tx_gen_write_16b(write_packet_bits,8'h20,data[0],rn16[0],handle_bits,3'b000);    end     //EPC address is by bit as opposed to by byte, 
          1:    begin    check_tx_gen_write_16b(write_packet_bits,8'h30,data[1],rn16[1],handle_bits,3'b001);    end     //see Page 44/152, Fig. 6.19 of v2.0 of RFID spec.
          2:    begin    check_tx_gen_write_16b(write_packet_bits,8'h40,data[2],rn16[2],handle_bits,3'b010);    end
          3:    begin    check_tx_gen_write_16b(write_packet_bits,8'h50,data[3],rn16[3],handle_bits,3'b011);    end
          4:    begin    check_tx_gen_write_16b(write_packet_bits,8'h60,data[4],rn16[4],handle_bits,3'b100);    end
          5:    begin    check_tx_gen_write_16b(write_packet_bits,8'h70,data[5],rn16[5],handle_bits,3'b101);    end
        endcase
    end
endtask