/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Bench : Test RFIDr top level - TX Cancel Hack Variant                               //
//                                                                                     //
// Filename: test_rfidr_top_hack_txcancel.v                                            //
// Creation Date: 9/8/2016                                                             //
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
// Description:                                                                        //
//    Test the top level RFIDr with BFMs of an ideal waveform storage, NRF51822        //
//    (MCU), and RFID tag/SX1257.    This file focuses on overall connectivity, not    //
//    feature support, so we won't test things like clocks stopping and starting.      //
//                                                                                     //
//    Revisions:                                                                       //
//                                                                                     //
//    090816 - File created                                                            //
//    091616 - Make hack_txcancel version to see if txcancel works when all            //
//    cap values change early and simultaneously.                                      //
//    083021 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

// Declare the overall test module and the timing parameters

`timescale 1ns/100ps
`define NULL 0

module test_rfidr_top_hack_txcancel();

///////////////////////////////////////////////////////////////////////////////////////////
// Define Parameters
///////////////////////////////////////////////////////////////////////////////////////////

    parameter    RST_DEASSERT_DLY        =    100;
    parameter    TIMEOUT_DLY             =    200000000;
    
///////////////////////////////////////////////////////////////////////////////////////////
// Declare the wires and registers required in the simulation
///////////////////////////////////////////////////////////////////////////////////////////

    wire    clk_36_extl;
    reg     rst_n_extl;
    wire    in_i_extl;
    wire    in_q_extl;
    wire    out_i_extl;
    wire    out_q_extl;
    wire    mcu_irq_extl;
    reg     prphrl_pclk_extl;
    wire    prphrl_cipo_extl;
    reg     prphrl_copi_extl;
    reg     prphrl_nps_extl;
    wire    cntrlr_pclk_extl;
    wire    cntrlr_copi_extl;
    wire    cntrlr_cipo_extl;
    wire    cntrlr_nps_rdio_extl;
    wire    cntrlr_nps_cap3_extl;
    wire    cntrlr_nps_cap2_extl;
    wire    cntrlr_nps_cap1_extl;
    wire    cntrlr_nps_cap0_extl;
    
    //Define registers and integers required to run large-scale function modeling tasks.
    
    integer          seed_epc_select_tx_top;
    integer          seed_epc_write_tx_top;
    integer          seed_rn16_bits_top;
    integer          seed_misc_bits_top;

    reg    [27:0]    select_tx_bits_top;
    reg    [27:0]    select_tx_blank_bits_top;
    reg    [21:0]    query_tx_bits_top;
    reg    [25:0]    read_tx_bits_top;
    reg    [27:0]    lock_tx_bits_top;
    reg    [9:0]     write_tx_bits_top;
    reg    [15:0]    rn16_i_rx_bits_top;
    reg    [15:0]    rn16_i_rx_bits_top_crc;
    reg    [31:0]    pcepc_rx_bits_top_msb;
    reg    [31:0]    pcepc_rx_bits_top_mlsb;
    reg    [31:0]    pcepc_rx_bits_top_lmsb;
    reg    [31:0]    pcepc_rx_bits_top_lsb;
    reg    [127:0]   pcepc_rx_bits_top;
    
    //Define ideal memory with which to store waveform storage data
    
    integer          loop_ram_init;
    reg    [7:0]     wvfm_mem_ideal    [0:8191];
    
    //Define dummy wires that bring out signals within the dut to top level where they can be examined by the check_tx_gen task
    
    wire             tx_go;
    wire             tx_en;
    wire             clk_4p5;
    wire             out_i_baseband_4p5;
    wire    [4:0]    radio_state;
    
    //Define analog outputs of SX1257 TX BB filters
    
    real             tx_iir_i_out;
    real             tx_iir_q_out;

    wire    [63:0]   tx_iir_i_out_bits;
    wire    [63:0]   tx_iir_q_out_bits;
    
    //Define wires required to run the SX1257 RX BFM SPI
    
    wire             cntrlr_cipo_sx1257_out;
    wire             cntrlr_cipo_sx1257_drive;
    
    //Define a flag to gate start of simulation until the SRAM is loaded
    
    reg              is_sram_loaded;
    reg              is_radio_running;
    
    //Define dummy signals to bring out from txcancel module
    
    wire             txcancel_values_ready;
    reg    [4:0]     dtc_value0;
    reg    [4:0]     dtc_value1;
    reg    [4:0]     dtc_value2;
    reg    [4:0]     dtc_value3;
    
////////////////////////////////////////////////////////////////////////////////////////
// Initialize registers
////////////////////////////////////////////////////////////////////////////////////////
    initial    begin
        is_sram_loaded              =    1'b0;
        is_radio_running            =    1'b0;
        rst_n_extl                  =    1'b0;
        prphrl_pclk_extl            =    1'b0;
        prphrl_copi_extl            =    1'b0;
        prphrl_nps_extl             =    1'b1;

        for(loop_ram_init=0; loop_ram_init < 8192; loop_ram_init=loop_ram_init+1)    begin
            wvfm_mem_ideal[loop_ram_init]    =    8'b0;
        end
        
        //Define the integers and registers required to drive the large-scale task models
      
        seed_epc_select_tx_top      =    365234;
        seed_epc_write_tx_top       =    1940459;

        select_tx_bits_top          =    28'b1010_100_010_01_00100000_01100000;               //This is sort-of made up, targeting just a match of a 96-bit EPC;
        select_tx_blank_bits_top    =    28'b1010_100_010_01_00100000_01100000;               //This is sort-of made up, targeting just a match of a 96-bit EPC;
        query_tx_bits_top           =    22'b1000_1_11_1_00_00_0_0111_01010;                  //Command_DR_M_TRext_Sel_Session_Tgt_Q_CRC5 (CRC5 here is fake!!!!!);
        read_tx_bits_top            =    26'b11000010_01_00100000_00000110;                   //Read a 96b EPC starting at address 0x20. Assume words are 16b (I think they are).;
        lock_tx_bits_top            =    {8'b11000101,20'b10_01_11_00_11__01_10_10_00_11};    //First 8 bits are the packet ID, the last 20 bits I made up randomly.
        write_tx_bits_top           =    10'b11000011_01;                                     //First 8 bits are the command ID, second 2 bits specify the EPC MemBank.
        rn16_i_rx_bits_top          =    16'b01000000_00100001;  
        rn16_i_rx_bits_top_crc      =    16'b11011011_01111111;
        pcepc_rx_bits_top_msb       =    32'b00100011_00110100_01000001_11000101;
        pcepc_rx_bits_top_mlsb      =    32'b11001000_10110011_11011000_01110001;
        pcepc_rx_bits_top_lmsb      =    32'b11010011_00101110_10011010_00111001;
        pcepc_rx_bits_top_lsb       =    32'b01010000_00110011_00011100_10100101;
        pcepc_rx_bits_top           =    {pcepc_rx_bits_top_msb,pcepc_rx_bits_top_mlsb,pcepc_rx_bits_top_lmsb,pcepc_rx_bits_top_lsb};
    end

////////////////////////////////////////////////////////////////////////////////////////
// Run independent clocks, generate reset, set time format, run timeout checker
////////////////////////////////////////////////////////////////////////////////////////

    initial    $timeformat(-9,1,"ns",10);
    
    initial begin : catch_timeout
        #TIMEOUT_DLY
        $display("The simulation failed: we reached the timeout at time %t",$realtime);
        $stop;
    end
    
    initial    begin
        #RST_DEASSERT_DLY
        rst_n_extl                =    1'b1;
    end
    
////////////////////////////////////////////////////////////////////////////////////////
// Define RAM loading tasks
////////////////////////////////////////////////////////////////////////////////////////

    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_rx.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_txcw0.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_select.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_select_blank_epc.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_query.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_query_rep.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_ack_rn16.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_ack_handle.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_nak.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_reqhdl.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_reqrn16.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_write.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_write_16b.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_read.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_lock.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_top.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/load_rfidr_top_sram_tx_cancel.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/read_rfidr_top_sram_tx_cancel.v"
    
////////////////////////////////////////////////////////////////////////////////////////
// Define TX GEN checking tasks
////////////////////////////////////////////////////////////////////////////////////////
    
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_top.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_txcw0.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_select.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_select_blank_epc.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_query.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_query_rep.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_ack_rn16.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_nak.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_reqrn16.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_write.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_read.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_lock.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_write_16b.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_generate_crc16.v"
    
////////////////////////////////////////////////////////////////////////////////////////
// Assign internal nets to external wires so that they can be checked by the TX GEN checking tasks
////////////////////////////////////////////////////////////////////////////////////////
    
    assign    tx_go                 =    rfidr_top0.tx_go;
    assign    tx_en                 =    rfidr_top0.tx_en;
    assign    clk_4p5               =    rfidr_top0.clk_4p5;
    assign    out_i_baseband_4p5    =    rfidr_top0.out_i_baseband_4p5;
    assign    radio_state           =    rfidr_top0.radio_state;
    assign    cntrlr_cipo_extl      =    cntrlr_cipo_sx1257_drive ? cntrlr_cipo_sx1257_out : 1'bz;


////////////////////////////////////////////////////////////////////////////////////////
// Assign internal nets to external wires so that they can be used to drive the tx cancellation algorithm
////////////////////////////////////////////////////////////////////////////////////////
    
    assign    txcancel_values_ready    =    (rfidr_top0.tx_cancel0.state_curr == 5'd9);
    
    initial    begin
        dtc_value0    <=    5'd7;
        dtc_value1    <=    5'd13;
        dtc_value2    <=    5'd13;
        dtc_value3    <=    5'd13;
    end
    
    always @(posedge    txcancel_values_ready)    begin
        dtc_value0    <=    rfidr_top0.tx_cancel0.state_cap1[11:7];
        dtc_value1    <=    rfidr_top0.tx_cancel0.state_cap1[6:2];
        dtc_value2    <=    rfidr_top0.tx_cancel0.state_cap2[11:7];
        dtc_value3    <=    rfidr_top0.tx_cancel0.state_cap2[6:2];
    end
    
////////////////////////////////////////////////////////////////////////////////////////
// Convert bits to real for the tx filter outputs
////////////////////////////////////////////////////////////////////////////////////////
    
    always @(*)    begin
        tx_iir_i_out    =    $bitstoreal(tx_iir_i_out_bits);
        tx_iir_q_out    =    $bitstoreal(tx_iir_q_out_bits);
    end
    
////////////////////////////////////////////////////////////////////////////////////////
// Define Major BFMs
////////////////////////////////////////////////////////////////////////////////////////
    
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/wr_3byte_transaction_from_mcu_spi_cntrlr.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/wr_3byte_transaction_from_mcu_spi_cntrlr_return_data.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/mcu_bfm_rfidr_top.v"
    `include "../../../FPGA-Test/test_rfidr_top_subtasks/wvfm_strg_ideal_bfm.v"
    
////////////////////////////////////////////////////////////////////////////////////////
// Define top level simulation operation
////////////////////////////////////////////////////////////////////////////////////////
    
    initial begin
        #RST_DEASSERT_DLY
        load_rfidr_top_sram_tx_cancel;
        //read_rfidr_top_sram_tx_cancel;
        load_rfidr_top_sram_top(seed_epc_select_tx_top,seed_epc_write_tx_top,select_tx_bits_top,select_tx_blank_bits_top,query_tx_bits_top,read_tx_bits_top,lock_tx_bits_top,write_tx_bits_top);
    
        //Inputs to the load_rfid_top_sram_top task are:
        //input    [31:0]    seed_epc_select;
        //input    [31:0]    seed_epc_write;
    
        //input    [27:0]    select_bits;
        //input    [27:0]    select_blank_bits;
        //input    [21:0]    query_bits;
        //input    [25:0]    read_bits;
        //input    [27:0]    lock_bits;
        //input    [9:0]     write_bits;
        
        //How do we determine that the simulation succeeded?
        //This actually takes place in the sx1257_tag bfm module when we run through the entire input vector without hitting an error elsewhere beforehand
        is_sram_loaded    =    1'b1;
    end

////////////////////////////////////////////////////////////////////////////////////////
// Run the various tasks associated with this simulation
////////////////////////////////////////////////////////////////////////////////////////
    
    initial    begin
        wait(is_sram_loaded);
        mcu_bfm_rfidr_top(rn16_i_rx_bits_top, pcepc_rx_bits_top);
            
        //input    [15:0]    rn16_i;
        //input    [127:0]   pcepc;
        
        $display("Finished MCU BFM: successful end to simulation at time %t",$realtime);
        $stop;
    end
    
    initial    begin
        wait(is_sram_loaded);
        wvfm_strg_ideal_bfm;
    end
    
    initial    begin
        wait(is_sram_loaded);
        check_tx_gen_top(seed_epc_select_tx_top,seed_epc_write_tx_top,seed_epc_write_tx_top+1,select_tx_bits_top,select_tx_blank_bits_top,query_tx_bits_top,read_tx_bits_top,lock_tx_bits_top,write_tx_bits_top,rn16_i_rx_bits_top,rn16_i_rx_bits_top+1);
        //Send in all of the complicated bit patterns that can in fact vary
    
        //input    [31:0]    seed_epc_select;
        //input    [31:0]    seed_epc_write;
        //input    [31:0]    seed_rn16_bits;
    
        //input    [27:0]    select_bits;
        //input    [27:0]    select_blank_bits;
        //input    [21:0]    query_bits;
        //input    [25:0]    read_bits;
        //input    [27:0]    lock_bits;
        //input    [9:0]     write_bits;
        //input    [15:0]    rn16_i_bits;
        //input    [15:0]    handle_bits;
    end
        
////////////////////////////////////////////////////////////////////////////////////////
// Instantiate non-synthesizable BFMs associated with this simulation
////////////////////////////////////////////////////////////////////////////////////////
    
    sx1257_rx_and_tag_bfm_hack_txcancel    sx1257_rx_and_tag_bfm_0
    (
        .is_radio_running(is_radio_running),
        .cntrlr_nps_rdio(cntrlr_nps_rdio_extl),
        .cntrlr_nps_cap3(cntrlr_nps_cap3_extl),
        .cntrlr_nps_cap2(cntrlr_nps_cap2_extl),
        .cntrlr_nps_cap1(cntrlr_nps_cap1_extl),
        .cntrlr_nps_cap0(cntrlr_nps_cap0_extl),
        .cntrlr_pclk(cntrlr_pclk_extl),
        .cntrlr_copi(cntrlr_copi_extl),
        .dtc_value_0(dtc_value0),
        .dtc_value_1(dtc_value1),
        .dtc_value_2(dtc_value2),
        .dtc_value_3(dtc_value3),
        .sx1257_clk(clk_36_extl),
        .sx1257_out_i(in_i_extl),
        .sx1257_out_q(in_q_extl),
        .cntrlr_cipo_sx1257_drive(cntrlr_cipo_sx1257_drive),
        .cntrlr_cipo_sx1257_out(cntrlr_cipo_sx1257_out)
    );
    
    sx1257_tx_filters_bfm_rfidr_top    sx1257_tx_filters_bfm_rfidr_top_0
    (
        .out_i_extl(out_i_extl),
        .out_q_extl(out_q_extl),
        .clk_36_extl(clk_36_extl),
        .tx_iir_i_out_bits(tx_iir_i_out_bits),
        .tx_iir_q_out_bits(tx_iir_q_out_bits)
    );
    
////////////////////////////////////////////////////////////////////////////////////////
// Instantiate the top level module
////////////////////////////////////////////////////////////////////////////////////////

    rfidr_top     rfidr_top0(
        .clk_36_in_pin(clk_36_extl),
        .rst_n_pin(rst_n_extl),
        .in_i_pin(in_i_extl),
        .in_q_pin(in_q_extl),
        .out_i_pin(out_i_extl),
        .out_q_pin(out_q_extl),
        .mcu_irq_pin(mcu_irq_extl),
        .prphrl_pclk_pin(prphrl_pclk_extl),
        .prphrl_cipo_pin(prphrl_cipo_extl),
        .prphrl_copi_pin(prphrl_copi_extl),
        .prphrl_nps_pin(prphrl_nps_extl),
        .cntrlr_pclk_pin(cntrlr_pclk_extl),
        .cntrlr_copi_pin(cntrlr_copi_extl),
        .cntrlr_cipo_pin(cntrlr_cipo_extl),
        .cntrlr_nps_rdio_pin(cntrlr_nps_rdio_extl),
        .cntrlr_nps_cap3_pin(cntrlr_nps_cap3_extl),
        .cntrlr_nps_cap2_pin(cntrlr_nps_cap2_extl),
        .cntrlr_nps_cap1_pin(cntrlr_nps_cap1_extl),
        .cntrlr_nps_cap0_pin(cntrlr_nps_cap0_extl)
    );

endmodule