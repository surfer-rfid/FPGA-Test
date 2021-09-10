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
    
    integer             loop_crc;
    reg       [15:0]    crc_reg, crc_reg_next;
    reg                 data_in;
    
    begin
        
        loop_crc        =    length-1;
        data_in         =    1'b0;        //This should get overwritten right away
        crc_reg         =    16'hFFFF;
        crc_reg_next    =    16'hFFFF;
    
        for(loop_crc=length-1;loop_crc>=0;loop_crc=loop_crc-1)    begin
            data_in                =    (bits >> loop_crc) & 256'd1;        //According to Section 4.1.5 of Verilog 2001 spec., integer division shall truncate any fractional part to zero.
            //$display("CRC data in is %b for iter %d at time %t",data_in,loop_crc,$realtime);
            crc_reg_next[0]        =    crc_reg[15] ^ data_in;
            crc_reg_next[1]        =    crc_reg[0];
            crc_reg_next[2]        =    crc_reg[1];
            crc_reg_next[3]        =    crc_reg[2];
            crc_reg_next[4]        =    crc_reg[3];
            crc_reg_next[5]        =    (crc_reg[15] ^ data_in) ^ crc_reg[4];
            crc_reg_next[6]        =    crc_reg[5];
            crc_reg_next[7]        =    crc_reg[6];
            crc_reg_next[8]        =    crc_reg[7];
            crc_reg_next[9]        =    crc_reg[8];
            crc_reg_next[10]       =    crc_reg[9];
            crc_reg_next[11]       =    crc_reg[10];
            crc_reg_next[12]       =    (crc_reg[15] ^ data_in) ^ crc_reg[11];
            crc_reg_next[13]       =    crc_reg[12];
            crc_reg_next[14]       =    crc_reg[13];
            crc_reg_next[15]       =    crc_reg[14];
        
            crc_reg                =    crc_reg_next;
        end
        
        crc_16    =    ~crc_reg;
    end
endtask