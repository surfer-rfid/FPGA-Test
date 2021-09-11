//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
// Bench : Test input I/Q wave storage feature                                      //
//                                                                                  //
// Filename: test_wave_storage.v                                                    //
// Creation Date: 7/30/2016                                                         //
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
//    Test the waveform storage module using 1-bit patterns from the top level      //
//    Octave DSP simulation. Load up the RAM in the waveform storage module,        //
//    then read it out.                                                             //
//                                                                                  //
//    Revisions:                                                                    //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.              //
//    This file is out of date and was not re-run after cleanup for release, so     //
//    please temper expectations for use accordingly.                               //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

// This should run for about 20,000,000,000 ps

`timescale    1ns/100ps
`define       NULL    0

module test_wave_storage();

    // Registers used to drive the waveform storage module from the signal processing side (36MHz)
    reg               in_i;
    reg               in_q;
    reg               clk_36;
    reg               rst_n;
    reg               go;                //This is transferred to the 4.5MHz clock domain at the top level, which is synchronous with 36MHz clock domain
    reg     [23:0]    wait_offset;
    
    // Registers used to drive the SPI side of the SRAM
    reg     [12:0]    sram_address_fromspi;
    reg               clk_spi;
    reg               clk_spi_en;
    wire    [7:0]     sram_data_tospi;
    
    // Registers to act as index holders
    
    reg     [19:0]    start_index;
    reg     [19:0]    stop_index;
    reg     [19:0]    sim_counter;
    reg     [1:0]     playback_counter;
    
    // Wires from SRAM which contain the data we need to examine
    wire              done;
    wire              running;
    reg               done_ideal;
    reg               running_ideal;
    reg               out_i;
    reg               out_q;
    
    // Integers which hold file handles
    integer           data_in_fid;
    integer           data_in_fid_2;
    integer           scan_in_rslt;
    
    // Integers to act as error counters
    integer           num_errors_done;
    integer           num_errors_running;
    integer           num_errors_sram_i;
    integer           num_errors_sram_q;
    integer           sim_pass_top;

    
    // Clock Parameters
    
    parameter    CLK_36_HALF_PERIOD     =    (0.5e9)/(36e6);
    parameter    CLK_SPI_HALF_PERIOD    =    (0.5e9)/(27.5e6);
    parameter    RST_DEASSERT_DLY       =    100;
    
    // Run the clocks
    
    initial    begin
        clk_36        =    1'b0;
        #RST_DEASSERT_DLY
        forever 
            begin
                #CLK_36_HALF_PERIOD;
                clk_36=~clk_36;
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
        rst_n          =    1'b0;
        #RST_DEASSERT_DLY
        rst_n          =    1'b1;
    end
    
    //Run an example task
    initial begin
        in_i                =    1'b0;
        in_q                =    1'b0;
        out_i               =    1'b0;
        out_q               =    1'b0;
        go                  =    1'b0;
        clk_spi_en          =    1'b0;
        done_ideal          =    1'b0;
        running_ideal       =    1'b0;
        playback_counter    =    2'b0;
        wait_offset         =    24'd592034;                           //Pick a somewhat random number here. It's early enough in the waveform to permit a proper sampling.
        start_index         =    20'd48723;                            //Pick a somewhat random number here. It's early enough in the waveform to roughly correspond to our other simulations.
        stop_index          =    start_index+wait_offset+20'd32767;    //We know that the stop index must be this - we will be checking to see if "done" signal actually rises here.
        sim_pass_top        =    1'b0;                                 //Set this to zero until we see that everything is all right.
        run_sim(sim_pass_top);
        $stop;
    end
    
// Have the bulk of the simulation in a task which takes one stimulus file
// and compares it with the outputs of the RAM

    task    run_sim (
        output              sim_pass
    );
        
    begin
        
    //// Initial block for opening data files

    data_in_fid             =    $fopen($psprintf("../../../MATLAB-Octave-Test/rtl_test_vectors/wvstrg_input.dat"),"r");

    if (data_in_fid == `NULL) begin
        $display("The input file handle came back as NULL");
        $stop;
    end
                
    //// Initialize simulation integer error counters, also the SPI side of the SRAM

    sram_address_fromspi    =    0;
    num_errors_done         =    0;
    num_errors_running      =    0;
    num_errors_sram_i       =    0;
    num_errors_sram_q       =    0;
    sim_pass                =    0;        // Set this to 1 when we see that everything is OK
    sim_counter             =    20'b0;
    
    //// Read out data from input file
            
    while (!$feof(data_in_fid)) begin
        @(posedge clk_36);
        if(sim_counter == start_index)
            go              =    1'b1;
        else
            go              =    1'b0;
        
        done_ideal          =    sim_counter > stop_index;                                  //Problem here: As coded, we assume that the posedge of clk_36 triggers execution of the DUT before we get here.
        running_ideal       =    sim_counter <= stop_index && sim_counter > start_index;    //But actually, all of this code seems to execute before the DUT outputs do in response to a clock edge.
                                                                                            //For now we will check for error on the negative clock edge but this effect deserves further study.
        scan_in_rslt        =    $fscanf(data_in_fid,"%d %d\n",in_i,in_q);
        sim_counter         =    sim_counter+20'd1;
       
        @(negedge clk_36);
        
        if(done != done_ideal)
            num_errors_done=num_errors_done+1;
            
        if(running != running_ideal)
            num_errors_running=num_errors_running+1;
    end
    
    $fclose(data_in_fid);
    //// Done with input file, let's check out the errors
    

    //Open the input file again - it's the simplest way to check that what comes out is what went in.
    data_in_fid_2           =    $fopen($psprintf("../../../MATLAB-Octave-Test/rtl_test_vectors/wvstrg_input.dat"),"r");

    if (data_in_fid_2 == `NULL) begin
        $display("The input file handle came back as NULL");
        $stop;
    end

    //Reset the sim counter, as we will be playing back the results of the simulation
    //Note that we will never see sim_counter = 0, rather, it will zip right ahead to start_index_wait_offset+4
    sim_counter             =    20'b0;
    
    //Burn through the input data that was not stored.
    while (sim_counter <= start_index+wait_offset) begin
        scan_in_rslt        =    $fscanf(data_in_fid_2,"%d %d\n",in_i,in_q);
        sim_counter         =    sim_counter+20'd1;
    end
    
    clk_spi_en=1'b1;
    @(posedge clk_spi);
    
    while (sim_counter <= stop_index) begin
        
        @(posedge clk_spi);
        
            case(playback_counter)    //Why do we think that sim_counter[1:0] is aligned with load_ctr inside the wave_storage block?
                2'b00:    begin    out_i=sram_data_tospi[0]; out_q=sram_data_tospi[1]; end
                2'b01:    begin    out_i=sram_data_tospi[2]; out_q=sram_data_tospi[3]; end
                2'b10:    begin    out_i=sram_data_tospi[4]; out_q=sram_data_tospi[5];
                                   sram_address_fromspi    =    sram_address_fromspi+1;    //Here, we assume that we get the RAM byte out the clock cycle after clk_spi_en is asserted
                          end
                2'b11:    begin    out_i=sram_data_tospi[6]; out_q=sram_data_tospi[7]; end
                default:  begin    out_i=sram_data_tospi[0]; out_q=sram_data_tospi[1]; end
            endcase    
        
            scan_in_rslt            =    $fscanf(data_in_fid_2,"%d %d\n",in_i,in_q);
            sim_counter             =    sim_counter+20'd1;
            playback_counter        =    playback_counter+2'd1;
        
        @(negedge clk_spi);
        
        if(in_i != out_i)
            num_errors_sram_i=num_errors_sram_i+1;
            
        if(in_q != out_q)
            num_errors_sram_q=num_errors_sram_q+1;
        
    end
        
    clk_spi_en=1'b0;
        
    $fclose(data_in_fid_2);
    
    $display("Number of \"done\" errors for this file handle = %d\n",num_errors_done);
    $display("Number of \"running\" errors for this file handle = %d\n",num_errors_running);
    $display("Number of sram I errors for this file handle = %d\n",num_errors_sram_i);
    $display("Number of sram Q errors for this file handle = %d\n",num_errors_sram_q);
    
    sim_pass    =    !(num_errors_done+num_errors_running+num_errors_sram_i+num_errors_sram_q);
                
    end
    endtask
                
// Instantiate DUTs

wave_storage    dut_wave_storage (
    // Inputs
    .in_i(in_i), 
    .in_q(in_q),
    .clk_27p5(clk_spi),
    .clk_36(clk_36),
    .rst_n(rst_n),
    .go(go),
    .wait_offset(wait_offset),
    .clk_27p5_en(clk_spi_en),
    .address(sram_address_fromspi),
    // Outputs
    .out(sram_data_tospi),
    .done(done),
    .running(running)
);
    
endmodule
