//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
// Bench : Test CDR - test the clock and data recovery system by itself         //
//                                                                              //
// Filename: test_cdr.v                                                         //
// Creation Date: 12/7/2015                                                     //
// Author: Edward Keehr                                                         //
//                                                                              //
// Copyright Superlative Semiconductor LLC 2021                                 //
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2  //
// You may redistribute and modify this documentation and make products         //
// using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).     //
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED             //
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                 //
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2           //
// for applicable conditions.                                                   //
//                                                                              //
// Description:                                                                 //
//    Test the clock and data recovery circuit using a number of stimuli waves  //
//    obtained from Octave (Big waves, little waves, saturating waves). Check   //
// contents of the destination SRAM to see if they indeed match Octave results  //
//                                                                              //
//    Revisions:                                                                //
//    072416 - Cleaned up for verification after LUT-reducing binge.            //
//    083021 - Replaced tabs with 4-spaces. Added copyright to header.          //
//    This file is out of date and was not re-run after cleanup for release, so //
//    please temper expectations for use accordingly.                           //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

// This should run for about 20,000,000,000 ps

`timescale    1ns/100ps
`define        NULL    0

module test_cdr();

    // Registers used to drive the CDR
    reg    signed    [15:0]    in_i;
    reg    signed    [15:0]    in_q;
    reg                        sample_i_ideal;
    reg                        sample_q_ideal;
    reg              [7:0]     sram_byte_ideal;
    reg                        clk_cdr;
    reg                        rst_n;
    reg              [4:0]     radio_state;
    reg                        go;
    // Registers used to drive the SPI side of the SRAM
    reg              [9:0]     sram_address_fromspi;
    reg                        clk_spi;
    reg              [7:0]     sram_data_fromspi;
    reg                        sram_wren_fromspi;
    // Wires from SRAM which contain the data we need to examine
    wire             [7:0]     sram_data_tospi;
    wire                       done;
    wire                       bit_decision;
    wire                       shift_rn16;
    wire                       shift_handle;
    
    // Integers which hold file handles
    
    integer                    data_in_fid;
    integer                    data_out_fid;
    integer                    scan_in_rslt;
    integer                    scan_out_rslt;
    
    // Integers to act as error counters
    
    integer                    num_errors_sample;
    integer                    num_errors_sram_byte;
    integer                    sim_pass_top;
    integer                    phs_int;
    integer                    mag_int;
    integer                    freq_int;
    
    // Clock Parameters
    
    parameter    CLK_CDR_HALF_PERIOD    =    (0.5e9)/(4.5e6);
    parameter    CLK_SPI_HALF_PERIOD    =    (0.5e9)/(27.5e6);
    parameter    RST_DEASSERT_DLY       =    100;
    
    // Run the clocks
    
    initial    begin
        clk_cdr        =    1'b0;
        #RST_DEASSERT_DLY
        forever 
            begin
                #CLK_CDR_HALF_PERIOD;
                clk_cdr=~clk_cdr;
            end
    end
    
    initial begin
        clk_spi        =    1'b0;
        #RST_DEASSERT_DLY
                
        forever 
            begin
                #CLK_SPI_HALF_PERIOD;
                clk_spi=~clk_spi;
            end    
    end
    
    initial begin
        rst_n            =    1'b0;
        #RST_DEASSERT_DLY
        rst_n            =    1'b1;
    end
    
    //Run an example task
    initial begin
        sim_pass_top    =    1'b0;            //Set this to zero until we see that everything is all right
        run_sim(51,1,214300,sim_pass_top);
        $stop;
    end

    initial
        begin
            in_i              =    16'sd0;
            in_q              =    16'sd0;
            sample_i_ideal    =    1'b0;
            sample_q_ideal    =    1'b0;
            radio_state       =    5'b0;
            go                =    1'b0;
        end
    
//    Have the bulk of the simulation in a task which takes one stimulus file
//    and compares it with the outputs of the RAM

    task    run_sim (
            input    [5:0]        mag,
            input    [8:0]        phs,
            input    [18:0]       freq,
            output                sim_pass
    );
    
    begin
    
    mag_int=mag;
    phs_int=phs;
    freq_int=freq;
    
    //// Initial block for opening data files

    data_in_fid    =    $fopen($psprintf("../../../MATLAB-Octave-Test/rtl_test_vectors/test_cdr_amp_m%0ddB_phs_%0ddeg_freq_%0d_in.dat",mag_int,phs_int,freq_int),"r");

    if (data_in_fid == `NULL) begin
        $display("The input file handle came back as NULL");
        $stop;
    end
    
    //// Initialize simulation integer error counters, also the SPI side of the SRAM

    sram_address_fromspi    =    0;
    sram_wren_fromspi       =    0;
    sram_data_fromspi       =    0;
    num_errors_sample       =    0;
    num_errors_sram_byte    =    0;
    sim_pass                =    0;    // Set this to 1 when we see that everything is OK
    
    //// Load packet lengths into the SRAM
    //// For this test we do something a bit concocted - we do a Req_RN tag return as oppsed to a Query tag return
    //// Also recall that we need to run the address
    
    @(posedge clk_spi);
        sram_address_fromspi=10'b1_00000_0000;    //Address for where RN16 packet # bits will be located, starting address for RN16 packet information.
    @(posedge clk_spi);
        sram_data_fromspi=8'd32;
        sram_wren_fromspi=1'b1;
    @(posedge clk_spi);
        sram_wren_fromspi=1'b0;
    @(posedge clk_spi);
        sram_address_fromspi=10'b1_00111_0000;    //Address for where PCEPC packet # bits will be located, starting address for PCEPC packet information.
    @(posedge clk_spi);
        sram_data_fromspi=8'd128;
        sram_wren_fromspi=1'b1;
    @(posedge clk_spi);
        sram_wren_fromspi=1'b0;
    @(posedge clk_spi);
        sram_address_fromspi=10'b1_00000_0000;
    @(posedge clk_spi);
        sram_data_fromspi=8'd0;
        sram_wren_fromspi=1'b0;
    @(posedge clk_spi);
    
    //// Read out data from input file
    
    while (!$feof(data_in_fid)) begin
        @(posedge clk_cdr);
        scan_in_rslt    =    $fscanf(data_in_fid,"%d %d %d %d %d %d\n",in_i,in_q,sample_i_ideal,sample_q_ideal,radio_state,go);
        @(negedge clk_cdr);
        if(sample_i_ideal != dut_cdr_sram.dut_cdr.sample)
            num_errors_sample=num_errors_sample+1;
    end
    
    $fclose(data_in_fid);
    //// Done with input file, let's check out the errors    
    
    $display("Number of sample errors for this file = %d\n",num_errors_sample);

    //// Deal with the SRAM now
    
    data_out_fid     =    $fopen($psprintf("../../../MATLAB-Octave-Test/rtl_test_vectors/test_cdr_amp_m%0ddB_phs_%0ddeg_freq_%0d_out.dat",mag,phs,freq),"r");

    if (data_out_fid == `NULL) begin
        $display("The output file for handle %d came back as NULL",data_out_fid);
        $stop;
    end
    
    sram_address_fromspi    =    10'b1_00000_0000;    //Start reading from the beginning of RX addresses. Maybe make this address a variable?        
    
    while (!$feof(data_out_fid)) begin
        @(posedge clk_spi);
            scan_out_rslt           =    $fscanf(data_out_fid,"%d\n",sram_byte_ideal);
            sram_address_fromspi    =    sram_address_fromspi+1;
        @(negedge clk_spi);
            if(sram_byte_ideal != sram_data_tospi)
                num_errors_sram_byte=num_errors_sram_byte+1;
    end
    
    $fclose(data_out_fid);
    $display("Number of sram errors for this file handle = %d\n",num_errors_sram_byte);
    sim_pass    =    !(num_errors_sample+num_errors_sram_byte);
    
    end
    endtask
    
// Instantiate DUTs

cdr_top_w_sram_test_only    dut_cdr_sram (
        // Inputs
        .in_i(in_i),
        .in_q(in_q),
        .use_i(1'b1),
        .clk_cdr(clk_cdr),
        .clk_spi(clk_spi),
        .rst_n(rst_n),
        .radio_state(radio_state),
        .go(go),
        .sram_address_fromspi(sram_address_fromspi),
        .sram_data_fromspi(sram_data_fromspi),
        .sram_wren_fromspi(sram_wren_fromspi),
        // Outputs
        .bit_decision(bit_decision),
        .done(done),
        .shift_rn16(shift_rn16),
        .shift_handle(shift_handle),
        .sram_data_tospi(sram_data_tospi)
);
    
endmodule
