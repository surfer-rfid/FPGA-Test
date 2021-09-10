//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
// Bench : Test sigma-delta modulator for TX data                                   //
//                                                                                  //
// Filename: test_tx_sdm.v                                                          //
// Creation Date: 11/24/2015                                                        //
// Author: Edward Keehr                                                             //
//                                                                                  //
// Copyright Superlative Semiconductor LLC 2021                                     //
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2      //
// You may redistribute and modify this documentation and make products             //
// using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).         //
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED                 //
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                     //
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2               //
// for applicable conditions.                                                       //
//                                                                                  //
// Description:                                                                     //
//    Test the sigma delta modulator with the I/O waveforms obtained from MATLAB    //
//    Check for bit-exactness.                                                      //
//                                                                                  //
//    Revisions:                                                                    //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.              //
//    This file is out of date and was not re-run after cleanup for release, so     //
//    please temper expectations for use accordingly.                               //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

//// Module, signal, and parameter declarations

`timescale 1ns/100ps
`define NULL 0

module test_tx_sdm();

    reg        in;
    reg        clk;
    reg        rst_n;
    wire       out;
    reg        out_ideal;
    reg        lfsr_ideal;

    integer    i;

    integer    data_in_fid;
    integer    data_out_fid;
    integer    data_lfsr_fid;

    integer    scan_in_rslt;
    integer    scan_out_rslt;
    integer    scan_lfsr_rslt;

    integer    num_errors;

    parameter    CLK_HALF_PERIOD     =    (0.5e9)/(36e6);
    parameter    RST_DEASSERT_DLY    =    100;
    
//// Generate rst_n

    initial
        begin
            rst_n    =    1'b0;
            #RST_DEASSERT_DLY
            rst_n    =    1'b1;
        end
    
//// Generate clk

    initial
        begin
            clk    =    1'b1;
            #RST_DEASSERT_DLY
            for(i=0;i<688000;i=i+1)
                begin
                    #CLK_HALF_PERIOD
                    clk=~clk;
                end
        end
    
//// Initialize input variables

    initial
        begin
            num_errors    =    0;
        end
    
/// Open data files

    initial
        begin
            data_in_fid      =    $fopen("../../../octave_tb/rtl_test_vectors/tx_sdm_in.dat","r");
            data_out_fid     =    $fopen("../../../octave_tb/rtl_test_vectors/tx_sdm_out.dat","r");
            data_lfsr_fid    =    $fopen("../../../octave_tb/rtl_test_vectors/tx_sdm_lfsr.dat","r");
        
            if (data_in_fid == `NULL)
                begin
                    $display("data_in_fid handle was null");
                    $finish;
                end
        
            if (data_out_fid == `NULL)
                begin
                    $display("data_out_fid handle was null");
                    $finish;
                end    
            
            if (data_lfsr_fid == `NULL)
                begin
                    $display("data_lfsr_fid handle was null");
                    $finish;
                end
                
        end
    
//// Instantiate DUT

    tx_sdm            dut
        (
            .in           (in),
            .clk          (clk),
            .rst_n        (rst_n),
            .clk_out      (clk),
            .rst_n_out    (rst_n),
            .out          (out)
        );
    
////    At each clock cycle, apply data to the SDM and receive data out
////    Compare the data streams

//integer         data_in_fid;
//integer         data_out_fid;
//integer         scan_in_rslt;
//integer         scan_out_rslt;

    always @(negedge clk)
        begin
            scan_in_rslt    =    $fscanf(data_in_fid,"%d\n",in);
        
            if(!$feof(data_in_fid))
                begin
                    if(out_ideal != out)
                        num_errors=num_errors+1;
                end
            else
                begin
                    $display("Number of bit errors = %d",num_errors);
                    $finish;
                end
        
        end

    always @(posedge clk)
        begin
            scan_out_rslt     =    $fscanf(data_out_fid,"%d\n",out_ideal);
            scan_lfsr_rslt    =    $fscanf(data_lfsr_fid,"%d\n",lfsr_ideal);
        
            if($feof(data_out_fid) || $feof(data_lfsr_fid))
                begin
                    $display("Number of bit errors = %d",num_errors);
                    $finish;
                end
        end    
endmodule
    