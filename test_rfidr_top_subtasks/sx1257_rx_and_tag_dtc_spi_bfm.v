/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : SX1257 RX and TAG DTC-over-SPI sub BFM                                    //
//                                                                                     //
// Filename: sx1257_rx_and_tag_dtc_spi_bfm.v                                           //
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
//    This file handles SPI traffic destined for *one* of the four                     //
//    digitally tunable capacitors (DTCs)                                              //
//    Make this a module, because all of this task business is                         //
//    getting out of hand with the global variable accessing.                          //
//                                                                                     //
//    091016 - File created                                                            //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module    sx1257_rx_and_tag_dtc_spi_bfm
    (
        input     wire            cntrlr_nps,
        input     wire            cntrlr_pclk,
        input     wire            cntrlr_copi,
        output    reg    [4:0]    dtc_value
    );
    
        localparam    DTC_IDLE                =    2'd0;
        localparam    DTC_RX_DATA_CLK_LOW     =    2'd1;
        localparam    DTC_RX_DATA_CLK_HIGH    =    2'd2;
        localparam    DTC_LIMBO               =    2'd3;
        localparam    CLK_DTC_PERIOD          =    (0.5e9)/(44e6);
        
        reg    [1:0]    dtc_state;
        reg    [3:0]    dtc_ctr;
        reg    [7:0]    dtc_rdata;
    
        initial begin
            dtc_state        =    DTC_IDLE;
            dtc_value        =    5'd15;
        end
        
        initial    begin
        forever    begin
            #CLK_DTC_PERIOD
                
            case(dtc_state)
                DTC_IDLE: begin
                    dtc_ctr              =    4'b0;                  //Indirectly initialize state variables after a reset
                    dtc_rdata            =    8'b0;
                    if(cntrlr_nps && !cntrlr_pclk) begin               //Stay here and wait until cntrlr_nps is low
                        dtc_state        =    DTC_RX_DATA_CLK_LOW;
                        //$display("Does this ever work");
                    end
                end
                DTC_RX_DATA_CLK_LOW: begin
                    if(cntrlr_pclk)    begin
                        dtc_ctr          =    dtc_ctr+4'd1;
                        dtc_rdata        =    {dtc_rdata[6:0],cntrlr_copi};
                        dtc_state        =    DTC_RX_DATA_CLK_HIGH;
                    end
                    if(!cntrlr_nps)
                        dtc_state        =    DTC_IDLE;
                end
                DTC_RX_DATA_CLK_HIGH: begin
                    if(!cntrlr_pclk && dtc_ctr < 4'd8)    begin
                        dtc_state        =    DTC_RX_DATA_CLK_LOW;
                    end
                    if(!cntrlr_pclk && dtc_ctr >= 4'd8)    begin
                        dtc_value        =    dtc_rdata[4:0];
                            
                        //$display("Testing DTC memory acceptance addr:%d data:%b at time %t",dtc_addr_intl,dtc_rdata,$realtime);
                        dtc_state        =    DTC_LIMBO;
                    end
                    if(!cntrlr_nps)
                        dtc_state    =    DTC_IDLE;
                end
                DTC_LIMBO: begin    //Wait for fall of nps to determine a return to idle
                    if(!cntrlr_nps)
                        dtc_state    =    DTC_IDLE;
                end    
                default:    begin
                    dtc_state    =    DTC_IDLE;
                end
            endcase
        end
        end
endmodule