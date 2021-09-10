/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : SX1257 RX and TAG TX reflection coefficient sub BFM                       //
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
//    This file takes the antenna reflection coefficient and the four                  //
//    DTC control values of the tunable microwave network and                          //
//    generates a complex gain by which to multiply the DC signal                      //
//                                                                                     //
//    Note that Verilog does not inherently process imaginary numbers                  //
//    like Matlab, so we will need to handle real and imaginary                        //
//    components of the values separately.                                             //
//                                                                                     //
//    091016 - File created                                                            //
//    101017 - Updated for final tests.                                                //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

`define        NULL    0

module    sx1257_rx_and_tag_tx_refl_coeff
    (
        input    wire    [63:0]    target_refl_coeff_r_bits,
        input    wire    [63:0]    target_refl_coeff_i_bits,
        input    wire    [63:0]    cos_tx_lkg_rot_angle_bits,
        input    wire    [63:0]    sin_tx_lkg_rot_angle_bits,
        input    reg     [4:0]     dtc_value_0,
        input    reg     [4:0]     dtc_value_1,
        input    reg     [4:0]     dtc_value_2,
        input    reg     [4:0]     dtc_value_3,
        output   wire    [63:0]    tx_net_refl_coeff_r_bits,
        output   wire    [63:0]    tx_net_refl_coeff_i_bits
    );
    
    integer    loop_a, loop_b, loop_c, loop_d;
    integer    scan_out_rslt;
    integer    data_in_fid;

    real    tmn_refl_coeff_r    [0:31][0:31][0:31][0:31];
    real    tmn_refl_coeff_i    [0:31][0:31][0:31][0:31];
    real    target_refl_coeff_r, target_refl_coeff_i, cos_tx_lkg_rot_angle, sin_tx_lkg_rot_angle;
    real    tx_net_refl_coeff_r, tx_net_refl_coeff_i;
    real    residual_refl_coeff_r, residual_refl_coeff_i;
        
    assign    tx_net_refl_coeff_r_bits    =    $realtobits(tx_net_refl_coeff_r);
    assign    tx_net_refl_coeff_i_bits    =    $realtobits(tx_net_refl_coeff_i);
    
    initial    begin
    
        //Load the array describing the tunable microwave network reflection coefficient as a function of dtc value
    
        data_in_fid        =    $fopen("../../../octave_tb/rtl_test_vectors/nw082117_simple_qucs_ascii.dat","r");
        
        if (data_in_fid == `NULL)    begin
            $display("Error: ASCII data file containing tunable microwave network information could not be opened at time %t",$realtime);
            $stop;
        end
        
        for(loop_a=0;loop_a < 32;loop_a=loop_a+1)    begin
            for(loop_b=0;loop_b < 32;loop_b=loop_b+1)    begin
                for(loop_c=0;loop_c < 32;loop_c=loop_c+1)    begin
                    for(loop_d=0;loop_d < 32;loop_d=loop_d+1)    begin
                        //As written below, this is an illegal reference to a real variable
                        scan_out_rslt    =    $fscanf(data_in_fid,"%f %f\n",tmn_refl_coeff_r[loop_a][loop_b][loop_c][loop_d],tmn_refl_coeff_i[loop_a][loop_b][loop_c][loop_d]);
                        //$display("%2.6f %2.6f",tmn_refl_coeff_r[loop_a][loop_b][loop_c][loop_d],tmn_refl_coeff_i[loop_a][loop_b][loop_c][loop_d]);
                        
                        if(loop_a == 7 && loop_b == 16 && loop_c == 5 && loop_d == 28) begin
                            $display("Loaded value r = %1.12f, i=%1.12f at time %t",tmn_refl_coeff_r[loop_a][loop_b][loop_c][loop_d],tmn_refl_coeff_i[loop_a][loop_b][loop_c][loop_d],$realtime);
                        end
                        
                        if(loop_a == 4 && loop_b == 31 && loop_c == 8 && loop_d == 19) begin
                            $display("Loaded value r = %1.12f, i=%1.12f at time %t",tmn_refl_coeff_r[loop_a][loop_b][loop_c][loop_d],tmn_refl_coeff_i[loop_a][loop_b][loop_c][loop_d],$realtime);
                        end
                        
                        if (scan_out_rslt == 0)    begin
                            $display("Error: ASCII data file containing tunable microwave network information could not be read at time %t",$realtime);
                            $stop;
                        end
                    end
                end
            end
        end
        
        $fclose(data_in_fid);
    
    end
    
    always@(*)    begin
        //target_refl_coeff_r     =    $bitstoreal(target_refl_coeff_r_bits);
        //target_refl_coeff_i     =    $bitstoreal(target_refl_coeff_i_bits);
        //cos_tx_lkg_rot_angle    =    $bitstoreal(cos_tx_lkg_rot_angle_bits);
        //sin_tx_lkg_rot_angle    =    $bitstoreal(sin_tx_lkg_rot_angle_bits);
        target_refl_coeff_r       =    0.1125;
        target_refl_coeff_i       =    -0.194855715852;
        //cos_tx_lkg_rot_angle    =    -0.656059028991;
        //sin_tx_lkg_rot_angle    =    -0.754709580223;
        cos_tx_lkg_rot_angle      =    1.000; //Changed 112617
        sin_tx_lkg_rot_angle      =    0.000;
        
        //We had this before: it worked (badly), but it was wrong!!!!!
        //tx_net_refl_coeff_r     =    cos_tx_lkg_rot_angle*(tmn_refl_coeff_r[dtc_value_0][dtc_value_1][dtc_value_2][dtc_value_3] - target_refl_coeff_r);
        //tx_net_refl_coeff_i     =    sin_tx_lkg_rot_angle*(tmn_refl_coeff_i[dtc_value_0][dtc_value_1][dtc_value_2][dtc_value_3] - target_refl_coeff_i);
        
        residual_refl_coeff_r     =    (tmn_refl_coeff_r[dtc_value_0][dtc_value_1][dtc_value_2][dtc_value_3] - target_refl_coeff_r);
        residual_refl_coeff_i     =    (tmn_refl_coeff_i[dtc_value_0][dtc_value_1][dtc_value_2][dtc_value_3] - target_refl_coeff_i);
        
        tx_net_refl_coeff_r       =    cos_tx_lkg_rot_angle*residual_refl_coeff_r-sin_tx_lkg_rot_angle*residual_refl_coeff_i;
        tx_net_refl_coeff_i       =    sin_tx_lkg_rot_angle*residual_refl_coeff_r+cos_tx_lkg_rot_angle*residual_refl_coeff_i;
    end
endmodule