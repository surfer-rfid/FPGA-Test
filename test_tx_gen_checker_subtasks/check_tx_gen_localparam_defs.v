/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Local parameters for the TX GEN to be used in checker subtasks            //
//                                                                                     //
// Filename: check_tx_gen_localparam_defs.v                                            //
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
//    Local parameters for the TX GEN to be used in checker subtasks.                  //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

    // 4.5 MHz periods for low signaling intervals
    
    localparam    LO_COUNT_REGULAR              =    6'd42;      //As per UHF RFID Specification
    localparam    LO_COUNT_DELIMITER            =    6'd56;      //As per UHF RFID Specification
    localparam    LO_COUNT_CW0                  =    6'd0;       //As per UHF RFID Specification

    // 4.5 MHz periods for high signaling intervals
    
    localparam    HI_COUNT_ZERO                 =    13'd54;     //As per UHF RFID Specification
    localparam    HI_COUNT_ONE                  =    13'd126;    //As per UHF RFID Specification
    localparam    HI_COUNT_RTCAL                =    13'd222;    //As per UHF RFID Specification
    localparam    HI_COUNT_TRCAL                =    13'd468;    //As per UHF RFID Specification
    localparam    HI_COUNT_CW0                  =    13'd8190;
    localparam    HI_COUNT_BEGIN_SELECT         =    13'd8190;
    localparam    HI_COUNT_BEGIN_REGULAR        =    13'd576;    // Standard minimum interpacket spacing
    
    //Checker states
    
    localparam    STATE_HI_TXCW0                =    4'd0;       //LO_TXCW0 is a fiction - it's 0 bits wide
    localparam    STATE_INTERPACKET             =    4'd1;
    localparam    STATE_HI_BEGIN                =    4'd2;
    localparam    STATE_LO_BEGIN                =    4'd3;
    localparam    STATE_HI_NAK_END              =    4'd4;
    localparam    STATE_HI_DUMMY_ZERO           =    4'd6;
    localparam    STATE_LO_DUMMY_ZERO           =    4'd7;
    localparam    STATE_HI_RTCAL                =    4'd8;
    localparam    STATE_LO_RTCAL                =    4'd9;
    localparam    STATE_HI_TRCAL                =    4'd10;
    localparam    STATE_LO_TRCAL                =    4'd11;
    localparam    STATE_HI_ZERO                 =    4'd12;
    localparam    STATE_LO_ZERO                 =    4'd13;
    localparam    STATE_HI_ONE                  =    4'd14;
    localparam    STATE_LO_ONE                  =    4'd15;
    
    localparam    EFFECTIVE_INTERPACKET_BITS    =    0;         //We need to check on this - is the "begin regular" enforcing minimum tag reply delay ? <= Answer: yes it is.