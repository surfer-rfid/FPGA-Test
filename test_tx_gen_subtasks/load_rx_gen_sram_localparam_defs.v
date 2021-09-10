/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : RX Local Parameter Definitions                                            //
//                                                                                     //
// Filename: load_rx_gen_sram_localparam_defs.v                                        //
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
//    Define local parameters for operation of the RX section of the RFID reader radio.//
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

    //These are copied from data rcvy.v. At some point we need to find a good way to unify these.
    
    localparam    RX_RAM_ADDR_OFFSET_RN16      =    5'd0;    //These offsets are in number of 16-address chunks
    localparam    RX_RAM_ADDR_OFFSET_RN16_I    =    5'd1;    //This is required because the number of received bits is less in RN16_I than in RN16,
    localparam    RX_RAM_ADDR_OFFSET_HANDLE    =    5'd2;    //Format of each slot is:
    localparam    RX_RAM_ADDR_OFFSET_WRITE     =    5'd3;    //Number of bits of valid data          (1 byte)
    localparam    RX_RAM_ADDR_OFFSET_LOCK      =    5'd4;    //Bits of data (with trailing zeros)    (6 bytes usually)
    localparam    RX_RAM_ADDR_OFFSET_READ      =    5'd5;    //Exit code                             (1 byte)
    localparam    RX_RAM_ADDR_OFFSET_PCEPC     =    5'd7;    //Mag I                                 (4 bytes)
                                                             //Mag Q                                 (4 bytes)
                                                             //Total                                 (16 bytes usually)


    localparam    EFFECTIVE_REG_RPLY_BITS   =    264;
    localparam    EFFECTIVE_EXT_RPLY_BITS   =    90000;
    localparam    EFFECTIVE_PILOT_BITS      =    16;
    localparam    EFFECTIVE_SYNC_BITS       =    6;
    
    localparam    RX_BITS_RN16              =    32;
    localparam    RX_BITS_RN16_I            =    16;
    localparam    RX_BITS_HANDLE            =    32;
    localparam    RX_BITS_WRITE             =    33;     //Remember that this is a delayed reply - 33 bits for a successful reply, 33+8 bits for an unsuccessful reply
    localparam    RX_BITS_LOCK              =    33;     //Remember that this is a delayed reply - Assume that both are successful
    localparam    RX_BITS_READ              =    129;    //(1 bit header+96 bits+16 bit RN+16 bit CRC)
    localparam    RX_BITS_PCEPC             =    112;    //(apparently we are after 96+16 bits - ah yes, a 96 bit EPC and a 16 bit CRC)
    
    localparam    DUMMY_BIT                 =    1;      //Dont forget that there is a dummy bit - not that we use it (maybe we should be using it?)
    
`include "C:/Users/Ed/Documents/SuperSemiSVN/Projects/RFIDr/Engineering/Quartus/source_small/radio_states_include_file.v"
    
    localparam    DR_STATE_DONE             =    16'b0000_0000_0000_0001;
    localparam    DR_STATE_RESET            =    16'b0000_0000_0000_0010;
    localparam    DR_STATE_IDLE             =    16'b0000_0000_0000_0100;
    localparam    DR_STATE_LOCKED           =    16'b0000_0000_0000_1000;
    localparam    DR_STATE_SYNC             =    16'b0000_0000_0001_0000;
    localparam    DR_STATE_BITS             =    16'b0000_0000_0010_0000;
    localparam    DR_STATE_RPT_EXIT_CODE    =    16'b0000_0000_0100_0000;
    localparam    DR_STATE_RPT_MI_BYT0      =    16'b0000_0000_1000_0000;
    localparam    DR_STATE_RPT_MI_BYT1      =    16'b0000_0001_0000_0000;
    localparam    DR_STATE_RPT_MI_BYT2      =    16'b0000_0010_0000_0000;
    localparam    DR_STATE_RPT_MI_BYT3      =    16'b0000_0100_0000_0000;
    localparam    DR_STATE_RPT_MQ_BYT0      =    16'b0000_1000_0000_0000;
    localparam    DR_STATE_RPT_MQ_BYT1      =    16'b0001_0000_0000_0000;
    localparam    DR_STATE_RPT_MQ_BYT2      =    16'b0010_0000_0000_0000;
    localparam    DR_STATE_RPT_MQ_BYT3      =    16'b0100_0000_0000_0000;
    localparam    DR_STATE_DUMMY            =    16'b1000_0000_0000_0000;
    
    