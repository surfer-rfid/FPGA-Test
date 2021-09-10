/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Write 16b Command                                                    //
//                                                                                     //
// Filename: mcu_bfm_rfidr_top_postfit.v                                               //
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
//    This file is intended to simulate with the fitted gate-level version of the RTL. //
//                                                                                     //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    mcu_bfm_rfidr_top_postfit;

input    [15:0]     rn16_i;
input    [127:0]    pcepc;

`include "../../../sim_tb/test_rfidr_top_subtasks/load_rfidr_top_sram_rx_localparam_defs.v"

localparam    rn16_i_mag_i_ideal    =    32'sd29000;
localparam    rn16_i_mag_q_ideal    =    32'sd1300;
localparam    pcepc_mag_i_ideal     =    32'sd225000;
localparam    pcepc_mag_q_ideal     =    32'sd3000;


integer                        loop_clk;
reg                  [13:0]    loop_wvfm;
reg        signed    [31:0]    rn16_i_mag_i;
reg        signed    [31:0]    rn16_i_mag_q;
reg        signed    [31:0]    pcepc_mag_i;
reg        signed    [31:0]    pcepc_mag_q;
    
begin
    is_radio_running    =    1'b0;
    rn16_i_mag_i        =    32'sd0;
    rn16_i_mag_q        =    32'sd0;
    pcepc_mag_i         =    32'sd0;
    pcepc_mag_q         =    32'sd0;
    
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
    
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b010},8'b0000_0010,8'b0000_0000);
    $display("Set use_i to 1 at time %t",$realtime);

    //Set the radio mode to something wrong so that on the next write we can see if we actually do it right

    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b000},8'b0001_1100,8'b0000_0000);
    $display("Set radio mode to an improper value at time %t",$realtime);

    //Set the radio mode to the correct value and run the radio

    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b000},8'b0000_0001,8'b0000_0000);
    $display("Set radio mode to the correct value and ran the radio at time %t",$realtime);
    is_radio_running    =    1'b1;
    //Wait a few clock cycles to ensure that we can see that both the radio and waveform storage are running

    for(loop_clk=0; loop_clk <=2048; loop_clk=loop_clk+1) begin
        @(posedge clk_36_extl);
    end

    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b001},8'b0000_0000,8'b0000_1010);
    $display("Checked that both the radio and waveform storage are running at time %t",$realtime);
    
    //Wait for the IRQ

    wait(mcu_irq_extl);
    $display("Received radio run complete IRQ at time %t",$realtime);

    //Read radio exit code, it should be 0

    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b000},8'b0000_0000,8'b0000_0011);
    $display("Properly read OK radio exit code at time %t",$realtime);

    //Also read that the spi shows proper status with regards to radio being done.

    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b001},8'b0000_0000,8'b0000_0101);
    $display("Read proper radio done status registers at time %t",$realtime);
        
    //Read out the RX RAM for the RN16
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd0},8'b0,8'd16);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd1},8'b0,rn16_i[15:8]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd2},8'b0,rn16_i[7:0]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd3},8'b0,{4'bzzzz,4'b0000});                //Check that exit code is indeed 0
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd4},8'b0,rn16_i_mag_i[7:0]);    //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd5},8'b0,rn16_i_mag_i[15:8]);   //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd6},8'b0,rn16_i_mag_i[23:16]);  //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd7},8'b0,rn16_i_mag_i[31:24]);  //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd8},8'b0,rn16_i_mag_q[7:0]);    //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd9},8'b0,rn16_i_mag_q[15:8]);   //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd10},8'b0,rn16_i_mag_q[23:16]); //Check for the magnitude
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_RN16_I << 4)+9'd11},8'b0,rn16_i_mag_q[31:24]); //Check for the magnitude
    
    if(rn16_i_mag_i > rn16_i_mag_i_ideal + 32'sd10000 || rn16_i_mag_i < rn16_i_mag_i_ideal - 32'sd10000)    begin
        $display("Error: RN16_I_MAG_I is off. Actual: %d Ideal %d at time %t", rn16_i_mag_i, rn16_i_mag_i_ideal, $realtime);
        $stop;
    end
    
    if(rn16_i_mag_q > rn16_i_mag_q_ideal + 32'sd2000 || rn16_i_mag_q < rn16_i_mag_q_ideal - 32'sd2000)    begin
        $display("Error: RN16_I_MAG_Q is off. Actual: %d Ideal %d at time %t", rn16_i_mag_q, rn16_i_mag_q_ideal, $realtime);
        $stop;
    end
    
    $display("Read out RX RAM for the RN16 and found it to be correct at time %t",$realtime);
    
    //Read out the RX RAM for the PCEPC
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd0},8'b0,8'd128);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd1},8'b0,pcepc[127:120]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd2},8'b0,pcepc[119:112]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd3},8'b0,pcepc[111:104]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd4},8'b0,pcepc[103:96]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd5},8'b0,pcepc[95:88]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd6},8'b0,pcepc[87:80]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd7},8'b0,pcepc[79:72]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd8},8'b0,pcepc[71:64]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd9},8'b0,pcepc[63:56]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd10},8'b0,pcepc[55:48]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd11},8'b0,pcepc[47:40]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd12},8'b0,pcepc[39:32]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd13},8'b0,pcepc[31:24]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd14},8'b0,pcepc[23:16]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd15},8'b0,pcepc[15:8]);    //We need to make sure that the proper CRC is included with the input
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd16},8'b0,pcepc[7:0]);
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd17},8'b0,{4'bzzzz,4'b0000});
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd18},8'b0,pcepc_mag_i[7:0]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd19},8'b0,pcepc_mag_i[15:8]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd20},8'b0,pcepc_mag_i[23:16]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd21},8'b0,pcepc_mag_i[31:24]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd22},8'b0,pcepc_mag_q[7:0]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd23},8'b0,pcepc_mag_q[15:8]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd24},8'b0,pcepc_mag_q[23:16]);
    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data(1'b0,{4'b0100,1'b1,(RX_RAM_ADDR_OFFSET_PCEPC << 4)+9'd25},8'b0,pcepc_mag_q[31:24]);    
    
    if(pcepc_mag_i > pcepc_mag_i_ideal + 32'sd40000 || pcepc_mag_i < pcepc_mag_i_ideal - 32'sd40000)    begin
        $display("Error: PCEPC_MAG_I is off. Actual: %d Ideal %d at time %t", pcepc_mag_i, pcepc_mag_i_ideal, $realtime);
        $stop;
    end
    
    if(pcepc_mag_q > pcepc_mag_q_ideal + 32'sd8000 || pcepc_mag_q < pcepc_mag_q_ideal - 32'sd8000)    begin
        $display("Error: PCEPC_MAG_Q is off. Actual: %d Ideal %d at time %t", pcepc_mag_q, pcepc_mag_q_ideal, $realtime);
        $stop;
    end
    
    $display("Read out RX RAM for the PCEPC and found it to be correct at time %t",$realtime);
    
    //Read out the waveform memory
    //What we will do at the top level is have a parallel memory bfm that loads an ideal memory (wvfm_mem_ideal).
    //Then we will read out this ideal memory byte by byte to ensure that we are getting the proper bits out of the spi
    
    for(loop_wvfm = 14'b0; loop_wvfm < 14'b10_0000_0000_0000; loop_wvfm = loop_wvfm + 14'd1)    begin
        if((loop_wvfm % 1024) == 0)
            $display("Reading out waveform memory expecting byte %b at address %d at time %t",wvfm_mem_ideal[loop_wvfm[12:0]],loop_wvfm[12:0],$realtime);
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{1'b1,loop_wvfm[12:0]},8'b0,wvfm_mem_ideal[loop_wvfm[12:0]]);        //Here's hoping the casting all works out for the data byte
    end
    
    $display("Read out waveform memory and found it to be correct at time %t",$realtime);
    
    //Ack the IRQ
    wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b000},8'b0000_0010,8'b0000_0000);
    $display("Acked the radio IRQ at time %t",$realtime);
    
    //Maybe confirm here that the radio state has indeed been reset
    
    //wait(rfidr_top0.rfidr_fsm0.state==2'b00);
    //$display("Confirmed that the radio state was indeed reset by the ACK at time %t",$realtime);
    
    //Return to the top level of the simulation where we declare it a success.
end
endtask
    