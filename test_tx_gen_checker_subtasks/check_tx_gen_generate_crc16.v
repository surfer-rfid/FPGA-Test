/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN CRC Generation                                               //
//                                                                                     //
// Filename: check_tx_gen_generate_crc16.v                                             //
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
//    Check that the proper CRC16 exits the TX GEN output.                             //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    check_tx_gen_generate_crc16;    //Want automatic because there will be different instances with different bit widths

    input     [255:0]   bits;           //We need to input a variable number of bits.
    input     [31:0]    length;         //We need to know the length of the bit vector entered in as "bits"
    output    [15:0]    crc_16;         //Since this is a one-shot task, can just output the CRC16.
    
    localparam          CRC_POLY    =    16'b0001_0000_0010_0000;
    
    integer             loop_shift;
    reg       [15:0]    shift_reg, shift_reg_next;
    reg                 bit_in;
    
    begin
        
        loop_shift        =    length-1;
        bit_in            =    1'b0;        //This should get overwritten right away
        shift_reg         =    16'hFFFF;
        shift_reg_next    =    16'hFFFF;
    
        for(loop_shift=length-1;loop_shift>=0;loop_shift=loop_shift-1)    begin
            bit_in                   =    (bits >> loop_shift) & 256'd1;
            //According to Section 4.1.5 of Verilog 2001 spec., integer division shall truncate any fractional part to zero.
            //$display("CRC data in is %b for iter %d at time %t",bit_in,loop_shift,$realtime);
            shift_reg_next    =    ({16{shift_reg[15] ^ bit_in}} & CRC_POLY) ^ {shift_reg[14:0],shift_reg[15] ^ bit_in};
            shift_reg         =    shift_reg_next;
        end
        
        crc_16    =    ~shift_reg;
    end
endtask