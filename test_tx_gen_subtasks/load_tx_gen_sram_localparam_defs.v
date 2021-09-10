/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : TX Local Parameter Definitions                                            //
//                                                                                     //
// Filename: load_tx_gen_sram_localparam_defs.v                                        //
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
//    Define local parameters for operation of the TX section of the RFID reader radio.//
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

    localparam    TX_RAM_ADDR_OFFSET_TXCW0      =    5'd0;    //These offsets are in number of 16-address (16-byte) chunks
    localparam    TX_RAM_ADDR_OFFSET_QUERY      =    5'd1;
    localparam    TX_RAM_ADDR_OFFSET_QRY_REP    =    5'd2;
    localparam    TX_RAM_ADDR_OFFSET_ACK_RN16   =    5'd3;
    localparam    TX_RAM_ADDR_OFFSET_ACK_HDL    =    5'd4;
    localparam    TX_RAM_ADDR_OFFSET_NAK        =    5'd5;
    localparam    TX_RAM_ADDR_OFFSET_REQHDL     =    5'd6;
    localparam    TX_RAM_ADDR_OFFSET_REQRN16    =    5'd7;
    localparam    TX_RAM_ADDR_OFFSET_LOCK       =    5'd8;
    localparam    TX_RAM_ADDR_OFFSET_READ       =    5'd10;
    localparam    TX_RAM_ADDR_OFFSET_WRITE0     =    5'd13;    //We allot 24 bytes per write. It takes 6 writes to write a 96b EPC. We allot 6 writes in memory, requiring 144 bytes
    localparam    TX_RAM_ADDR_OFFSET_SELECT     =    5'd22;    //There are 160 bytes left. We may use up to 73 bytes per select command if we use a 16b EBV and 96b condition field. 
    localparam    TX_RAM_ADDR_OFFSET_SEL_BLNK   =    5'd27;    //Therefore, we must allot 80 addresses under this current addresing scheme.
    
    localparam    TXCW0                         =    4'd0;
    localparam    BEGIN_SELECT                  =    4'd1;
    localparam    BEGIN_REGULAR                 =    4'd2;
    localparam    DUMMY_ZERO                    =    4'd3;
    localparam    SINGLE_ZERO                   =    4'd4;
    localparam    SINGLE_ONE                    =    4'd5;
    localparam    RTCAL                         =    4'd6;
    localparam    TRCAL                         =    4'd7;
    localparam    NAK_END                       =    4'd8;    //Added on 091416
    localparam    XOR_NEXT_16B                  =    4'd9;
    localparam    INSERT_CRC16                  =    4'd10;
    localparam    INSERT_RN16                   =    4'd11;
    localparam    INSERT_HANDLE                 =    4'd12;
    localparam    LAST_WRITE                    =    4'd13;
    localparam    END_PACKET                    =    4'd14;
    localparam    DUMMY_15                      =    4'd15;