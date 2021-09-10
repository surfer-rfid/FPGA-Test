/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : SX1257 RX and TAG BFM                                                     //
//                                                                                     //
// Filename: sx1257_rx_and_tag_bfm.v                                                   //
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
//    This file is intended to act as the top level BFM for the SX1257 and elements    //
//    associated with the SX1257 receiver.                                             //
//                                                                                     //
//    This task at the moment takes the following from file:                           //
//    Analog baseband RX tag and TX reflection waveforms prior to SDM.                 //
//    Reflection coefficient matrix.                                                   //
//                                                                                     //
//    091016 - File created                                                            //
//    101017 - Update for better SX1257 modeling                                       //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

`timescale     1ns/100ps
`define        NULL    0

module    sx1257_rx_and_tag_bfm
    (
        input    wire        is_radio_running,
        input    wire        cntrlr_nps_rdio,
        input    wire        cntrlr_nps_dtc,
        input    wire        cntrlr_pclk,
        input    wire        cntrlr_copi_cap3,
        input    wire        cntrlr_copi_cap2,
        input    wire        cntrlr_copi_cap1,
        input    wire        cntrlr_copi_cap0_rdio,
        output   reg         sx1257_clk,
        output   wire        sx1257_out_i,
        output   wire        sx1257_out_q,
        output   wire        cntrlr_cipo_sx1257_drive,
        output   wire        cntrlr_cipo_sx1257_out
    );
    
    localparam    CLK_36_HALF_PERIOD        =    (0.5e9)/(36e6);
    
    real              tx_i, tx_q, rx_i, rx_q, u_i, u_q, u_i_temp, u_q_temp;
    real              tx_net_refl_coeff_r, tx_net_refl_coeff_i, lna_gain, bb_gain, lna_out_sat_level;
    wire    [63:0]    tx_net_refl_coeff_r_bits, tx_net_refl_coeff_i_bits, lna_gain_bits;
    wire    [4:0]     dtc_value_0, dtc_value_1, dtc_value_2, dtc_value_3;
    integer           data_in_fid, scan_in_rslt;
    
    sx1257_rx_and_tag_tx_refl_coeff    sx1257_rx_and_tag_tx_refl_coeff_0
    (
        .target_refl_coeff_r_bits($realtobits(0.1125)),
        .target_refl_coeff_i_bits($realtobits(-0.194855715852)),
        //.cos_tx_lkg_rot_angle_bits($realtobits(-0.656059028991)),
        //.sin_tx_lkg_rot_angle_bits($realtobits(-0.754709580223)),
        .cos_tx_lkg_rot_angle_bits($realtobits(1.000)), //Changed 112617
        .sin_tx_lkg_rot_angle_bits($realtobits(0.000)),
        .dtc_value_0(dtc_value_0),
        .dtc_value_1(dtc_value_1),
        .dtc_value_2(dtc_value_2),
        .dtc_value_3(dtc_value_3),
        .tx_net_refl_coeff_r_bits(tx_net_refl_coeff_r_bits),
        .tx_net_refl_coeff_i_bits(tx_net_refl_coeff_i_bits)
    );
    
    sx1257_rx_and_tag_sdm_bfm    sx1257_rx_and_tag_sdm_bfm_0
    (
        .u_i_bits($realtobits(u_i)),
        .u_q_bits($realtobits(u_q)),
        .sx1257_clk(sx1257_clk),
        .sx1257_out_i(sx1257_out_i),
        .sx1257_out_q(sx1257_out_q)
    );
    
    sx1257_rx_and_tag_sx1257_spi_bfm    sx1257_rx_and_tag_sx1257_spi_bfm_0
    (
        .cntrlr_nps_rdio(cntrlr_nps_rdio),
        .cntrlr_pclk(cntrlr_pclk),
        .cntrlr_copi(cntrlr_copi_cap0_rdio),
        .sx1257_clk(sx1257_clk),
        .cntrlr_cipo_sx1257_drive(cntrlr_cipo_sx1257_drive),
        .cntrlr_cipo_sx1257_out(cntrlr_cipo_sx1257_out),
        .lna_gain_bits(lna_gain_bits)
    );
    
    sx1257_rx_and_tag_dtc_spi_bfm    sx1257_rx_and_tag_dtc_spi_bfm_0
    (
        .cntrlr_nps(cntrlr_nps_dtc),
        .cntrlr_pclk(cntrlr_pclk),
        .cntrlr_copi(cntrlr_copi_cap0_rdio),
        .dtc_value(dtc_value_0)
    );
    
    sx1257_rx_and_tag_dtc_spi_bfm    sx1257_rx_and_tag_dtc_spi_bfm_1
    (
        .cntrlr_nps(cntrlr_nps_dtc),
        .cntrlr_pclk(cntrlr_pclk),
        .cntrlr_copi(cntrlr_copi_cap1),
        .dtc_value(dtc_value_1)
    );
    
    sx1257_rx_and_tag_dtc_spi_bfm    sx1257_rx_and_tag_dtc_spi_bfm_2
    (
        .cntrlr_nps(cntrlr_nps_dtc),
        .cntrlr_pclk(cntrlr_pclk),
        .cntrlr_copi(cntrlr_copi_cap2),
        .dtc_value(dtc_value_2)
    );
    
    sx1257_rx_and_tag_dtc_spi_bfm    sx1257_rx_and_tag_dtc_spi_bfm_3
    (
        .cntrlr_nps(cntrlr_nps_dtc),
        .cntrlr_pclk(cntrlr_pclk),
        .cntrlr_copi(cntrlr_copi_cap3),
        .dtc_value(dtc_value_3)
    );
    
    always @(*) begin
    
        tx_net_refl_coeff_r    =    $bitstoreal(tx_net_refl_coeff_r_bits);
        tx_net_refl_coeff_i    =    $bitstoreal(tx_net_refl_coeff_i_bits);
        lna_gain               =    $bitstoreal(lna_gain_bits);
    
    end
    
    initial    begin
        data_in_fid            =    $fopen("../../../octave_tb/rtl_test_vectors/rfidr_top_input_112617.dat","r");
                
        if (data_in_fid == `NULL)    begin
            $display("Error: ASCII data file containing baseband equivalent signals could not be opened at time $t",$realtime);
            $stop;
        end
        
        u_i_temp    =    0.0000000000000;
        u_q_temp    =    0.0000000000000;
        u_i         =    0.0000000000000;
        u_q         =    0.0000000000000;
        
    end
    
    initial begin
            sx1257_clk    =    1'b0;
    
        forever    begin
            #CLK_36_HALF_PERIOD
            sx1257_clk=~sx1257_clk;
        end
    end
    
    always @(posedge sx1257_clk)    begin
        if(is_radio_running)    begin
            if($ftell(data_in_fid) != -1)    begin
                scan_in_rslt        =    $fscanf(data_in_fid,"%f %f %f %f\n",rx_i,rx_q,tx_i,tx_q);
                if(scan_in_rslt == 0) begin
                    $display("Scan of SX1257 baseband input data failed at time $t",$realtime);
                    $stop;
                end
            end else begin
                rx_i    =    rx_i;
                rx_q    =    rx_q;
                tx_i    =    tx_i;
                tx_q    =    tx_q;
            end
        end    else    begin
            rx_i    =    0.0000000000000;
            rx_q    =    0.0000000000000;
            tx_i    =    0.0000000000000;
            tx_q    =    0.0000000000000;
        end
        
        lna_out_sat_level    =    0.036307805477;
        bb_gain              =    14.1253754462;
        
        u_i_temp=lna_gain*((tx_i*tx_net_refl_coeff_r-tx_q*tx_net_refl_coeff_i)+rx_i);
        u_q_temp=lna_gain*((tx_i*tx_net_refl_coeff_i+tx_q*tx_net_refl_coeff_r)+rx_q);
        
        if(u_i_temp*u_i_temp+u_q_temp*u_q_temp > lna_out_sat_level*lna_out_sat_level) begin
            u_i=lna_out_sat_level*bb_gain;
            u_q=0;
        end else begin
            u_i=u_i_temp*bb_gain;
            u_q=u_q_temp*bb_gain;
        end
    end
    
endmodule