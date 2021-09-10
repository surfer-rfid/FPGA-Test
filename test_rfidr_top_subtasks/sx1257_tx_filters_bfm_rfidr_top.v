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
//    This task allows us to filter out both the I and Q SDM outputs                   //
//    using models of the filters found in the SX1257. Eventually we                   //
//    will use the results of this BFM to automatically check that                     //
//    the SDM output closely follows the TX_GEN output, but for now                    //
//    we will settle on a visual comparison.                                           //
//                                                                                     //
//    Make this a module because we have it open and because we                        //
//    should reduce our reliance on tasks that grab lots of global                     //
//    variables.                                                                       //
//                                                                                     //
//    091016 - File created                                                            //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

module    sx1257_tx_filters_bfm_rfidr_top(
    input     wire              out_i_extl,
    input     wire              out_q_extl,
    input     wire              clk_36_extl,
    output    wire    [63:0]    tx_iir_i_out_bits,
    output    wire    [63:0]    tx_iir_q_out_bits
);

    localparam    b0    =    0.00000585170803465818;
    localparam    b1    =    0.0000175551241039745;
    localparam    b2    =    0.0000175551241039745;
    localparam    b3    =    0.00000585170803465818;

    localparam    a1    =    -2.927049277100162;
    localparam    a2    =    2.856735212941799;
    localparam    a3    =    -0.929639122177360;

    real       fir_i_shift_reg [0:63];
    real       fir_q_shift_reg [0:63];

    real       fir_i_out;
    real       fir_q_out;

    real       tx_iir_b_i [0:3];
    real       tx_iir_a_i [0:3];

    real       tx_iir_b_q [0:3];
    real       tx_iir_a_q [0:3];
    
    real       tx_iir_i_out;
    real       tx_iir_q_out;

    integer    loop_init;
    
    assign     tx_iir_i_out_bits    =    $realtobits(tx_iir_i_out);
    assign     tx_iir_q_out_bits    =    $realtobits(tx_iir_q_out);

    initial begin
    
        //Initialize reals
    
        for(loop_init=0; loop_init < 64; loop_init=loop_init+1)    begin
            fir_i_shift_reg[loop_init]    =    0.0;
            fir_q_shift_reg[loop_init]    =    0.0;
        end
    
        for(loop_init=0; loop_init < 4; loop_init=loop_init+1)    begin
            tx_iir_b_i[loop_init]        =    0.0;
            tx_iir_b_q[loop_init]        =    0.0;
        end
    
        for(loop_init=0; loop_init < 4; loop_init=loop_init+1)    begin
            tx_iir_a_i[loop_init]        =    0.0;
            tx_iir_a_q[loop_init]        =    0.0;
        end
    
        fir_i_out    =    0.0;
        fir_q_out    =    0.0;
    end
    
    always @(negedge clk_36_extl)    begin
        for(loop_init=63; loop_init > 0; loop_init=loop_init-1)    begin
            fir_i_shift_reg[loop_init]    =    fir_i_shift_reg[loop_init-1];
            fir_q_shift_reg[loop_init]    =    fir_q_shift_reg[loop_init-1];
        end
            
        fir_i_shift_reg[0]    =    out_i_extl ? 1.0 : -1.0;
        fir_q_shift_reg[0]    =    out_q_extl ? 1.0 : -1.0;

        fir_i_out    =    0.0;
        fir_q_out    =    0.0;
            
        for(loop_init=0; loop_init < 64; loop_init=loop_init+1)    begin
            fir_i_out    =    fir_i_out+0.015625*fir_i_shift_reg[loop_init];
            fir_q_out    =    fir_q_out+0.015625*fir_q_shift_reg[loop_init];
        end
            
        for(loop_init=3; loop_init > 0; loop_init=loop_init-1)    begin
            tx_iir_b_i[loop_init]    =    tx_iir_b_i[loop_init-1];
            tx_iir_b_q[loop_init]    =    tx_iir_b_q[loop_init-1];
        end
    
        tx_iir_b_i[0]    =    fir_i_out;
        tx_iir_b_q[0]    =    fir_q_out;
            
        for(loop_init=3; loop_init > 0; loop_init=loop_init-1)    begin
            tx_iir_a_i[loop_init]    =    tx_iir_a_i[loop_init-1];
            tx_iir_a_q[loop_init]    =    tx_iir_a_q[loop_init-1];
        end
    
        tx_iir_a_i[0]    =    -a1*tx_iir_a_i[1]-a2*tx_iir_a_i[2]-a3*tx_iir_a_i[3]+b0*tx_iir_b_i[0]+b1*tx_iir_b_i[1]+b2*tx_iir_b_i[2]+b3*tx_iir_b_i[3];
        tx_iir_a_q[0]    =    -a1*tx_iir_a_q[1]-a2*tx_iir_a_q[2]-a3*tx_iir_a_q[3]+b0*tx_iir_b_q[0]+b1*tx_iir_b_q[1]+b2*tx_iir_b_q[2]+b3*tx_iir_b_q[3];
    
        tx_iir_i_out    =    tx_iir_a_i[0];
        tx_iir_q_out    =    tx_iir_a_q[0];
    end    
endmodule