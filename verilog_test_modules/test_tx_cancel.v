/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
// Bench : Test TX Cancel - Test the TX cancellation by itself                     //
//                                                                                 //
// Filename: test_tx_cancel.v                                                      //
// Creation Date: 12/29/2015                                                       //
// Author: Edward Keehr                                                            //
//                                                                                 //
// Copyright Superlative Semiconductor LLC 2021                                    //
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2     //
// You may redistribute and modify this documentation and make products            //
// using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).        //
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED                //
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                    //
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2              //
// for applicable conditions.                                                      //
//                                                                                 //
// Description:                                                                    //
//                                                                                 //
// This file takes input/output vectors from the 'top level' Octave simulation     //
// so that we can just test the TX cancellation. We model the action of the        //
// SPI controller engine with code.                                                //
//                                                                                 //
//    Revisions:                                                                   //
//    071616 - Revise this to work with new rotationally nonblind convergence      //
//    algorithm                                                                    //
//    091816 - Adjust file to reflect now interface between tx cancel and spi      //
//    082821 - Changed references to txcancel in/out files to 112617 versions.     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.             //
//    This file is out of date and was not re-run after cleanup for release, so    //
//    please temper expectations for use accordingly.                              //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////

`timescale    1ns/100ps
`define       NULL    0

module test_tx_cancel();
    
    // Registers used to drive the CDR from stored simulation output file
    
    reg    signed    [15:0]    dc_in_i;
    reg    signed    [15:0]    dc_in_q;
    reg              [7:0]     ram_data;
    reg                        dc_ready;
    reg                        gain_shift;
    
    // Registers used the drive the Tx cancellation engine from logic described in this file
    
    reg                        rst_n;
    reg                        spi_ack;
    reg                        spi_ack_next;
    reg                        clk_4p5;
    reg                        clk_ram;
    reg                        ram_wren;
    reg              [9:0]     ram_addr;
    
    
    //    Wires used to accept outputs of TX cancellation engine
    
    wire             [7:0]     spi_data_out;
    wire             [14:0]    spi_data_aux_out;
    wire                       spi_data_csel;
    wire                       spi_data_rdy;
    
    // Integers used to keep track of violations
    
    integer                    num_errors;
    
    // Integers used to keep track of data pointers
    
    integer                    data_in_fid;
    integer                    data_in_rslt;
    integer                    data_out_fid;
    integer                    data_out_rslt;
    integer                    ram_in_fid;
    integer                    ram_in_rslt;
    
    // Integers used to keep track of the outputs of the tx canceller
    
    integer                    cap_vec_0;
    integer                    cap_vec_1;
    integer                    cap_vec_2;
    integer                    cap_vec_3;
    integer                    rdio_gain;
    
    // Integers holding the ideal results of the tx canceller
    
    integer                    cap_vec_0_ideal;
    integer                    cap_vec_1_ideal;
    integer                    cap_vec_2_ideal;
    integer                    cap_vec_3_ideal;
    integer                    rdio_gain_ideal;
    
    // Loop integer
    
    integer                    i;
    
    // Parameters
    
    parameter    CLK_4P5_HALF_PERIOD    =    (0.5e9)/(4.5e6);
    parameter    CLK_RAM_HALF_PERIOD    =    (0.5e9)/(200e6);
    parameter    RST_DEASSERT_DLY       =    100;
    parameter    RAM_PROGRAM_DLY        =    32*32*2*2*CLK_RAM_HALF_PERIOD;
    
    localparam    HI_GAIN_SETTING       =    8'b001_0110_0;    //First 3 bits set LNA gain to Max-24dB, second 4 bits: BB Gain to 6dB was 100_1111_0
    localparam    LO_GAIN_SETTING       =    8'b101_1001_0;    //First 3 bits set LNA gain to Max-36dB, second 4 bits: BB gain to 0dB was 101_1100_0
    localparam    RADIO_RX_ADDRESS      =    8'b1_000_1100;    //First bit is a 1 for write, 0x0c is address for Rx Gain
    
    // Initial reset and clock management
    
    initial    begin
        rst_n           =    1'b0;
        #RST_DEASSERT_DLY
        rst_n           =    1'b1;
    end
    
    initial begin
        clk_ram         =    1'b0;
        ram_wren        =    1'b0;
        ram_addr        =    10'b0;
        #RST_DEASSERT_DLY
        ram_in_rslt     =    $fscanf(ram_in_fid,"%d\n",ram_data);
        ram_wren        =    1'b1;
        for (i=0; i<32*32*2; i=i+1) begin
            #CLK_RAM_HALF_PERIOD
            clk_ram     =    ~clk_ram;
        end
        #CLK_RAM_HALF_PERIOD
        ram_wren        =    1'b0;
    end            
            
    
    initial    begin
        dc_in_i         =    16'b0;
        dc_in_q         =    16'b0;
        dc_ready        =    1'b0;
        gain_shift      =    1'b0;
        spi_ack         =    1'b0;
        spi_ack_next    =    1'b0;
        clk_4p5         =    1'b0;
        #RST_DEASSERT_DLY
        #RAM_PROGRAM_DLY
        forever begin
            #CLK_4P5_HALF_PERIOD;
            clk_4p5     =    ~clk_4p5;
        end    
    end
    
    // Initialize input variables

    initial    begin
        num_errors     =    0;
    end
    
    // Open data files
    
    initial    begin 
        data_in_fid    =    $fopen("../../../MATLAB-Octave-Test/rtl_test_vectors/txcancel_2bit_input_112617.dat","r");
        data_out_fid   =    $fopen("../../../MATLAB-Octave-Test/rtl_test_vectors/txcancel_2bit_output_112617.dat","r");
        ram_in_fid     =    $fopen("../../../MATLAB-Octave-Test/rtl_test_vectors/txcancel_2bit_ram_121816_sim.txt","r");
        //Note that while the input data is updated once per 4.5 MHz clock period,
        // the output data file is updated once every 128 4.5MHz clock periods
    
        if (data_in_fid == `NULL || data_out_fid == `NULL || ram_in_fid    == `NULL) begin
            $display("One of the file handles was null");
            $stop;
        end
    end
    
    // Instantiate DUT
    
    tx_cancel dut
    (
        .dc_in_i(dc_in_i),
        .dc_in_q(dc_in_q),
        .dc_ready(dc_ready),
        .gain_shift(gain_shift),
        .rst_n(rst_n),
        .spi_ack(spi_ack),                //This signal comes in from oscillator 55 MHz to 4p5 MHz synchronizer
        .clk_4p5(clk_4p5),                //4p5 MHz clock is used here
        .mem_wdata(ram_data),
        .mem_wraddress(ram_addr),
        .mem_clk(clk_ram),
        .mem_wren(ram_wren),
        .mem_rdata(),                     //Don't hook up the read-back port to anything
        .spi_data_out(spi_data_out),
        .spi_data_aux_out(spi_data_aux_out),
        .spi_data_csel(spi_data_csel),    //This is the chip select for which of the DTC is targeted
        .spi_data_rdy(spi_data_rdy)
    );
    

    always @(negedge clk_ram)    begin
        ram_in_rslt    =    $fscanf(ram_in_fid,"%d\n",ram_data);
        ram_addr       =    ram_addr+10'b1;
    end    
        
    // Run the always @ clk_4p5. Keep in mind that we are assuming here that all signals incoming from 55MHz domain
    // have already been resynced elsewhere
    
    always @(posedge clk_4p5)    begin
        data_in_rslt        =    $fscanf(data_in_fid,"%d %d %d %d\n",dc_in_i,dc_in_q,gain_shift,dc_ready);
    
        if($feof(data_in_fid))    begin
            $display("Number of errors = %d\n",num_errors);
            $stop;
        end
            
        spi_ack=spi_ack_next;
        spi_ack_next=1'b0;
    end
        
    always @(posedge spi_data_rdy)    begin
        spi_ack_next=1'b1;
                    
        if(spi_data_csel    ==    1'b0)    begin
            cap_vec_0    =    spi_data_out[4:0];
            cap_vec_1    =    spi_data_aux_out[14:10];
            cap_vec_2    =    spi_data_aux_out[9:5];
            cap_vec_3    =    spi_data_aux_out[4:0];
        end else if (spi_data_csel    ==    1'b1)    begin
            rdio_gain    =    spi_data_out;
                        
            if(gain_shift)
                rdio_gain_ideal    =    HI_GAIN_SETTING;
            else
                rdio_gain_ideal    =    LO_GAIN_SETTING;
                        
            data_out_rslt          =    $fscanf(data_out_fid,"%d %d %d %d\n",cap_vec_0_ideal,cap_vec_1_ideal,cap_vec_2_ideal,cap_vec_3_ideal);
            data_out_rslt          =    $fscanf(data_out_fid,"%d %d %d %d\n",cap_vec_0_ideal,cap_vec_1_ideal,cap_vec_2_ideal,cap_vec_3_ideal); //Do this on 010717 to match octave pattern gen setup
                            
            if($feof(data_out_fid))    begin
                $display("Data out file ended before the data in file - this is real bad");
                $stop;
            end
                            
            num_errors = num_errors + (cap_vec_0_ideal != cap_vec_0) + (cap_vec_1_ideal != cap_vec_1) + (cap_vec_2_ideal != cap_vec_2) + (cap_vec_3_ideal != cap_vec_3) + (rdio_gain_ideal != rdio_gain);
        end
    end
        
endmodule
    