/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
// Bench : Test TX Gen and Radio FSM                                               //
//                                                                                 //
// Filename: test_tx_gen.v                                                         //
// Creation Date: 8/23/2016                                                        //
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
//    Test the TX generation circuit along with the real TX RAM and Radio FSM      //
//    and RN16/Handle transfer registers. Use tasks to create BFMs for the RAM     //
//    loading, data recovery, ideal playback, and comparison functions.            //
//     Also we will test the top level FSM!!!!                                     //
//                                                                                 //
//    Revisions:                                                                   //
//    082316 - File created.                                                       //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.             //
//    This file is out of date and was not re-run after cleanup for release, so    //
//    please temper expectations for use accordingly.                              //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////

// Declare the overall test module and the timing parameters

`timescale 1ns/100ps
`define NULL 0

module test_tx_gen();

/////////////////////////////////////////////////////////////////////////////////////////
// Define Parameters
/////////////////////////////////////////////////////////////////////////////////////////

    parameter    CLK_RAM_HALF_PERIOD     =    (0.5e9)/(360e6);
    parameter    CLK_27P5_HALF_PERIOD    =    (0.5e9)/(27.5e6);        //Make a super fast clock to load in RAMs. But only have it run when needed.
    parameter    CLK_4P5_HALF_PERIOD     =    (0.5e9)/(4.5e6);
    parameter    RST_DEASSERT_DLY        =    100;
    parameter    TIMEOUT_DLY             =    300000000;
    
/////////////////////////////////////////////////////////////////////////////////////////
// Declare the wires and registers required in the simulation
/////////////////////////////////////////////////////////////////////////////////////////

    // Inputs to TX Gen
    wire    [7:0]   radio_sram_rdata_4p5;
    wire            rn16_to_txgen;
    wire            handle_to_txgen;
    wire    [4:0]   radio_state;
    reg             clk_4p5;
    reg             rst_n_4p5;
        
    // Inputs to rn16 and handle shift registers
    reg             bit_decision_from_dr;
    reg             shift_rn16_from_dr;
    reg             shift_handle_from_dr;
        
    //Inputs to Radio SRAM with MUX
    reg    [8:0]    radio_sram_address_rx;
    reg    [9:0]    radio_sram_addr_27p5;
    reg             clk_ram;
    reg    [7:0]    radio_sram_wdata_4p5;
    reg    [7:0]    radio_sram_wdata_27p5;
    wire            radio_sram_txrxaccess;    //FTLOG let's change this name
    reg             radio_sram_wren;
    reg             radio_sram_we_data_27p5;

    // Inputs Radio FSM
    reg             radio_go_4p5;              //    *** From top-level FSM
    reg    [2:0]    radio_mode_4p5;            //    *** From memory-mapped registers interfacing with SPI
    reg    [2:0]    radio_mode_temp;           //    We will do the clock crossings by hand.
    reg    [2:0]    radio_mode_27p5;           //    Do the clock crossings by hand
    reg             rx_done;                   //    The RX has completed its reception, made valid its indicators, and stored its results in SRAM
        
    //Inputs RFIDr FSM
    reg             radio_go;                  //    This needs to be a one-shot signal from the SPI control registers
    reg             radio_done_27p5;           //    This needs to be a one-shot signal from the radio
    reg             radio_busy_27p5;
    reg             irq_ack;                   //    This needs to be a one-shot signal from the SPI control registers
    reg             rst_n_27p5;
    reg             clk_27p5;
        
    // Outputs TX Gen
    wire            shift_rn16_to_txgen;
    wire            shift_handle_to_txgen;
    wire    [8:0]   radio_sram_address_tx;
    wire            out_i_baseband_4p5;
    wire            tx_done;
    wire            last_tx_write;
    wire            tx_error_4p5;
    
    //Outputs Radio SRAM with MUX
    
    wire    [7:0]   radio_sram_rdata_27p5;
    
    // Outputs Radio FSM
    wire            rx_block;                   //    Block the RX from seeing crazy TX signal
    wire            rx_go;                      //    Kick off the RX DR state machine
    wire            rx_gain;                    //    Increase RX gain vis-a-vis TX cancel block and SPI
    wire            tx_go;                      //    Kick off the TX Gen state machine
    wire            tx_en;                      //    ??? Enable SX1257 TX, TX PA ??? - Use this to enable TX Gen CW at least
    wire            tx_gain;                    //    ??? Full power (1) for search, Low power (0) for programming ???    
    wire            wvfm_go;                    //    Kick off waveform recording
    wire            radio_busy_4p5;             //    *** Tell top-level FSM and memory-mapped register that radio is busy.
    wire    [2:0]   radio_exit_code_4p5;        //    *** Pass (0) or fail (1)
    wire    [3:0]   radio_num_tags_4p5;         //    Tells how many blank tags were found on the latest search
    wire            radio_done_4p5;             //    *** Tell top-level FSM that the radio FSM is done
    
    //Outputs RFIDr FSM
    wire            radio_go_27p5;
    wire            radio_running;              //This signal is required in order to disable SPI peripheral writes and SPI peripheral feedthrough
    wire            radio_done;
    wire            mcu_irq_pin;
    
    //Define any registers that we haven't already that are required for clock domain crossing
    
    reg             radio_go_temp;
    reg             radio_done_temp;
    reg             radio_busy_temp;

    //Define registers and integers required to run large-scale function modeling tasks.
    
    integer         seed_epc_select_top;
    integer         seed_epc_write_top;
    integer         seed_rn16_bits_top;
    integer         seed_misc_bits_top;

    reg    [27:0]   select_bits_top;
    reg    [27:0]   select_blank_bits_top;
    reg    [21:0]   query_bits_top;
    reg    [25:0]   read_bits_top;
    reg    [27:0]   lock_bits_top;
    reg    [9:0]    write_bits_top;
    reg    [15:0]   rn16_i_bits_top;
    reg    [15:0]   handle_bits_top;
    
    //Define loop variables that we may need
    
    integer    loop_misc;
    
/////////////////////////////////////////////////////////////////////////////////////////
// Initialize registers
/////////////////////////////////////////////////////////////////////////////////////////
    initial begin
      // Inputs to TX Gen
      clk_4p5                 =    1'b0;
      rst_n_4p5               =    1'b0;
        
      // Inputs to rn16 and handle shift registers
      bit_decision_from_dr    =    1'b0;
      shift_rn16_from_dr      =    1'b0;
      shift_handle_from_dr    =    1'b0;
        
      //Inputs to Radio SRAM with MUX
      radio_sram_address_rx   =    9'b0;
      radio_sram_addr_27p5    =    10'b0;
      clk_ram                 =    1'b0;
      radio_sram_wdata_4p5    =    8'b0;
      radio_sram_wdata_27p5   =    1'b0;
      radio_sram_wren         =    1'b0;
      radio_sram_we_data_27p5 =     1'b0;

      // Inputs Radio FSM
      radio_go_4p5            =    1'b0;
      radio_mode_4p5          =    3'b0;
      radio_mode_temp         =    3'b0;
      radio_mode_27p5         =    3'b0;
      rx_done                 =    1'b0;
        
      //Inputs RFIDr FSM
      radio_go                =    1'b0;
      radio_done_27p5         =    1'b0;
      irq_ack                 =    1'b0;
      rst_n_27p5              =    1'b0;
      clk_27p5                =    1'b0;
    
      //Define any registers that we haven't already that are required for clock domain crossing
    
      radio_go_temp           =    1'b0;

      //Define the integers and registers required to drive the large-scale task models
      
      seed_epc_select_top     =    365234;
      seed_epc_write_top      =    1940459;
      seed_rn16_bits_top      =    2348023;
      seed_misc_bits_top      =    7239423;

      select_bits_top         =    28'b1010_100_010_01_00100000_01100000;               //This is sort-of made up, targeting just a match of a 96-bit EPC;
      select_blank_bits_top   =    28'b1010_100_010_01_00100000_01100000;               //This is sort-of made up, targeting just a match of a 96-bit EPC;
      query_bits_top          =    22'b1000_1_11_1_00_00_0_0111_01010;                  //Command_DR_M_TRext_Sel_Session_Tgt_Q_CRC5 (CRC5 here is fake!!!!!);
      read_bits_top           =    26'b11000010_01_00100000_00000110;                   //Read a 96b EPC starting at address 0x20. Assume words are 16b (I think they are).;
      lock_bits_top           =    {8'b11000101,20'b10_01_11_00_11__01_10_10_00_11};    //First 8 bits are the packet ID, the last 20 bits I made up randomly.
      write_bits_top          =    10'b11000011_01;                                     //First 8 bits are the command ID, second 2 bits specify the EPC MemBank.
      rn16_i_bits_top         =    16'b1100_0101_0001_1011;                             //16 bits that I just made up here.
      handle_bits_top         =    16'b0111_0010_0110_1000;                             //16 bits that I made up randomly.
    end
/////////////////////////////////////////////////////////////////////////////////////////
// Run independent clocks, generate reset, set time format, run timeout checker
/////////////////////////////////////////////////////////////////////////////////////////
    
    initial    $timeformat(-9,1,"ns",10);
    
    initial begin : catch_timeout
        #TIMEOUT_DLY
        $display("The simulation failed: we reached the timeout at time %t",$realtime);
        $stop;
    end
    
    initial    begin
        #RST_DEASSERT_DLY
        rst_n_27p5            =    1'b1;
        rst_n_4p5             =    1'b1;
    end
    
    initial begin
        forever    begin
            #CLK_4P5_HALF_PERIOD
            clk_4p5=~clk_4p5;
        end
    end
    
    initial begin
        forever    begin
            #CLK_27P5_HALF_PERIOD
            clk_27p5=~clk_27p5;
        end
    end

/////////////////////////////////////////////////////////////////////////////////////////
// Define TX_GEN ideal RAM loading, the Tag/RX BFM and the TX GEN output checker tasks and run them in initial blocks
/////////////////////////////////////////////////////////////////////////////////////////

`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_top.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_txcw0.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_select.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_select_blank_epc.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_query.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_query_rep.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_ack_rn16.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_ack_handle.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_nak.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_reqhdl.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_reqrn16.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_write.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_read.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_lock.v"
`include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_write_16b.v"

`include "../../../sim_tb/test_tx_gen_subtasks/tag_and_rx_bfm.v"

`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_top.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_txcw0.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_select.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_select_blank_epc.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_query.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_query_rep.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_ack_rn16.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_nak.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_reqrn16.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_write.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_read.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_lock.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_write_16b.v"
`include "../../../sim_tb/test_tx_gen_checker_subtasks/check_tx_gen_generate_crc16.v"
    
/////////////////////////////////////////////////////////////////////////////////////////
// Define MCU/SPI drive of rfidr_fsm.v
/////////////////////////////////////////////////////////////////////////////////////////
    
    initial    begin
        #RST_DEASSERT_DLY
        load_tx_gen_sram_top(seed_epc_select_top, seed_epc_write_top, select_bits_top, select_blank_bits_top, query_bits_top, read_bits_top, lock_bits_top, write_bits_top);
        
        //input    seed_epc_select;
        //input    seed_epc_write;
    
        //input    [27:0]    select_bits;
        //input    [27:0]    select_blank_bits;
        //input    [21:0]    query_bits;
        //input    [25:0]    read_bits;
        //input    [27:0]    lock_bits;
        //input    [9:0]    write_bits;
        
        //First, do the programming check mode. This checks to see if there is more than one tag with a blank EPC in the area.
        @(negedge clk_27p5);
        radio_mode_27p5        =    3'b001;    //Set programming check mode
        @(negedge clk_27p5);
        radio_go               =    1'b1;      //Implement a one shot for radio_go
        @(negedge clk_27p5);
        radio_go               =    1'b0;
        for (loop_misc = 0; loop_misc < 32; loop_misc = loop_misc+1)    begin
            @(negedge clk_27p5);               //Wait 32 clock cycles for radio_running to be asserted
        end
        while(radio_done ==    1'b0)    begin
            if(!radio_running)    begin
                $display("The simulation failed: radio_running was not asserted when it was supposed to be %t",$realtime);
                $stop;
            end
            @(negedge clk_27p5);
        end
        @(negedge clk_27p5);
        irq_ack    =    1'b1;
        @(negedge clk_27p5);
        irq_ack    =    1'b0;
        //Next, do the programming confirm mode. This double checks that there is only one tag with a blank EPC in the area.
        @(negedge clk_27p5);
        radio_mode_27p5        =    3'b010;    //Set programming check mode
        @(negedge clk_27p5);
        radio_go               =    1'b1;      //Implement a one shot for radio_go
        @(negedge clk_27p5);
        radio_go               =    1'b0;
        for (loop_misc = 0; loop_misc < 32; loop_misc = loop_misc+1)    begin
            @(negedge clk_27p5);               //Wait 32 clock cycles for radio_running to be asserted
        end
        while(radio_done ==    1'b0)    begin
            if(!radio_running)    begin
                $display("The simulation failed: radio_running was not asserted when it was supposed to be %t",$realtime);
                $stop;
            end
            @(negedge clk_27p5);
        end
        @(negedge clk_27p5);
        irq_ack    =    1'b1;
        @(negedge clk_27p5);
        irq_ack    =    1'b0;
        //Next, do the programming mode. This does the actual programming.
        @(negedge clk_27p5);
        radio_mode_27p5        =    3'b011;    //Set programming check mode
        @(negedge clk_27p5);
        radio_go               =    1'b1;      //Implement a one shot for radio_go
        @(negedge clk_27p5);
        radio_go               =    1'b0;
        for (loop_misc = 0; loop_misc < 32; loop_misc = loop_misc+1)    begin
            @(negedge clk_27p5);    //Wait 32 clock cycles for radio_running to be asserted
        end
        while(radio_done ==    1'b0)    begin
            if(!radio_running)    begin
                $display("The simulation failed: radio_running was not asserted when it was supposed to be %t",$realtime);
                $stop;
            end
            @(negedge clk_27p5);
        end
        @(negedge clk_27p5);
        irq_ack    =    1'b1;
        @(negedge clk_27p5);
        irq_ack    =    1'b0;
       //Next, do the search mode. This searches for the tag we just programmed.
        @(negedge clk_27p5);
        radio_mode_27p5        =    3'b000;    //Set search mode
        @(negedge clk_27p5);
        radio_go               =    1'b1;      //Implement a one shot for radio_go
        @(negedge clk_27p5);
        radio_go               =    1'b0;
        for (loop_misc = 0; loop_misc < 32; loop_misc = loop_misc+1)    begin
            @(negedge clk_27p5);    //Wait 32 clock cycles for radio_running to be asserted
        end
        while(radio_done ==    1'b0)    begin
            if(!radio_running)    begin
                $display("The simulation failed: radio_running was not asserted when it was supposed to be %t",$realtime);
                $stop;
            end
            @(negedge clk_27p5);
        end
        @(negedge clk_27p5);
        irq_ack    =    1'b1;
        @(negedge clk_27p5);
        irq_ack    =    1'b0;
        @(negedge clk_27p5);
        @(negedge clk_27p5);
        @(negedge clk_27p5);
        $display("The simulation succeeded at time %t!!!!!!!",$realtime);
        $stop;
    end

  initial    begin
    #RST_DEASSERT_DLY
    tag_and_rx_bfm(rn16_i_bits_top, handle_bits_top, seed_rn16_bits_top, seed_misc_bits_top);
            
    //input    [15:0]    rn16_i_bits;
    //input    [15:0]    handle_bits;
    //input              seed_rn16_bits;
    //input              seed_misc_bits;
  end
  
  initial    begin
    #RST_DEASSERT_DLY
    check_tx_gen_top(seed_epc_select_top, seed_epc_write_top, seed_rn16_bits_top, select_bits_top, select_blank_bits_top, query_bits_top, read_bits_top, lock_bits_top, write_bits_top,rn16_i_bits_top,handle_bits_top);
        
    //input    seed_epc_select;
    //input    seed_epc_write;
    //input    seed_rn16_bits;
    
    //input    [27:0]    select_bits;
    //input    [27:0]    select_blank_bits;
    //input    [21:0]    query_bits;
    //input    [25:0]    read_bits;
    //input    [27:0]    lock_bits;
    //input    [9:0]    write_bits;
    //input    [15:0]    rn16_i_bits;
    //input    [15:0]    handle_bits;
  end

/////////////////////////////////////////////////////////////////////////////////////////
// Declare the top level TX_GEN module. Copy it from top level.
/////////////////////////////////////////////////////////////////////////////////////////

    tx_gen    tx_gen0(
        // Inputs
        .sram_in_data(radio_sram_rdata_4p5),
        .current_rn16(rn16_to_txgen),
        .current_handle(handle_to_txgen),
        .radio_state(radio_state),
        .go(tx_go),
        .en(tx_en),
        .clk(clk_4p5),
        .rst_n(rst_n_4p5),
        // Outputs
        .shift_rn16_bits(shift_rn16_to_txgen),
        .shift_handle_bits(shift_handle_to_txgen),
        .sram_address(radio_sram_address_tx),
        .out(out_i_baseband_4p5),
        .done(tx_done),
        .last_write(last_tx_write),
        .error_outer(tx_error_4p5)                //Error in the outer loop of the FSM - must report thru SPI
    );
    
/////////////////////////////////////////////////////////////////////////////////////////
// Declare the other blocks we require to operate this simulation, again copied from top level
/////////////////////////////////////////////////////////////////////////////////////////

    rn16_and_handle_shift_regs    rn16_and_handle_shift_regs0(
        // Inputs
        .in_rn16(bit_decision_from_dr),
        .in_handle(bit_decision_from_dr),
        .shift_rn16_from_dr(shift_rn16_from_dr),
        .shift_rn16_to_txgen(shift_rn16_to_txgen),
        .shift_handle_from_dr(shift_handle_from_dr),
        .shift_handle_to_txgen(shift_handle_to_txgen),
        .rst_n(rst_n_4p5),
        .clk(clk_4p5),
        //Outputs
        .out_rn16(rn16_to_txgen),
        .out_handle(handle_to_txgen)
    );
    
    radio_sram_with_mux        radio_sram_with_mux0(
        //Inputs
        .address_a_rx({1'b1,radio_sram_address_rx}),
        .address_a_tx({1'b0,radio_sram_address_tx}),
        .address_b(radio_sram_addr_27p5),
        .clock_a(clk_4p5),
        .clock_b(clk_ram),
        .data_a(radio_sram_wdata_4p5),
        .data_b(radio_sram_wdata_27p5),
        .txrxaccess(radio_sram_txrxaccess),
        .wren_a(radio_sram_wren),
        .wren_b(radio_sram_we_data_27p5),
        //Outputs
        .q_a(radio_sram_rdata_4p5),
        .q_b(radio_sram_rdata_27p5)
    );
    
    radio_fsm    radio_fsm0(
        // *** Note that wires marked with stars "***" must undergo clock domain crossings.
        // Output signals so denoted must be launched from flops, obviously
        // ??? denotes signals that we haven't determined whether we need them or not.
        
        // Inputs
        .go(radio_go_4p5),                        //    *** From top-level FSM
        .mode(radio_mode_4p5),                    //    *** From memory-mapped registers interfacing with SPI
        .rx_done(rx_done),                        //    The RX has completed its reception, made valid its indicators, and stored its results in SRAM
        .rx_fail_crc(1'b0),                       //    The RX CRC reception has failed
        .rx_timeout(1'b0),                        //    The RX has timed out while waiting for a packet
        .rx_dlyd_err(1'b0),                       //    The RX has received an error in a delayed response packet (e.g. write)
        .rx_hndl_mmtch(1'b0),                     //    The RX has received a packet with the wrong handle
        .rx_collision(1'b0),                      //    The RX has detected a RN16 packet with a high probability of collision
        .tx_done(tx_done),                        //    The TX has completed transmitting its packet
        .last_tx_write(last_tx_write),            //    From TX_Gen - reading SRAM will tell when we are at the last word to be written
        .rst_n(rst_n_4p5),                        //    4.5MHz domain reset signal.
        .clk(clk_4p5),                            //    4.5MHz clock            
    
        // Outputs
        .state(radio_state),                      //    Tell Data Recovery / TX Gen which operation to do and which RX/TX address to place the data
        .txrxaccess(radio_sram_txrxaccess),       //    Permits either TX or RX to access the shared variable packet data RAM
        .rx_block(rx_block),                      //    Block the RX from seeing crazy TX signal
        .rx_go(rx_go),                            //    Kick off the RX DR state machine
        .rx_gain(rx_gain),                        //    Increase RX gain vis-a-vis TX cancel block and SPI
        .tx_go(tx_go),                            //    Kick off the TX Gen state machine
        .tx_en(tx_en),                            //    ??? Enable SX1257 TX, TX PA ??? - Use this to enable TX Gen CW at least
        .tx_gain(tx_gain),                        //    ??? Full power (1) for search, Low power (0) for programming ???    
        .wvfm_go(wvfm_go),                        //    Kick off waveform recording
        .busy(radio_busy_4p5),                    //    *** Tell top-level FSM and memory-mapped register that radio is busy.
        .exit_code(radio_exit_code_4p5),          //    *** Pass (0) or fail (1)
        .num_tags(radio_num_tags_4p5),            //    Tells how many blank tags were found on the latest search
        .done(radio_done_4p5)                     //    *** Tell top-level FSM that the radio FSM is done
    );
    
    rfidr_fsm    rfidr_fsm0(
        //Inputs
        .radio_go_in(radio_go),                   //    This needs to be a one-shot signal from the SPI control registers
        .radio_busy_in(radio_busy_27p5),          //    This needs to be a level-based signal from the radio
        .radio_done_in(radio_done_27p5),          //    This needs to be a one-shot signal from the radio
        .irq_acked(irq_ack),                      //    This needs to be a one-shot signal from the SPI control registers
        .clk(clk_27p5),
        .rst_n(rst_n_27p5),
        //Outputs
        .radio_go_out(radio_go_27p5),
        .radio_running(radio_running),            //    This signal is required in order to disable SPI peripheral writes and SPI peripheral feedthrough
        .radio_done_out(radio_done),
        .mcu_irq(mcu_irq_pin)
    );
    
/////////////////////////////////////////////////////////////////////////////////////////
// Define synthesizeable statement representing the double flops in the SPI peripheral-external I/F that are in clock_crossings.v
// Also represent the double flops coming from the TX cancellation engine.
/////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge clk_4p5 or negedge rst_n_4p5) begin
        if(!rst_n_4p5) begin
            radio_go_temp          <=    1'b0;
            radio_go_4p5           <=    1'b0;
            radio_mode_temp        <=    3'b0;
            radio_mode_4p5         <=    3'b0;
        end else begin
            radio_go_temp          <=    radio_go_27p5;
            radio_go_4p5           <=    radio_go_temp;
            radio_mode_temp        <=    radio_mode_27p5;
            radio_mode_4p5         <=    radio_mode_temp;
        end
    end
    
    always @(posedge clk_27p5 or negedge rst_n_27p5) begin
        if(!rst_n_27p5) begin
            radio_done_temp        <=    1'b0;
            radio_done_27p5        <=    1'b0;
            radio_busy_temp        <=    1'b0;
            radio_busy_27p5        <=    1'b0;
        end else begin
            radio_done_temp        <=    radio_done_4p5;
            radio_done_27p5        <=    radio_done_temp;
            radio_busy_temp        <=    radio_busy_4p5;
            radio_busy_27p5        <=    radio_busy_temp;
        end
    end
    
endmodule