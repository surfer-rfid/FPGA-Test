/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : RX Local Parameter Definitions                                            //
//                                                                                     //
// Filename: load_rfidr_top_sram_rx_localparam_defs.v                                  //
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
                                                             //Total    (16 bytes usually)


    localparam    EFFECTIVE_REG_RPLY_BITS      =    264;
    localparam    EFFECTIVE_EXT_RPLY_BITS      =    90000;
    localparam    EFFECTIVE_PILOT_BITS         =    16;
    localparam    EFFECTIVE_SYNC_BITS          =    6;
    
    localparam    RX_BITS_RN16                 =    32;
    localparam    RX_BITS_RN16_I               =    16;
    localparam    RX_BITS_HANDLE               =    32;
    localparam    RX_BITS_WRITE                =    33;     //Remember that this is a delayed reply - 33 bits for a successful reply, 33+8 bits for an unsuccessful reply
    localparam    RX_BITS_LOCK                 =    33;     //Remember that this is a delayed reply - Assume that both are successful
    localparam    RX_BITS_READ                 =    129;    //(1 bit header+96 bits+16 bit RN+16 bit CRC)
    localparam    RX_BITS_PCEPC                =    112;    //(apparently we are after 96+16 bits - ah yes, a 96 bit EPC and a 16 bit CRC)
    
    localparam    DUMMY_BIT                    =    1;      //Dont forget that there is a dummy bit - not that we use it (maybe we should be using it?)
    

    
    
    //localparam    STATE_DONE          =    5'd0;         //    The idle state - wait here for top level FSM to kick this off again
    //localparam    STATE_RESET         =    5'd1;         //    An optional state designed to reset everything for the next run.
    //localparam    STATE_TX_TXCW0      =    5'd2;         // Transmit a CW signal to allow the TX cancellation to converge (low RX gain)
    //localparam    STATE_TX_SELECT     =    5'd3;         //    Read the select packet from the appropriate location in SRAM and TX it.
    //localparam    STATE_TX_QUERY      =    5'd4;         //    Read the query packet from the appropriate location in SRAM and TX it.
    //localparam    STATE_RX_RN16_I     =    5'd5;         // Obtain the first RN16 in the transaction.(from Query rep, query, or query adjust)
    //localparam    STATE_TX_QRY_REP    =    5'd6;         //    Perform a query rep in order to check number of tags or otherwise
    //localparam    STATE_TX_ACK_RN16   =    5'd7;         //    Acknowledge the first RN16 packet with {2'b01,RN16}.
    //localparam    STATE_RX_PCEPC      =    5'd8;         // Receive the PC+EPC+CRC from the tag and store it in designated SRAM location.
    //localparam    STATE_TX_NAK_CNTE   =    5'd9;         // TX a NAK in response to bad PCEPC received, but continue inventorying
    //localparam    STATE_TX_NAK_EXIT   =    5'd10;        //    TX a NAK in response to an error in order to allow tags to power down OK
    //localparam    STATE_TX_REQHDL     =    5'd11;        //    Make a special case for requesting the handle
    //localparam    STATE_RX_HANDLE     =    5'd12;        //    Receive the handle from the tag and store it in designated reg/SRAM locations.
    //localparam    STATE_TX_REQRN16    =    5'd13;        //    Transmit the REQRN, assembled from register contents
    //localparam    STATE_RX_RN16       =    5'd14;        // Receive a RN16 from the tag for purposes of sending a write or lock
    //localparam    STATE_TX_WRITE      =    5'd15;        //    Transmit a write from its SRAM location
    //localparam    STATE_RX_WRITE      =    5'd16;        //    Receive a write delayed response, store result in designated SRAM location
    //localparam    STATE_TX_READ       =    5'd17;        //    Transmit a read request from designated TX SRAM location.
    //localparam    STATE_RX_READ       =    5'd18;        //    Receive a read response - store in designated SRAM location.
    //localparam    STATE_TX_LOCK       =    5'd19;        //    Transmit a lock request from designated TX SRAM location.
    //localparam    STATE_RX_LOCK       =    5'd20;        //    Receive lock response - delayed response - store in designated SRAM location
    //localparam    STATE_TX_ACK_HDL    =    5'd21;        //    Transmit an ACK with a handle
    //localparam    STATE_TX_SEL_BLNK   =    5'd22;        //    Select tags with bank EPCs. This is done commonly enough that we reserve memory for this operation.
    //localparam    STATE_INV_HOLD      =    5'd23;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_24      =    5'd24;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_25      =    5'd25;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_26      =    5'd26;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_27      =    5'd27;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_28      =    5'd28;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_29      =    5'd29;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_30      =    5'd30;        //    Dummy state - return to DONE
    //localparam    STATE_DUMMY_31      =    5'd31;        //    Dummy state    - return to DONE
    
    localparam    STATE_DONE            =    5'd0;     //    The idle state - wait here for top level FSM to kick this off again
    localparam    STATE_RESET           =    5'd1;     //    An optional state designed to reset everything for the next run.
    localparam    STATE_TX_TXCW0        =    5'd2;     //     Transmit a CW signal to allow the TX cancellation to converge (low RX gain)
    localparam    STATE_TX_SELECT       =    5'd3;     //    Read the select packet from the appropriate location in SRAM and TX it.
    localparam    STATE_TX_SEL_2        =    5'd4;     //    Reserve memory for a second select operation. This is needed to assert SL and inventory tags on the same query.
    localparam    STATE_TX_QUERY        =    5'd5;     //    Read the query packet from the appropriate location in SRAM and TX it.
    localparam    STATE_RX_RN16_I       =    5'd6;     //     Obtain the first RN16 in the transaction.
    localparam    STATE_TX_QRY_REP      =    5'd7;     //    Perform a query rep in order to check number of tags or otherwise
    localparam    STATE_TX_ACK_RN16     =    5'd8;     //    Acknowledge the first RN16 packet with {2'b01,RN16}.
    localparam    STATE_TX_ACK_HDL      =    5'd9;     //    Transmit an ACK with a handle
    localparam    STATE_RX_PCEPC        =    5'd10;    //     Receive the PC+EPC+CRC from the tag and store it in designated SRAM location.
    localparam    STATE_TX_NAK_CNTE     =    5'd11;    //     TX a NAK in response to bad PCEPC received, but continue inventorying
    localparam    STATE_TX_NAK_EXIT     =    5'd12;    //    TX a NAK in response to an error in order to allow tags to power down OK
    localparam    STATE_TX_REQHDL       =    5'd13;    //    Make a special case for requesting the handle
    localparam    STATE_RX_HANDLE       =    5'd14;    //    Receive the handle from the tag and store it in designated reg/SRAM locations.
    localparam    STATE_TX_REQRN16      =    5'd15;    //    Transmit the REQRN, assembled from register contents
    localparam    STATE_RX_RN16         =    5'd16;    //     Receive a RN16 from the tag for purposes of sending a write or lock or from Query rep
    localparam    STATE_TX_WRITE        =    5'd17;    //    Transmit a write from its SRAM location
    localparam    STATE_RX_WRITE        =    5'd18;    //    Receive a write delayed response, store result in designated SRAM location
    localparam    STATE_TX_READ         =    5'd19;    //    Transmit a read request from designated TX SRAM location.
    localparam    STATE_RX_READ         =    5'd20;    //    Receive a read response - store in designated SRAM location.
    localparam    STATE_TX_LOCK         =    5'd21;    //    Transmit a lock request from designated TX SRAM location.
    localparam    STATE_RX_LOCK         =    5'd22;    //    Receive lock response - delayed response - store in designated SRAM location
    localparam    STATE_INV_HOLD        =    5'd23;    //    Hold inventory while we wait for the MCU to process the EPC results.
    localparam    STATE_INV_END         =    5'd24;    //    Delay state to return to DONE after inventory. This is required to properly step through the rfidr_fsm.v state machine.
    localparam    STATE_INV_END_2       =    5'd25;    //    Another delay state to return to DONE after inventory. As of 111317 can't figure out why this is needed, but it is.
    localparam    STATE_INV_END_3       =    5'd26;    //    Yet another delay state to return to DONE after inventory. This one was added. "For good measure"
    localparam    STATE_TX_QRY_REP_B    =    5'd27;    //    Dummy state - return to DONE
    localparam    STATE_DUMMY_28        =    5'd28;    //    Dummy state - return to DONE
    localparam    STATE_DUMMY_29        =    5'd29;    //    Dummy state - return to DONE
    localparam    STATE_DUMMY_30        =    5'd30;    //    Dummy state - return to DONE
    localparam    STATE_DUMMY_31        =    5'd31;    //    Dummy state    - return to DONE
    
    localparam    DR_STATE_DONE            =    16'b0000_0000_0000_0001;
    localparam    DR_STATE_RESET           =    16'b0000_0000_0000_0010;
    localparam    DR_STATE_IDLE            =    16'b0000_0000_0000_0100;
    localparam    DR_STATE_LOCKED          =    16'b0000_0000_0000_1000;
    localparam    DR_STATE_SYNC            =    16'b0000_0000_0001_0000;
    localparam    DR_STATE_BITS            =    16'b0000_0000_0010_0000;
    localparam    DR_STATE_RPT_EXIT_CODE   =    16'b0000_0000_0100_0000;
    localparam    DR_STATE_RPT_MI_BYT0     =    16'b0000_0000_1000_0000;    
    localparam    DR_STATE_RPT_MI_BYT1     =    16'b0000_0001_0000_0000;
    localparam    DR_STATE_RPT_MI_BYT2     =    16'b0000_0010_0000_0000;    
    localparam    DR_STATE_RPT_MI_BYT3     =    16'b0000_0100_0000_0000;
    localparam    DR_STATE_RPT_MQ_BYT0     =    16'b0000_1000_0000_0000;    
    localparam    DR_STATE_RPT_MQ_BYT1     =    16'b0001_0000_0000_0000;
    localparam    DR_STATE_RPT_MQ_BYT2     =    16'b0010_0000_0000_0000;    
    localparam    DR_STATE_RPT_MQ_BYT3     =    16'b0100_0000_0000_0000;
    localparam    DR_STATE_DUMMY           =    16'b1000_0000_0000_0000;
    
    