////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
// Bench : Test RX Chain: decimation filter and channel filter                    //
//                                                                                //
// Filename: test_rxchain.v                                                       //
// Creation Date: 11/27/2015                                                      //
// Author: Edward Keehr                                                           //
//                                                                                //
// Copyright Superlative Semiconductor LLC 2021                                   //
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2    //
// You may redistribute and modify this documentation and make products           //
// using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).       //
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED               //
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                   //
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2             //
// for applicable conditions.                                                     //
//                                                                                //
// Description:                                                                   //
//    Test the dec. and chnl. filter with the I/O waveforms obtained from MATLAB  //
//    Check for bit-exactness.                                                    //
//                                                                                //
//    Revisions:                                                                  //
//                                                                                //
//    072316 - Adapt to work with newer version of cic_8 which accepts data on    //
//    the negative clock edge.                                                    //
//    083021 - Replaced tabs with 4-spaces. Added copyright to header.            //
//    This file is out of date and was not re-run after cleanup for release, so   //
//    please temper expectations for use accordingly.                             //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////

`timescale    1ns/100ps
`define        NULL    0

module    test_rxchain();

    reg                         in_freq1;
    reg                         in_freq2;
    reg                         in_freq3;
    reg                         in_freq4;
    reg                         in_freq5;
    
    reg                         clk_36;
    reg                         clk_4p5;
    reg                         clk_0p035;
    reg                         load_first_data;
    
    reg                         rst_n;
    
    wire    signed    [15:0]    chfilt_out_freq1;
    wire    signed    [15:0]    dc_out_freq1;
    
    wire    signed    [15:0]    chfilt_out_freq2;
    wire    signed    [15:0]    dc_out_freq2;

    wire    signed    [15:0]    chfilt_out_freq3;
    wire    signed    [15:0]    dc_out_freq3;

    wire    signed    [15:0]    chfilt_out_freq4;
    wire    signed    [15:0]    dc_out_freq4;

    wire    signed    [15:0]    chfilt_out_freq5;
    wire    signed    [15:0]    dc_out_freq5;

    reg     signed    [12:0]    cic8_out_freq1_ideal;
    reg     signed    [15:0]    chfilt_out_freq1_ideal;
    reg     signed    [15:0]    dc_out_freq1_ideal;
    
    reg     signed    [12:0]    cic8_out_freq2_ideal;
    reg     signed    [15:0]    chfilt_out_freq2_ideal;
    reg     signed    [15:0]    dc_out_freq2_ideal;

    reg     signed    [12:0]    cic8_out_freq3_ideal;
    reg     signed    [15:0]    chfilt_out_freq3_ideal;
    reg     signed    [15:0]    dc_out_freq3_ideal;

    reg     signed    [12:0]    cic8_out_freq4_ideal;
    reg     signed    [15:0]    chfilt_out_freq4_ideal;
    reg     signed    [15:0]    dc_out_freq4_ideal;

    reg     signed    [12:0]    cic8_out_freq5_ideal;
    reg     signed    [15:0]    chfilt_out_freq5_ideal;
    reg     signed    [15:0]    dc_out_freq5_ideal;
    
    integer    i;

    integer    data_in_1_fid;
    integer    data_cic8_out_1_fid;
    integer    data_chfilt_out_1_fid;
    integer    data_dc_out_1_fid;
    
    integer    data_in_2_fid;
    integer    data_cic8_out_2_fid;
    integer    data_chfilt_out_2_fid;
    integer    data_dc_out_2_fid;
    
    integer    data_in_3_fid;
    integer    data_cic8_out_3_fid;
    integer    data_chfilt_out_3_fid;
    integer    data_dc_out_3_fid;
    
    integer    data_in_4_fid;
    integer    data_cic8_out_4_fid;
    integer    data_chfilt_out_4_fid;
    integer    data_dc_out_4_fid;
    
    integer    data_in_5_fid;
    integer    data_cic8_out_5_fid;
    integer    data_chfilt_out_5_fid;
    integer    data_dc_out_5_fid;

    integer    scan_in_1_rslt;
    integer    scan_cic8_out_1_rslt;
    integer    scan_chfilt_out_1_rslt;
    integer    scan_dc_out_1_rslt;
    
    integer    scan_in_2_rslt;
    integer    scan_cic8_out_2_rslt;
    integer    scan_chfilt_out_2_rslt;
    integer    scan_dc_out_2_rslt;
    
    integer    scan_in_3_rslt;
    integer    scan_cic8_out_3_rslt;
    integer    scan_chfilt_out_3_rslt;
    integer    scan_dc_out_3_rslt;
    
    integer    scan_in_4_rslt;
    integer    scan_cic8_out_4_rslt;
    integer    scan_chfilt_out_4_rslt;
    integer    scan_dc_out_4_rslt;
    
    integer    scan_in_5_rslt;
    integer    scan_cic8_out_5_rslt;
    integer    scan_chfilt_out_5_rslt;
    integer    scan_dc_out_5_rslt;

    integer    num_errors_chfilt_freq1;
    integer    num_errors_chfilt_freq2;
    integer    num_errors_chfilt_freq3;
    integer    num_errors_chfilt_freq4;
    integer    num_errors_chfilt_freq5;
    
    integer    num_errors_chfilt_total;
    
    integer    num_errors_dc_freq1;
    integer    num_errors_dc_freq2;
    integer    num_errors_dc_freq3;
    integer    num_errors_dc_freq4;
    integer    num_errors_dc_freq5;
    
    integer    num_errors_dc_total;

    parameter    CLK_36_HALF_PERIOD    =    (0.5e9)/(36e6);
    parameter    RST_DEASSERT_DLY      =    100;

//// Generate rst_n

    initial
        begin
            rst_n    =    1'b0;
            #RST_DEASSERT_DLY
            rst_n    =    1'b1;
        end
    
//// Generate clks. There are three clocks whose rising edges should all line up

    initial
        begin
            load_first_data    =    1'b0;
            clk_36             =    1'b0;
            clk_4p5            =    1'b0;
            clk_0p035          =    1'b0;
            #RST_DEASSERT_DLY
            #CLK_36_HALF_PERIOD;
            #CLK_36_HALF_PERIOD;
            load_first_data    =    1'b1;
            clk_36             =    1'b1;
            #CLK_36_HALF_PERIOD;
            for(i=0;i<131072;i=i+1)
                begin
                    clk_36=~clk_36;
                    if (i % 8 == 1)
                        clk_4p5=~clk_4p5;
                    if    (i % 1024 == 1)
                        clk_0p035=~clk_0p035;
                        
                    #CLK_36_HALF_PERIOD;
                end
        end
        
        
//// Initialize input variables

    initial
        begin
            num_errors_chfilt_freq1    =    0;
            num_errors_chfilt_freq2    =    0;
            num_errors_chfilt_freq3    =    0;
            num_errors_chfilt_freq4    =    0;
            num_errors_chfilt_freq5    =    0;
            
            num_errors_chfilt_total    =    0;
    
            num_errors_dc_freq1        =    0;
            num_errors_dc_freq2        =    0;
            num_errors_dc_freq3        =    0;
            num_errors_dc_freq4        =    0;
            num_errors_dc_freq5        =    0;
            
            num_errors_dc_total        =    0;
        end
        
/// Open data files

    initial
        begin
            data_in_1_fid            =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_in_loopf_1.dat","r");
            data_cic8_out_1_fid      =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_out_loopf_1.dat","r");
            data_chfilt_out_1_fid    =    $fopen("../../../octave_tb/rtl_test_vectors/chfilt_out_loopf_1.dat","r");
            data_dc_out_1_fid        =    $fopen("../../../octave_tb/rtl_test_vectors/dc_out_loopf_1.dat","r");
        
            if (data_in_1_fid == `NULL || data_cic8_out_1_fid == `NULL || data_chfilt_out_1_fid == `NULL || data_dc_out_1_fid == `NULL)
                begin
                    $display("One of the group 1 file handles was null");
                    $stop;
                end
                
            data_in_2_fid            =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_in_loopf_2.dat","r");
            data_cic8_out_2_fid      =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_out_loopf_2.dat","r");
            data_chfilt_out_2_fid    =    $fopen("../../../octave_tb/rtl_test_vectors/chfilt_out_loopf_2.dat","r");
            data_dc_out_2_fid        =    $fopen("../../../octave_tb/rtl_test_vectors/dc_out_loopf_2.dat","r");
        
            if (data_in_2_fid == `NULL || data_cic8_out_2_fid == `NULL || data_chfilt_out_2_fid == `NULL || data_dc_out_2_fid == `NULL)
                begin
                    $display("One of the group 2 file handles was null");
                    $stop;
                end
                
            data_in_3_fid            =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_in_loopf_3.dat","r");
            data_cic8_out_3_fid      =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_out_loopf_3.dat","r");
            data_chfilt_out_3_fid    =    $fopen("../../../octave_tb/rtl_test_vectors/chfilt_out_loopf_3.dat","r");
            data_dc_out_3_fid        =    $fopen("../../../octave_tb/rtl_test_vectors/dc_out_loopf_3.dat","r");
        
            if (data_in_3_fid == `NULL || data_cic8_out_3_fid == `NULL || data_chfilt_out_3_fid == `NULL || data_dc_out_3_fid == `NULL)
                begin
                    $display("One of the group 3 file handles was null");
                    $stop;
                end
                
            data_in_4_fid            =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_in_loopf_4.dat","r");
            data_cic8_out_4_fid      =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_out_loopf_4.dat","r");
            data_chfilt_out_4_fid    =    $fopen("../../../octave_tb/rtl_test_vectors/chfilt_out_loopf_4.dat","r");
            data_dc_out_4_fid        =    $fopen("../../../octave_tb/rtl_test_vectors/dc_out_loopf_4.dat","r");
                
            if (data_in_4_fid == `NULL || data_cic8_out_4_fid == `NULL || data_chfilt_out_4_fid == `NULL || data_dc_out_4_fid == `NULL)
                begin
                    $display("One of the group 4 file handles was null");
                    $stop;
                end
                
            data_in_5_fid            =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_in_loopf_5.dat","r");
            data_cic8_out_5_fid      =    $fopen("../../../octave_tb/rtl_test_vectors/cic8_out_loopf_5.dat","r");
            data_chfilt_out_5_fid    =    $fopen("../../../octave_tb/rtl_test_vectors/chfilt_out_loopf_5.dat","r");
            data_dc_out_5_fid        =    $fopen("../../../octave_tb/rtl_test_vectors/dc_out_loopf_5.dat","r");
                
            if (data_in_5_fid == `NULL || data_cic8_out_5_fid == `NULL || data_chfilt_out_5_fid == `NULL || data_dc_out_5_fid == `NULL)
                begin
                    $display("One of the group 5 file handles was null");
                    $stop;
                end
                
        end

//// Instantiate DUTs

rxchain    rxchain_freq1
    (
        // Inputs
        .in(in_freq1),
        .blank(1'b0),
        .clk_4p5(clk_4p5),
        .clk_36(clk_36),
        .rst_n(rst_n),
        // Outputs
        .chfilt_out(chfilt_out_freq1),
        .dc_out(dc_out_freq1),
        .in_posedge(),
        .dc_ready()
    );
    
rxchain    rxchain_freq2
    (
        // Inputs
        .in(in_freq2),
        .blank(1'b0),
        .clk_4p5(clk_4p5),
        .clk_36(clk_36),
        .rst_n(rst_n),
        // Outputs
        .chfilt_out(chfilt_out_freq2),
        .dc_out(dc_out_freq2),
        .in_posedge(),
        .dc_ready()
    );
    
rxchain    rxchain_freq3
    (
        // Inputs
        .in(in_freq3),
        .blank(1'b0),
        .clk_4p5(clk_4p5),
        .clk_36(clk_36),
        .rst_n(rst_n),
        // Outputs
        .chfilt_out(chfilt_out_freq3),
        .dc_out(dc_out_freq3),
        .in_posedge(),
        .dc_ready()
    );
    
rxchain    rxchain_freq4
    (
        // Inputs
        .in(in_freq4),
        .blank(1'b0),
        .clk_4p5(clk_4p5),
        .clk_36(clk_36),
        .rst_n(rst_n),
        // Outputs
        .chfilt_out(chfilt_out_freq4),
        .dc_out(dc_out_freq4),
        .in_posedge(),
        .dc_ready()
    );
    
rxchain    rxchain_freq5
    (
        // Inputs
        .in(in_freq5),
        .blank(1'b0),
        .clk_4p5(clk_4p5),
        .clk_36(clk_36),
        .rst_n(rst_n),
        // Outputs
        .chfilt_out(chfilt_out_freq5),
        .dc_out(dc_out_freq5),
        .in_posedge(),
        .dc_ready()
    );
    
////    At each clock cycle, apply data to the SDM and receive data out
////    Compare the data streams

    // data_in_1_fid
    // data_cic8_out_1_fid
    // data_chfilt_out_1_fid

    always @(posedge clk_36)
        begin
            scan_in_1_rslt    =    $fscanf(data_in_1_fid,"%d\n",in_freq1);
            scan_in_2_rslt    =    $fscanf(data_in_2_fid,"%d\n",in_freq2);
            scan_in_3_rslt    =    $fscanf(data_in_3_fid,"%d\n",in_freq3);
            scan_in_4_rslt    =    $fscanf(data_in_4_fid,"%d\n",in_freq4);
            scan_in_5_rslt    =    $fscanf(data_in_5_fid,"%d\n",in_freq5);
        
            if($feof(data_in_1_fid) || $feof(data_in_2_fid) || $feof(data_in_3_fid) || $feof(data_in_4_fid) || $feof(data_in_5_fid))
                begin
                    $display("Number of chfilt bit errors = %d\n",num_errors_chfilt_total);
                    $display("Number of dc bit errors = %d\n",num_errors_dc_total);
                    $stop;
                end
        end

    always @(posedge clk_4p5  or posedge load_first_data)
        begin
            scan_cic8_out_1_rslt      =    $fscanf(data_cic8_out_1_fid,"%d\n",cic8_out_freq1_ideal);
            scan_cic8_out_2_rslt      =    $fscanf(data_cic8_out_2_fid,"%d\n",cic8_out_freq2_ideal);
            scan_cic8_out_3_rslt      =    $fscanf(data_cic8_out_3_fid,"%d\n",cic8_out_freq3_ideal);
            scan_cic8_out_4_rslt      =    $fscanf(data_cic8_out_4_fid,"%d\n",cic8_out_freq4_ideal);
            scan_cic8_out_5_rslt      =    $fscanf(data_cic8_out_5_fid,"%d\n",cic8_out_freq5_ideal);
            
            scan_chfilt_out_1_rslt    =    $fscanf(data_chfilt_out_1_fid,"%d\n",chfilt_out_freq1_ideal);
            scan_chfilt_out_2_rslt    =    $fscanf(data_chfilt_out_2_fid,"%d\n",chfilt_out_freq2_ideal);
            scan_chfilt_out_3_rslt    =    $fscanf(data_chfilt_out_3_fid,"%d\n",chfilt_out_freq3_ideal);
            scan_chfilt_out_4_rslt    =    $fscanf(data_chfilt_out_4_fid,"%d\n",chfilt_out_freq4_ideal);
            scan_chfilt_out_5_rslt    =    $fscanf(data_chfilt_out_5_fid,"%d\n",chfilt_out_freq5_ideal);

            if($feof(data_cic8_out_1_fid) || $feof(data_cic8_out_2_fid) || $feof(data_cic8_out_3_fid) || $feof(data_cic8_out_4_fid) || $feof(data_cic8_out_5_fid))
                begin
                    $display("Number of chfilt bit errors = %d\n",num_errors_chfilt_total);
                    $display("Number of dc bit errors = %d\n",num_errors_dc_total);
                    $stop;
                end
            else if($feof(data_chfilt_out_1_fid) || $feof(data_chfilt_out_2_fid) || $feof(data_chfilt_out_3_fid) || $feof(data_chfilt_out_4_fid) || $feof(data_chfilt_out_5_fid))
                begin
                    $display("Number of chfilt bit errors = %d\n",num_errors_chfilt_total);
                    $display("Number of dc bit errors = %d\n",num_errors_dc_total);
                    $stop;
                end

        end
    
    always @(negedge clk_4p5)
        begin
            if(chfilt_out_freq1_ideal != chfilt_out_freq1)
                num_errors_chfilt_freq1=num_errors_chfilt_freq1+1;
            if(chfilt_out_freq2_ideal != chfilt_out_freq2)
                num_errors_chfilt_freq2=num_errors_chfilt_freq2+1;
            if(chfilt_out_freq3_ideal != chfilt_out_freq3)
                num_errors_chfilt_freq3=num_errors_chfilt_freq3+1;
            if(chfilt_out_freq4_ideal != chfilt_out_freq4)
                num_errors_chfilt_freq4=num_errors_chfilt_freq4+1;
            if(chfilt_out_freq5_ideal != chfilt_out_freq5)
                num_errors_chfilt_freq5=num_errors_chfilt_freq5+1;
    
            num_errors_chfilt_total=num_errors_chfilt_freq1+num_errors_chfilt_freq2+num_errors_chfilt_freq3+num_errors_chfilt_freq4+num_errors_chfilt_freq5;
        end
            
    
    always @(posedge clk_0p035)
        begin
            scan_dc_out_1_rslt        =    $fscanf(data_dc_out_1_fid,"%d\n",dc_out_freq1_ideal);
            scan_dc_out_2_rslt        =    $fscanf(data_dc_out_2_fid,"%d\n",dc_out_freq2_ideal);
            scan_dc_out_3_rslt        =    $fscanf(data_dc_out_3_fid,"%d\n",dc_out_freq3_ideal);
            scan_dc_out_4_rslt        =    $fscanf(data_dc_out_4_fid,"%d\n",dc_out_freq4_ideal);
            scan_dc_out_5_rslt        =    $fscanf(data_dc_out_5_fid,"%d\n",dc_out_freq5_ideal);
        
            if($feof(data_dc_out_1_fid) || $feof(data_dc_out_2_fid) || $feof(data_dc_out_3_fid) || $feof(data_dc_out_4_fid) || $feof(data_dc_out_5_fid))
                begin
                    $display("Number of chfilt bit errors = %d\n",num_errors_chfilt_total);
                    $display("Number of dc bit errors = %d\n",num_errors_dc_total);
                    $stop;
                end

        end

    always @(negedge clk_0p035)
        begin
            if(dc_out_freq1_ideal != dc_out_freq1)
                num_errors_dc_freq1=num_errors_dc_freq1+1;
            if(dc_out_freq2_ideal != dc_out_freq2)
                num_errors_dc_freq2=num_errors_dc_freq2+1;
            if(dc_out_freq3_ideal != dc_out_freq3)
                num_errors_dc_freq3=num_errors_dc_freq3+1;
            if(dc_out_freq4_ideal != dc_out_freq4)
                num_errors_dc_freq4=num_errors_dc_freq4+1;
            if(dc_out_freq5_ideal != dc_out_freq5)
                num_errors_dc_freq5=num_errors_dc_freq5+1;
                        
            num_errors_dc_total=num_errors_dc_freq1+num_errors_dc_freq2+num_errors_dc_freq3+num_errors_dc_freq4+num_errors_dc_freq5;
        end
        
endmodule
    