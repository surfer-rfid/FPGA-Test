/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Write 16b Command                                                    //
//                                                                                     //
// Filename: mcu_bfm_rfidr_s11_top.v                                                   //
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
//    This file is intended to act as the MCU driving the RFIDr FPGA during            //
//    a search operation. We will not call the RAM loading function here -             //
//    we will call that in parallel.                                                   //
//                                                                                     //
//    103016 - This file is modified to strictly test the S11 DTC actuation            //
//                                                                                     //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


task    mcu_bfm_rfidr_s11_top;

input    [15:0]     rn16_i;
input    [127:0]    pcepc;

`include "../../../sim_tb/test_rfidr_top_subtasks/load_rfidr_top_sram_rx_localparam_defs.v"

localparam                rn16_i_mag_i_ideal    =    32'sd29000;
localparam                rn16_i_mag_q_ideal    =    32'sd1300;
localparam                pcepc_mag_i_ideal     =    32'sd225000;
localparam                pcepc_mag_q_ideal     =    32'sd3000;


integer                        loop_clk;
integer                        loop_dtc;
reg                  [13:0]    loop_wvfm;
reg        signed    [31:0]    rn16_i_mag_i;
reg        signed    [31:0]    rn16_i_mag_q;
reg        signed    [31:0]    pcepc_mag_i;
reg        signed    [31:0]    pcepc_mag_q;
    
begin
    is_radio_running   =    1'b0;
    rn16_i_mag_i       =    32'sd0;
    rn16_i_mag_q       =    32'sd0;
    pcepc_mag_i        =    32'sd0;
    pcepc_mag_q        =    32'sd0;
    
    //Check that clk36 is valid
    $display("Start MCU BFM at time %t",$realtime);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b000},8'b0000_0000,8'b0100_0010);    //We want to see the exit code as "DIDNT EXIT" and CLK_36 as valid but not running
    $display("Checked that CLK 36 is valid at time %t",$realtime);
    
    //Make clk 36 run
    
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b001},8'b1000_0000,8'b0000_0000);
    $display("Set CLK 36 to run at time %t",$realtime);
    
    //Now check to see that clk_36 is indeed running
    
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b000},8'b0000_0000,8'b0100_0011);
    $display("Checked that CLK 36 is running at time %t",$realtime);

    //Set the waveform offset - current calculations have us needing it at "5"?!?!?

    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b011},8'b0000_0101,8'b0000_0000);
    $display("Set waveform offset at time %t",$realtime);
    
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b010},8'b1100_0010,8'b0000_0000);
    $display("Set use_i to 1 and enter s11 dtc test mode, clearing the local dtc counters at time %t",$realtime);

    //Set is_radio_running to 1 to enable the sx1257/DTC BFM. We need this to actuate the DTC
    is_radio_running    =    1'b1;
    
    for(loop_clk=0; loop_clk <=2048; loop_clk=loop_clk+1) begin
        @(posedge clk_36_extl);
    end

    //There are 262K increments of the DTC test.
    //How many can we reasonably run?
    //262K will take about 6.55s of simulation time
    //we might have time for 20ms of simulation time
    //So 8192 would be a reasonable number
    //Also this actuate the second set of capacitors
    
    for(loop_dtc=0; loop_dtc <= 8192; loop_dtc=loop_dtc+1) begin
        if((loop_dtc % 1024) == 0)
            $display("At DTC loop %d at time %t",loop_dtc,$realtime);
        //Write for cntrlr SPI to go
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b110},8'b0000_0001,8'b0000_0000);
        //Wait for the IRQ
        //wait(mcu_irq_extl); //Oops it came too fast. In the real software the IRQ should be pending.
        //Read that cntrlr SPI is indeed done
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b1010_0010);
        if((loop_dtc % 1024) == 0)
            $display("Got DTC done %d at time %t",loop_dtc,$realtime);
        //Ack the cntrlr SPI by deasserting it.
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b110},8'b0000_0000,8'b0000_0000);
        //Increment the DTC capacitor value
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b010},8'b1010_0010,8'b0000_0000);
    end
    
    //Maybe confirm here that the radio state has indeed been reset
    
    wait(rfidr_top0.rfidr_fsm0.state==2'b00);
    $display("Confirmed that the radio state was indeed reset by the ACK at time %t",$realtime);
    
    //Return to the top level of the simulation where we declare it a success.
end
endtask
    