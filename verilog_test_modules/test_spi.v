///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
// Bench : Test SPI Controller and Peripheral modules                                //
//                                                                                   //
// Filename: test_spi.v                                                              //
// Creation Date: 8/20/2016                                                          //
// Author: Edward Keehr                                                              //
//                                                                                   //
// Copyright Superlative Semiconductor LLC 2021                                      //
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2       //
// You may redistribute and modify this documentation and make products              //
// using it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).          //
// This documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED                  //
// WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY                      //
// AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2                //
// for applicable conditions.                                                        //
//                                                                                   //
// Description:                                                                      //
//    Test the SPI in loopback fashion. Do this in a quasi-BFM fashion using tasks   //
//    for various operations.                                                        //
//                                                                                   //
//    Revisions:                                                                     //
//    091816 - Fix to accomodate revised spi in which all DTC are programmed at      //
//    once, minimizing delays and avoiding glitches.                                 //
//    083021 - Replaced tabs with 4-spaces. Added copyright to header.               //
//    This file is out of date and was not re-run after cleanup for release, so      //
//    please temper expectations for use accordingly.                                //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////

// Declare the overall test module and the timing parameters

`timescale 1ns/100ps
`define NULL 0

module test_spi();

/////////////////////////////////////////////////////////////////////////////////////////
// Define Parameters
/////////////////////////////////////////////////////////////////////////////////////////

    parameter    CLK_SX1257_PERIOD        =    (0.5e9)/(36e6);
    parameter    CLK_DTC_PERIOD           =    (0.5e9)/(44e6);
    parameter    CLK_36_HALF_PERIOD       =    (0.5e9)/(360e6);    //Make a super fast clock to load in RAMs. But only have it run when needed.
    parameter    CLK_4P5_HALF_PERIOD      =    (0.5e9)/(4.5e6);
    parameter    CLK_27P5_HALF_PERIOD     =    (0.5e9)/(27.5e6);
    parameter    CLK_SPI_HALF_PERIOD      =    (0.5e9)/(4.8e6);    //Max. of NRF51822 is 4Mbps. But with respect to CLK27P5 it's effectively 4.8MHz worst case in this sim. Use a 1x clock to make the SPI clock.
    parameter    RST_DEASSERT_DLY         =    100;
    parameter    TIMEOUT_DLY              =    150000000;
    
/////////////////////////////////////////////////////////////////////////////////////////
// Declare the wires and registers required in the simulation
/////////////////////////////////////////////////////////////////////////////////////////

    //SPI dut Module Inouts
    wire              cntrlr_cipo;                //A bidirectional pin that is ordinarily tristated and used as input only when cntrlr_nps[4] is low
    reg               cntrlr_cipo_sx1257_out;
    reg               cntrlr_cipo_sx1257_drive;
    
    //SPI dut Module Inputs
    reg               prphrl_copi_extl;       //Double flop synchronizer external to this block
    reg               prphrl_nps_extl;        //Double flop synchronizer external to this block
    reg               prphrl_pclk_extl;       //Double flop synchronizer external to this block
    reg               prphrl_copi_temp;       //Double flop synchronizer external to this block
    reg               prphrl_nps_temp;        //Double flop synchronizer external to this block
    reg               prphrl_pclk_temp;       //Double flop synchronizer external to this block
    reg               prphrl_copi_27p5;       //Needs double flop synchronizer external to this block
    reg               prphrl_nps_27p5;        //Needs double flop synchronizer external to this block
    reg               prphrl_pclk_27p5;       //Needs double flop synchronizer external to this block
    
    reg               clk_pclk_nrf51822;      //Represent the clock really running in the NRF51822 that generates its controller pclk
    
    reg               clk_4p5;
    reg               clk_27p5;               //27p5MHz clock 
    reg               rst_n_27p5;
    
    reg     [7:0]     txcancel_data_4p5;       //Double flop synchronizer external to this block
    reg     [14:0]    txcancel_data_aux_4p5;   //Double flop synchronizer external to this block
    reg               txcancel_csel_4p5;       //Double flop synchronizer external to this block
    reg               txcancel_rdy_4p5;        //Double flop synchronizer external to this block
    reg     [7:0]     txcancel_data_temp;      //Double flop synchronizer external to this block
    reg     [14:0]    txcancel_data_aux_temp;  //Double flop synchronizer external to this block
    reg               txcancel_csel_temp;      //Double flop synchronizer external to this block
    reg               txcancel_rdy_temp;       //Double flop synchronizer external to this block
    reg     [7:0]     txcancel_data_27p5;      //Double flop synchronizer external to this block
    reg     [14:0]    txcancel_data_aux_27p5;  //Double flop synchronizer external to this block
    reg               txcancel_csel_27p5;      //Needs double flop synchronizer external to this block
    reg               txcancel_rdy_27p5;       //Needs double flop synchronizer external to this block
    
    //SPI dut Module Inputs related to control registers
    
    reg               wave_storage_running;    //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg               wave_storage_done;       //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg     [2:0]     radio_exit_code;         //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg     [3:0]     radio_num_tags;          //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg               radio_done;              //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg               radio_running;           //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg     [2:0]     tx_error;                //Needs double flop synchronizer external to this block - ignore 2-flop-sync here b/c this is a relatively static signal whose timing is not critical
    reg               clk_36_valid;
    reg               clk_36_running;

    //SPI dut Module Outputs
    wire              prphrl_cipo;
    
    wire    [9:0]      radio_sram_addr;
    wire    [7:0]      radio_sram_wdata;
    wire               radio_sram_we_data;
    wire    [9:0]      txcancel_sram_addr;
    wire    [7:0]      txcancel_sram_wdata;
    wire               txcancel_sram_we_data;
    wire    [12:0]     wvfm_sram_addr;
    wire               cntrlr_nps_rdio;        //One-hot encoded since this maps to pins 4:Radio; 3-0: DTCs
    wire               cntrlr_nps_dtc;
    wire               cntrlr_pclk;
    wire               cntrlr_copi_cap3;
    wire               cntrlr_copi_cap2;
    wire               cntrlr_copi_cap1;
    wire               cntrlr_copi_cap0_rdio;
    
    wire               irq_spi;                //Added 081916
    
    wire               radio_ack;              //Assert this when txcancel_rdy is high and packet has been processed
    
    //SPI dut Module Outputs related to control registers
    
    wire               go_radio;
    wire               irq_ack;
    wire    [2:0]      radio_mode;
    wire               sw_reset;
    wire    [7:0]      wvfm_offset;
    wire               clk_36_start;
    wire               use_i;
    
    //Declare wire associated with the IRQ clock stretcher
    
    wire               mcu_irq_pin;
    
    //Declare regs and wires associated with the RAM modules
    
    wire    [7:0]      radio_sram_rdata;
    wire    [7:0]      wvfm_sram_rdata;
    wire    [7:0]      txcancel_sram_rdata;
    
    reg     [8:0]      radio_sram_address_rx_ideal;
    reg     [8:0]      radio_sram_address_tx_ideal;
    reg     [7:0]      radio_sram_wdata_ideal;
    reg                radio_sram_txrxaccess_ideal;
    reg                radio_sram_wren_ideal;
    wire    [7:0]      radio_sram_rdata_ideal;
    reg     [9:0]      txcancel_mem_ideal_raddr;
    wire    [7:0]      txcancel_mem_ideal_rdata;
    reg     [7:0]      wave_ram_ideal_wdata;
    reg     [12:0]     wave_ram_ideal_waddr;
    reg                clk_36;
    reg                wave_ram_ideal_wren;
    
    //Define globally accessible memories
    
    reg     [7:0]      sx1257_mem[0:127];
    reg     [7:0]      dtc_mem[0:3];
    integer            loop_ram_init;            //A loop variable for RAM initialization
    
/////////////////////////////////////////////////////////////////////////////////////////
// Initialize variables
/////////////////////////////////////////////////////////////////////////////////////////

    initial begin
        prphrl_copi_extl          =    1'b0;
        prphrl_nps_extl           =    1'b1;
        prphrl_pclk_extl          =    1'b0;
        prphrl_copi_temp          =    1'b0;
        prphrl_nps_temp           =    1'b1;
        prphrl_pclk_temp          =    1'b0;
        prphrl_copi_27p5          =    1'b0;
        prphrl_nps_27p5           =    1'b1;
        prphrl_pclk_27p5          =    1'b0;
        clk_pclk_nrf51822         =    1'b0;
    
        clk_4p5                   =    1'b0;
        clk_27p5                  =    1'b0;
        rst_n_27p5                =    1'b0;
    
        txcancel_data_4p5         =    8'b0;
        txcancel_data_aux_4p5     =    15'b0;
        txcancel_csel_4p5         =    1'b0;
        txcancel_rdy_4p5          =    1'b0;
        txcancel_data_temp        =    8'b0;
        txcancel_data_aux_temp    =    15'b0;
        txcancel_csel_temp        =    1'b0;
        txcancel_rdy_temp         =    1'b0;
        txcancel_data_27p5        =    8'b0;
        txcancel_data_aux_27p5    =    15'b0;
        txcancel_csel_27p5        =    1'b0;
        txcancel_rdy_27p5         =    1'b0;
        radio_running             =    1'b0;
    
    //SPI dut Module Inputs related to control registers
    
        wave_storage_running      =    1'b0;
        wave_storage_done         =    1'b0;
        radio_exit_code           =    3'b0;
        radio_num_tags            =    4'b0;
        radio_done                =    1'b0;
        radio_running             =    1'b0;
        tx_error                  =    3'b0;
        clk_36_valid              =    1'b0;
        clk_36_running            =    1'b0;
        
    //Initialize registers related to driving the SRAMs

        radio_sram_address_rx_ideal    =    9'b0;
        radio_sram_address_tx_ideal    =    9'b0;
        radio_sram_wdata_ideal         =    8'b0;
        radio_sram_txrxaccess_ideal    =    1'b0;
        radio_sram_wren_ideal          =    1'b0;
        txcancel_mem_ideal_raddr       =    10'b0;
        wave_ram_ideal_wdata           =    8'b0;
        wave_ram_ideal_waddr           =    13'b0;
        clk_36                         =    1'b0;
        wave_ram_ideal_wren            =    1'b0;
        
    //Initialize SX1257 and DTC RAMs
    
        for(loop_ram_init=0; loop_ram_init < 128; loop_ram_init=loop_ram_init+1)    begin
            sx1257_mem[loop_ram_init]    =    8'b0;
        end
        for(loop_ram_init=0; loop_ram_init < 4; loop_ram_init=loop_ram_init+1)    begin
            dtc_mem[loop_ram_init]       =    8'b0;
        end
        
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
        rst_n_27p5                =    1'b1;
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
    
    initial begin
        forever    begin
            #CLK_SPI_HALF_PERIOD
            clk_pclk_nrf51822=~clk_pclk_nrf51822;
        end
    end
    
/////////////////////////////////////////////////////////////////////////////////////////
// Define SX1257 modeling behavior
/////////////////////////////////////////////////////////////////////////////////////////
    
    //This block is written according to the understanding that the forever block is evaluated once per time step
    //One problem - if we use @(negedge) or wait() statements to halt the state machine, we can't exit the state
    //machine if we see NPS inadvertently go high.
    //Therefore, we use if statements to capture the proper behavior.
    //The only issue here is that we must use state to track the level of the pclk.
    //Enclose the forever block in a task. This way we can define locally scoped variables and parameters.
    //One thing we don't want locally scoped is the sx1257 memory. We'll declare this elsewhere.
    //Hopefully this works - the worry is that the task will not run in parallel with other code in this file.
    
    assign    cntrlr_cipo                =    cntrlr_cipo_sx1257_drive ? cntrlr_cipo_sx1257_out : 1'bz;
    
    initial    begin: run_sx1257_proc
        sx1257_proc;
    end
    
    task sx1257_proc;
    
        parameter    SX1257_IDLE                 =    3'd0;
        parameter    SX1257_WNR_BIT_PCLK_LOW     =    3'd1;
        parameter    SX1257_WNR_BIT_PCLK_HIGH    =    3'd2;
        parameter    SX1257_RX_ADDR_CLK_LOW      =    3'd3;
        parameter    SX1257_RX_ADDR_CLK_HIGH     =    3'd4;
        parameter    SX1257_RX_DATA_CLK_LOW      =    3'd5;
        parameter    SX1257_RX_DATA_CLK_HIGH     =    3'd6;
        parameter    SX1257_LIMBO                =    3'd7;
        
        reg    [2:0]    sx1257_state;
        reg    [3:0]    sx1257_ctr;
        reg    [6:0]    sx1257_addr;
        reg    [7:0]    sx1257_rdata;
        reg    [7:0]    sx1257_wdata;
        reg             sx1257_wnr_bit;
        
        integer    sx1257_addr_int;
    
        begin
            sx1257_state               =    SX1257_IDLE;
            cntrlr_cipo_sx1257_drive    =    1'b0;
            cntrlr_cipo_sx1257_out      =    1'bz;
            forever    begin
                #CLK_SX1257_PERIOD
                case(sx1257_state)
                    SX1257_IDLE: begin
                        cntrlr_cipo_sx1257_drive       =    1'b0;
                        cntrlr_cipo_sx1257_out         =    1'bz;       //Must tristate when NPS goes low
                        sx1257_ctr                     =    4'b0;       //Indirectly initialize state variables after a reset
                        sx1257_addr                    =    7'b0;
                        sx1257_rdata                   =    8'b0;
                        sx1257_wdata                   =    8'b0;
                        if(!cntrlr_nps_rdio && !cntrlr_pclk) begin        //Stay here and wait until we get a falling edge on cntrlr_nps_radio
                            sx1257_state               =    SX1257_WNR_BIT_PCLK_LOW;
                        end
                    end
                    SX1257_WNR_BIT_PCLK_LOW: begin
                        cntrlr_cipo_sx1257_drive       =    1'b1;
                        cntrlr_cipo_sx1257_out         =    1'b0;
                        if (cntrlr_pclk) begin
                            sx1257_wnr_bit             =    cntrlr_copi_cap0_rdio;
                            sx1257_state               =    SX1257_WNR_BIT_PCLK_HIGH;
                        end
                        if(cntrlr_nps_rdio)    begin
                            cntrlr_cipo_sx1257_drive   =    1'b0;
                            cntrlr_cipo_sx1257_out     =    1'bz;       //Must tristate when NPS goes low
                            sx1257_state               =    SX1257_IDLE;
                        end
                    end
                    SX1257_WNR_BIT_PCLK_HIGH: begin
                        cntrlr_cipo_sx1257_drive       =    1'b1;
                        cntrlr_cipo_sx1257_out         =    1'b0;
                        if(!cntrlr_pclk)    begin
                            sx1257_state               =    SX1257_RX_ADDR_CLK_LOW;
                        end
                        if(cntrlr_nps_rdio)    begin
                            cntrlr_cipo_sx1257_drive   =    1'b0;
                            cntrlr_cipo_sx1257_out     =    1'bz;       //Must tristate when NPS goes low
                            sx1257_state               =    SX1257_IDLE;
                        end
                    end
                    SX1257_RX_ADDR_CLK_LOW: begin
                        cntrlr_cipo_sx1257_drive       =    1'b1;
                        cntrlr_cipo_sx1257_out         =    1'b0;
                        if(cntrlr_pclk)    begin
                            sx1257_ctr                 =    sx1257_ctr+4'd1;
                            sx1257_addr                =    {sx1257_addr[5:0],cntrlr_copi_cap0_rdio};
                            sx1257_state               =    SX1257_RX_ADDR_CLK_HIGH;
                        end
                        if(cntrlr_nps_rdio)    begin
                            cntrlr_cipo_sx1257_drive   =    1'b0;
                            cntrlr_cipo_sx1257_out     =    1'bz;       //Must tristate when NPS goes low
                            sx1257_state               =    SX1257_IDLE;
                        end
                    end
                    SX1257_RX_ADDR_CLK_HIGH: begin
                        cntrlr_cipo_sx1257_drive       =    1'b1;
                        cntrlr_cipo_sx1257_out         =    1'b0;
                        if(!cntrlr_pclk && sx1257_ctr < 4'd7)    begin
                            sx1257_state               =    SX1257_RX_ADDR_CLK_LOW;
                        end
                        if(!cntrlr_pclk && sx1257_ctr >= 4'd7)    begin
                            sx1257_ctr                 =    4'b0;
                            sx1257_addr_int            =    sx1257_addr;
                            sx1257_wdata               =    sx1257_mem[sx1257_addr_int];
                            //$display("Addr Int: %d Data Int:%b at time %t",sx1257_addr_int,sx1257_wdata,$realtime);
                            cntrlr_cipo_sx1257_drive   =    1'b1;
                            cntrlr_cipo_sx1257_out     =    sx1257_wdata[7];
                            sx1257_wdata               =    {sx1257_wdata[6:0],1'b0};
                            sx1257_state               =    SX1257_RX_DATA_CLK_LOW;
                        end
                        if(cntrlr_nps_rdio)    begin
                            cntrlr_cipo_sx1257_drive   =    1'b0;
                            cntrlr_cipo_sx1257_out     =    1'bz;        //Must tristate when NPS goes low
                            sx1257_state               =    SX1257_IDLE;
                        end
                    end
                    SX1257_RX_DATA_CLK_LOW: begin
                        if(cntrlr_pclk)    begin
                            sx1257_ctr                 =    sx1257_ctr+4'd1;
                            sx1257_rdata               =    {sx1257_rdata[6:0],cntrlr_copi_cap0_rdio};
                            sx1257_state               =    SX1257_RX_DATA_CLK_HIGH;
                        end
                        if(cntrlr_nps_rdio)    begin
                            cntrlr_cipo_sx1257_drive   =    1'b0;
                            cntrlr_cipo_sx1257_out     =    1'bz;       //Must tristate when NPS goes low
                            sx1257_state               =    SX1257_IDLE;
                        end
                    end
                    SX1257_RX_DATA_CLK_HIGH: begin
                        if(!cntrlr_pclk && sx1257_ctr < 4'd8)    begin
                            cntrlr_cipo_sx1257_drive   =    1'b1;
                            cntrlr_cipo_sx1257_out     =    sx1257_wdata[7];
                            sx1257_wdata               =    {sx1257_wdata[6:0],1'b0};
                            sx1257_state               =    SX1257_RX_DATA_CLK_LOW;
                        end
                        if(!cntrlr_pclk && sx1257_ctr >= 4'd8)    begin
                            sx1257_ctr                =    4'b0;
                            if(sx1257_wnr_bit) begin
                                sx1257_addr_int       =    sx1257_addr;
                                sx1257_mem[sx1257_addr_int]    =    sx1257_rdata;
                            end
                            sx1257_state              =    SX1257_LIMBO;    
                        end
                        if(cntrlr_nps_rdio)    begin
                            cntrlr_cipo_sx1257_drive  =    1'b0;
                            cntrlr_cipo_sx1257_out    =    1'bz;    //Must tristate when NPS goes low
                            sx1257_state              =    SX1257_IDLE;
                        end
                    end
                    SX1257_LIMBO: begin                            //Wait for rise of NPS or PCLK to determine a return to idle or BURST mode
                        if(cntrlr_nps_rdio)    begin
                            //While waiting for this to happen in the wait statement at the beginning of this simulation, SX1257 and FPGA will drive each other
                            //This results in a short 1'bx on cntrlr_cipo in the simulation.
                            //This is a simulation artifact that does nothing and I'm not going to solve it at the moment.
                            cntrlr_cipo_sx1257_drive   =    1'b0;
                            cntrlr_cipo_sx1257_out     =    1'bz;    //Must tristate when NPS goes low
                            sx1257_state               =    SX1257_IDLE;
                        end
                        if(cntrlr_pclk)    begin                    //Engage burst mode - do not change wnr bit
                            sx1257_addr                =    sx1257_addr+6'd1;
                            sx1257_ctr                 =    4'b0;
                            sx1257_addr_int            =    sx1257_addr;
                            sx1257_wdata               =    sx1257_mem[sx1257_addr_int];
                            cntrlr_cipo_sx1257_drive   =    1'b1;
                            cntrlr_cipo_sx1257_out     =    sx1257_wdata[7];
                            sx1257_wdata               =    {sx1257_wdata[6:0],1'b0};
                            sx1257_state               =    SX1257_RX_DATA_CLK_LOW;
                        end
                    end    
                endcase
            end
        end
    endtask
/////////////////////////////////////////////////////////////////////////////////////////
// Define DTC modeling behavior
/////////////////////////////////////////////////////////////////////////////////////////
    // Here we make a task for all DTC at once, although we run them individually.
    // We separate the tasks by having them access different parts of the DTC RAM.
    
    initial    begin: run_dtc_procs
        fork
            begin
                dtc_proc(2'd0);
            end
            begin
                dtc_proc(2'd1);
            end
            begin
                dtc_proc(2'd2);
            end
            begin
                dtc_proc(2'd3);
            end
        join
    end
    
    //initial    begin: run_dtc_0_proc
    //    dtc_proc(2'd0);
    //end
    //initial    begin: run_dtc_1_proc
    //    dtc_proc(2'd1);
    //end
    //initial    begin: run_dtc_2_proc
    //    dtc_proc(2'd2);
    //end
    //initial    begin: run_dtc_3_proc
    //    dtc_proc(2'd3);
    //end
    
    task automatic dtc_proc;
    
        input    [1:0]    dtc_addr;
    
        parameter    DTC_IDLE                    =    2'd0;
        parameter    DTC_RX_DATA_CLK_LOW         =    2'd1;
        parameter    DTC_RX_DATA_CLK_HIGH        =    2'd2;
        parameter    DTC_LIMBO                   =    2'd3;
        
        reg             cntrlr_copi_intl;
        reg    [1:0]    dtc_state;
        reg    [3:0]    dtc_ctr;
        reg    [7:0]    dtc_rdata;
        integer         dtc_addr_intl;
    
        begin
            dtc_state        =    DTC_IDLE;
            dtc_addr_intl    =    dtc_addr;
            forever    begin
                #CLK_DTC_PERIOD
                case(dtc_addr)
                    2'd0:    begin    cntrlr_copi_intl    =    cntrlr_copi_cap0_rdio;    end
                    2'd1:    begin    cntrlr_copi_intl    =    cntrlr_copi_cap1;         end
                    2'd2:    begin    cntrlr_copi_intl    =    cntrlr_copi_cap2;         end
                    2'd3:    begin    cntrlr_copi_intl    =    cntrlr_copi_cap3;         end
                endcase
                    
                case(dtc_state)
                    DTC_IDLE: begin
                        dtc_ctr              =    4'b0;                //Indirectly initialize state variables after a reset
                        dtc_rdata            =    8'b0;
                        if(cntrlr_nps_dtc && !cntrlr_pclk) begin       //Stay here and wait until cntrlr_nps is low
                            dtc_state        =    DTC_RX_DATA_CLK_LOW;
                            //$display("Does this ever work");
                        end
                    end
                    DTC_RX_DATA_CLK_LOW: begin
                        if(cntrlr_pclk)    begin
                            dtc_ctr          =    dtc_ctr+4'd1;
                            dtc_rdata        =    {dtc_rdata[6:0],cntrlr_copi_intl};
                            dtc_state        =    DTC_RX_DATA_CLK_HIGH;
                        end
                        if(!cntrlr_nps_dtc)
                            dtc_state        =    DTC_IDLE;
                    end
                    DTC_RX_DATA_CLK_HIGH: begin
                        if(!cntrlr_pclk && dtc_ctr < 4'd8)    begin
                            dtc_state        =    DTC_RX_DATA_CLK_LOW;
                        end
                        if(!cntrlr_pclk && dtc_ctr >= 4'd8)    begin
                            dtc_mem[dtc_addr_intl]    =    dtc_rdata;
                            //$display("Testing DTC memory acceptance addr:%d data:%b at time %t",dtc_addr_intl,dtc_rdata,$realtime);
                            dtc_state        =    DTC_LIMBO;    
                        end
                        if(!cntrlr_nps_dtc)
                            dtc_state    =    DTC_IDLE;
                    end
                    DTC_LIMBO: begin                            //Wait for fall of NPS to determine a return to idle
                        if(!cntrlr_nps_dtc)
                            dtc_state    =    DTC_IDLE;
                    end    
                    default:    begin
                        dtc_state    =    DTC_IDLE;
                    end
                endcase
            end
        end
    endtask
    
/////////////////////////////////////////////////////////////////////////////////////////
// Declare the top level SPI module.
/////////////////////////////////////////////////////////////////////////////////////////

    spi    dut
        (

            //SPI dut module Inouts
            .cntrlr_cipo(cntrlr_cipo),                    //A bidirectional pin that is ordinarily tristated and used as input only when cntrlr_nps[4] is low
    
            //SPI dut module Inputs
            .prphrl_copi(prphrl_copi_27p5),               //Needs double flop synchronizer external to this block
            .prphrl_nps(prphrl_nps_27p5),                 //Needs double flop synchronizer external to this block
            .prphrl_pclk(prphrl_pclk_27p5),               //Needs double flop synchronizer external to this block
    
            .radio_sram_rdata(radio_sram_rdata),
            .wvfm_sram_rdata(wvfm_sram_rdata),
            .txcancel_sram_rdata(txcancel_sram_rdata),
    
            .clk(clk_27p5),                               //27p5MHz clock 
            .rst_n(rst_n_27p5),                
    
            .txcancel_data(txcancel_data_27p5),           //Needs double flop synchronizer external to this block
            .txcancel_data_aux(txcancel_data_aux_27p5),   //Needs double flop synchronizer external to this block
            .txcancel_csel(txcancel_csel_27p5),           //Needs double flop synchronizer external to this block
            .txcancel_rdy(txcancel_rdy_27p5),             //Needs double flop synchronizer external to this block
    
            //SPI dut module Inputs related to control registers
    
            .wave_storage_running(wave_storage_running),  //Needs double flop synchronizer external to this block
            .wave_storage_done(wave_storage_done),        //Needs double flop synchronizer external to this block
            .radio_exit_code(radio_exit_code),            //Needs double flop synchronizer external to this block
            .radio_num_tags(radio_num_tags),              //Needs double flop synchronizer external to this block
            .radio_done(radio_done),                      //Needs double flop synchronizer external to this block
            .radio_running(radio_running),                //Needs double flop synchronizer external to this block
            .tx_error(tx_error),                          //Needs double flop synchronizer external to this block
            .clk_36_valid(clk_36_valid),
            .clk_36_running(clk_36_running),

            //SPI dut module Outputs
            .prphrl_cipo(prphrl_cipo),
    
            .radio_sram_addr(radio_sram_addr),
            .radio_sram_wdata(radio_sram_wdata),
            .radio_sram_we_data(radio_sram_we_data),
            .txcancel_sram_addr(txcancel_sram_addr),
            .txcancel_sram_wdata(txcancel_sram_wdata),
            .txcancel_sram_we_data(txcancel_sram_we_data),
            .wvfm_sram_addr(wvfm_sram_addr),
            .cntrlr_nps_rdio(cntrlr_nps_rdio),
            .cntrlr_nps_dtc(cntrlr_nps_dtc),
            .cntrlr_pclk(cntrlr_pclk),
            .cntrlr_copi_cap3(cntrlr_copi_cap3),
            .cntrlr_copi_cap2(cntrlr_copi_cap2),
            .cntrlr_copi_cap1(cntrlr_copi_cap1),
            .cntrlr_copi_cap0_rdio(cntrlr_copi_cap0_rdio),
    
            .radio_ack(radio_ack),                        //Assert this when txcancel_rdy is high and packet has been processed
            .irq_spi(irq_spi),
    
            //SPI dut module Outputs related to control registers
    
            .go_radio(go_radio),
            .irq_ack(irq_ack),
            .radio_mode(radio_mode),
            .sw_reset(sw_reset),
            .wvfm_offset(wvfm_offset),
            .clk_36_start(clk_36_start),
            .use_i(use_i)
        );

/////////////////////////////////////////////////////////////////////////////////////////
// Declare the IRQ merger and stretcher
/////////////////////////////////////////////////////////////////////////////////////////
        
    irq_merge    irq_merge0(
        .irq_fsm(1'b0),
        .irq_clock(1'b0),
        .irq_spi(irq_spi),
        .irq_extra(1'b0),
        .clk_27p5(clk_27p5),
        .rst_n_27p5(rst_n_27p5),
        .mcu_irq(mcu_irq_pin)
    );    
        
/////////////////////////////////////////////////////////////////////////////////////////
// Declare the 3 RAMs that will be interfacing with the SPI
/////////////////////////////////////////////////////////////////////////////////////////

    radio_sram_with_mux        radio_sram_with_mux0(
        //Inputs
        .address_a_rx({1'b1,radio_sram_address_rx_ideal}),    //Need to make a reg [8:0] radio_sram_address_rx_ideal
        .address_a_tx({1'b0,radio_sram_address_tx_ideal}),    //Need to make a reg [8:0] radio_sram_address_tx_ideal
        .address_b(radio_sram_addr),
        .clock_a(clk_36),                                     //We'll run it with the uber fast clk_36
        .clock_b(clk_27p5),
        .data_a(radio_sram_wdata_ideal),                      //Need to make a reg [7:0] radio_sram_wdata_ideal
        .data_b(radio_sram_wdata),
        .txrxaccess(radio_sram_txrxaccess_ideal),             //Need to make a reg radio_sram_txrxaccess_ideal
        .wren_a(radio_sram_wren_ideal),                       //Need to make a reg radio_sram_wren_ideal
        .wren_b(radio_sram_we_data),
        //Outputs
        .q_a(radio_sram_rdata_ideal),                         //Need to make a wire [7:0]    radio_sram_rdata_ideal
        .q_b(radio_sram_rdata)
    );
        
    txcancel_mem txcancel_mem_0(
        .data_a(8'b0),
        .address_a(txcancel_mem_ideal_raddr),                 //Need to make a reg [9:0]    txcancel_mem_ideal_raddr
        .clock_a(clk_36),                                     //We'll run it with the uber fast clk_36
        .wren_a(1'b0),        
        .q_a(txcancel_mem_ideal_rdata),                       //Need to make a reg [7:0]    txcancel_mem_ideal_rdata
        .data_b(txcancel_sram_wdata),
        .address_b(txcancel_sram_addr),
        .clock_b(clk_27p5),
        .wren_b(txcancel_sram_we_data),
        .q_b(txcancel_sram_rdata)
    ); //a = txcancel side (4.5MHz), b=spi side (27.5MHz)
    
    wave_storage_ram wave_ram_0(
        .data(wave_ram_ideal_wdata),                          //Need to make a reg [7:0]    wave_ram_ideal_wdata
        .rd_aclr(rst_p_36),                                   //Need to make a rst_p_36 (that goes uber fast)
        .rdaddress({1'b0,wvfm_sram_addr}),
        .rdclock(clk_27p5),
        .rdclocken(1'b1),
        .wraddress({1'b0,wave_ram_ideal_waddr}),              //Need to make a reg [12:0]    wave_ram_ideal_waddr
        .wrclock(clk_36),                                     //Need to make a reg clk_36 that runs uber fast
        .wrclocken(1'b1),
        .wren(wave_ram_ideal_wren),                           //Need to make a reg    wave_ram_ideal_wren
        .q(wvfm_sram_rdata)
    );
        
/////////////////////////////////////////////////////////////////////////////////////////
// Define synthesizeable statement representing the double flops in the SPI prphrl-external I/F that are in clock_crossings.v
// Also represent the double flops coming from the TX cancellation engine.
/////////////////////////////////////////////////////////////////////////////////////////
        
    always@(posedge clk_27p5 or negedge rst_n_27p5) begin
        if(!rst_n_27p5) begin
            prphrl_copi_temp              <=    1'b0;
            prphrl_nps_temp               <=    1'b0;
            prphrl_pclk_temp              <=    1'b0;
            prphrl_copi_27p5              <=    1'b0;
            prphrl_nps_27p5               <=    1'b0;
            prphrl_pclk_27p5              <=    1'b0;
            
            txcancel_data_temp            <=    8'b0;
            txcancel_data_aux_temp        <=    15'b0;
            txcancel_csel_temp            <=    1'b0;
            txcancel_rdy_temp             <=    1'b0;
            txcancel_data_27p5            <=    8'b0;
            txcancel_data_aux_27p5        <=    15'b0;
            txcancel_csel_27p5            <=    1'b0;
            txcancel_rdy_27p5             <=    1'b0;
        end else begin
            prphrl_copi_temp              <=    prphrl_copi_extl;
            prphrl_nps_temp               <=    prphrl_nps_extl;
            prphrl_pclk_temp              <=    prphrl_pclk_extl;
            prphrl_copi_27p5              <=    prphrl_copi_temp;
            prphrl_nps_27p5               <=    prphrl_nps_temp;
            prphrl_pclk_27p5              <=    prphrl_pclk_temp;
            
            txcancel_data_temp            <=    txcancel_data_4p5;
            txcancel_data_aux_temp        <=    txcancel_data_aux_4p5;
            txcancel_csel_temp            <=    txcancel_csel_4p5;
            txcancel_rdy_temp             <=    txcancel_rdy_4p5;
            txcancel_data_27p5            <=    txcancel_data_temp;
            txcancel_data_aux_27p5        <=    txcancel_data_aux_temp;
            txcancel_csel_27p5            <=    txcancel_csel_temp;
            txcancel_rdy_27p5             <=    txcancel_rdy_temp;
        end
    end
        
/////////////////////////////////////////////////////////////////////////////////////////
// Define Low Level Tasks
/////////////////////////////////////////////////////////////////////////////////////////
    
    //Write a general task for reading and writing from the MCU SPI Controller
    //Note that cipo in this case doesn't need to be tristated since the only peripheral addressed by the MCU is the FPGA
    
    task    wr_3byte_transaction_from_mcu_spi_cntrlr;
        //Emulate NRF51822 SPI CPHA=0; namely, data transitions on the falling edge and is sampled on the rising edge
        //This means that the first data must be placed on the line a half clock cycle prior to the first rising edge
        //Inputs from simulation
        //input                   prphrl_cipo;     - Access as global variable
        //Input arguments
        input                     write_readb;
        input            [13:0]   address;
        input            [7:0]    data_in;
        input            [7:0]    data_return_ideal;
        //Outputs
        //output                  prphrl_copi; - Access as global variable
        //output                  prphrl_nps;  - Access as global variable
        //output                  prphrl_pclk; - Access as global variable
        //Task Declarations
        reg              [7:0]    data_return;
        //Local Variable Declarations
        reg    signed    [5:0]    loop_i;    //Use a reg instead of an integer to ensure that we are properly using case syntax.
        reg    signed    [5:0]    loop_j;
        reg              [22:0]   tx_data;
        //Task statement
        begin
            tx_data                =    {write_readb,address,data_in};    //As per our LUT optimizations, we adopted a unified memory map for the FPGA. Writes to the SX1257 are done through the user register map.
            prphrl_nps_extl        =    1'b0;                             //Drive chip select low to signal the start of a transaction
            @(posedge clk_pclk_nrf51822);                                 //This two clock cycle delay is based on the diagrams in the NRF51822 reference manual (page 134) but may not in fact be accurate
            @(posedge clk_pclk_nrf51822);
            for (loop_i = 6'sd31; loop_i >= 6'sd0; loop_i=loop_i-6'sd1)    begin
                loop_j    =    loop_i-6'sd9;
                @(negedge clk_pclk_nrf51822);                             //Data changes on the falling edge. 
                if(loop_i < 6'sd31)    begin
                    prphrl_pclk_extl   =    1'b0;                         //Except for the first data transition, have the clock edge fall. We will need an extra clock FE after the final RE
                end
                if(loop_i >= 6'sd9 && loop_i <= 6'sd31) begin
                    prphrl_copi_extl   =    tx_data[loop_j[4:0]];         //Play the tx_data vector backwards
                end else begin
                    prphrl_copi_extl   =    1'b0;
                end
                @(posedge clk_pclk_nrf51822);
                prphrl_pclk_extl       =    1'b1;
                if(loop_i < 6'sd8) begin
                    data_return[loop_i[4:0]]    =    prphrl_cipo;         //Data is captured on the rising edge
                end
            end
            @(negedge clk_pclk_nrf51822)
            prphrl_pclk_extl    =    1'b0;                                //Have the final falling clock edge to complete the bit transfer portion of the transaction
        
            if(data_return_ideal != data_return)    begin
                $display("The simulation failed: data returned %b did not equal data returned %b ideal at time %t",data_return,data_return_ideal,$realtime);
                $stop;
            end
            
            @(posedge clk_pclk_nrf51822);                                 //This two clock cycle delay is based on the diagrams in the NRF51822 reference manual (page 134) but may not in fact be accurate
            @(posedge clk_pclk_nrf51822);
            prphrl_nps_extl        =    1'b1;                             //Drive chip select high to signal the end of a transaction
            @(posedge clk_pclk_nrf51822);                                 //Give a 2 clock cycle delay before we attempt any other transactions.
            @(posedge clk_pclk_nrf51822);
        end
    endtask
    
    //Write a task for writing the SPI from the TX Cancellation Circuit
        
    task    write_spi_from_txcancel_module;
        //Emulate the SPI-interfacing portion of tx_cancel.v
        //Each assertion of this task results in csel and data being placed on their respective lines and the rdy signal asserted one clock cycle later.
        //This task then waits for the spi controller to assert its ack, at which point it permits the simulation to proceeed.
        //If the ack does not come within a predefined time interval after rdy is asserted (an SVA assertion would be helpful here), then flag an error.
        
        //How is this ultimately checked?
        //1. In a separate initial block we need to review the RAMs of the DTCs
        //2. We should later pull the SX1257 value out through the NRF51822 SPI interface.
        
        //Inputs from simulation
        
        //input            radio_ack;
        
        //Outputs to simulation
        
        //output    [7:0]    txcancel_data_4p5;
        //output    [2:0]    txcancel_csel_4p5;
        //output             txcancel_rdy_4p5;
        
        //Input arguments
        input    [7:0]     data;
        input    [14:0]    data_aux;
        input              csel;
        
        //Task Declarations
        //Local Variable Declarations
        reg                rcvd_ack_flag;
        integer            loop_i;
        
        //Task statement
        begin
            rcvd_ack_flag            =    1'b0;
            txcancel_rdy_4p5         =    1'b0;
            @(posedge clk_4p5);
            txcancel_data_4p5        =    data;
            txcancel_data_aux_4p5    =    data_aux;
            txcancel_csel_4p5        =    csel;
            @(posedge clk_4p5);
            txcancel_rdy_4p5         =    1'b1;
            for(loop_i = 0; loop_i  <= 128; loop_i=loop_i+1)    begin : check_ack //We need to allow time to complete the transaction - up to 4*16 clk_27p5 plus some margin
                @(posedge clk_27p5);
                if(radio_ack)    begin
                    rcvd_ack_flag    =    1'b1;
                    disable check_ack;
                end
            end
            if(rcvd_ack_flag == 1'b0) begin
                $display("The simulation failed: TX cancellation circuit did not receive an ACK from SPI Controller at time %t",$realtime);
                $stop;
            end    
            @(posedge clk_4p5);
            txcancel_rdy_4p5         =    1'b0;
            txcancel_data_4p5        =    8'b0;
            txcancel_data_aux_4p5    =    8'b0;
            txcancel_csel_4p5        =    1'b0;
        end
    endtask
            
    //Write a task for writing a byte to the waveform RAM.
    //Although we can load this RAM up like we did in the waveform test bench, it will be easier if we just set the random seed and loop out a bunch of rand iterations.
    //Then to check we just loop through the same rand iterations after reasserting the seed
    //We drive clk_36 using this module using the delay time statement #CLK_36_HALF_PERIOD
    
    task    write_byte_waveform_sram;
        //Inputs from simulation (global)
        
        //None!!!!            
        
        //Outputs to simulation (global)
        
        //output    [7:0]     wave_ram_ideal_wdata;
        //output    [12:0]    wave_ram_ideal_waddr;
        //output              wave_ram_ideal_wren;
        //output              clk_36;
        
        //Input arguments
        input    [7:0]     wdata;
        input    [12:0]    waddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                  =    1'b0;
            wave_ram_ideal_wdata    =    wdata;
            wave_ram_ideal_waddr    =    waddr;
            #CLK_36_HALF_PERIOD
            clk_36                  =    1'b1;
        end
    endtask
    
    //Write a task for reading a byte from the TX cancel RAM.
    //Although we can load this RAM up like we did in the waveform test bench, it will be easier if we just set the random seed and loop out a bunch of rand iterations.
    //Then to check we just loop through the same rand iterations after reasserting the seed
    //We drive clk_36 using this module using the delay time statement #CLK_36_HALF_PERIOD
    
    task    read_byte_tx_cancel_sram;
        //Inputs from simulation (global)
            
        // [7:0]    txcancel_mem_ideal_rdata
        
        //Outputs to simulation (global)
        
        // clk_36
        // [9:0]    txcancel_mem_ideal_raddr
        
        //Input arguments
        input    [7:0]    rdata_ideal;
        input    [9:0]    raddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b0;
            txcancel_mem_ideal_raddr      =    raddr;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b1;
            if(rdata_ideal != txcancel_mem_ideal_rdata)    begin
                $display("The simulation failed: TX Cancel memory check failed with actual:%b and ideal:%b at time %t",txcancel_mem_ideal_rdata,rdata_ideal,$realtime);
                $stop;
            end
        end
    endtask
    
    //Do the same stuff for the radio sram. We write only for RX because TX has no ability to write.
    
    task    write_byte_rx_radio_sram;
        //Inputs from simulation (global)
        
        //None!!!!            
        
        //Outputs to simulation (global)
        
        //output    [8:0]    radio_sram_address_rx_ideal;
        //output    [7:0]    radio_sram_wdata_ideal;
        //output             radio_sram_wren_ideal;
        //output             radio_sram_txrxaccess_ideal
        //output             clk_36;
        
        //Input arguments
        input    [7:0]    wdata;
        input    [8:0]    waddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            radio_sram_wdata_ideal         =    wdata;
            radio_sram_address_rx_ideal    =    waddr;
            radio_sram_txrxaccess_ideal    =    1'b1;
            radio_sram_wren_ideal          =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
        end
    endtask
    
    //Do same stuff for the sx1257 sram!
    
    task    write_byte_sx1257_sram;
        //Inputs from simulation (global)
        
        //None!!!!
        
        //Outputs to simulation (global)
        
        //output    [7:0]    sx1257_mem[6:0];
        //output             clk_36;
        
        //Input arguments
        input    [7:0]    wdata;
        input    [6:0]    waddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b0;
            sx1257_mem[waddr]             =    wdata;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b1;
        end
    endtask
    
    task    read_byte_sx1257_sram;
        //Inputs from simulation (global)

        // input    [7:0]    sx1257_mem[6:0];
        
        //Outputs to simulation (global)
        
        //Input arguments
        input    [7:0]    rdata_ideal;
        input    [6:0]    raddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b1;
            if(rdata_ideal != sx1257_mem[raddr])    begin
                $display("The simulation failed: SX1257 memory check failed at time %t",$realtime);
                $stop;
            end
        end
    endtask
    
    task    read_byte_dtc_sram;
        //Inputs from simulation (global)

        // input    [7:0]    dtc_mem[1:0];
        
        //Outputs to simulation (global)
        
        //Input arguments
        input    [7:0]    rdata_ideal;
        input    [1:0]    raddr;
        
        reg      [7:0]    rdata_actual;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                        =    1'b1;
            case(raddr)
                2'b00: begin    rdata_actual=dtc_mem[0];    end
                2'b01: begin    rdata_actual=dtc_mem[1];    end
                2'b10: begin    rdata_actual=dtc_mem[2];    end
                2'b11: begin    rdata_actual=dtc_mem[3];    end
            endcase    
            if(rdata_ideal != rdata_actual)    begin
                $display("The simulation failed: DTC memory check failed with actual:%b and ideal:%b at time %t",rdata_actual,rdata_ideal,$realtime);
                $stop;
            end
        end
    endtask
    
    task    read_byte_rx_radio_sram;
        //Inputs from simulation (global)

        // [7:0]    radio_sram_rdata_ideal
        
        //Outputs to simulation (global)
        
        //    clk_36
        //    radio_sram_txrxaccess_ideal
        //    radio_sram_address_rx_ideal
        
        //Input arguments
        input    [7:0]    rdata_ideal;
        input    [8:0]    raddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            radio_sram_address_rx_ideal    =    raddr;
            radio_sram_txrxaccess_ideal    =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
            if(rdata_ideal != radio_sram_rdata_ideal)    begin
                $display("The simulation failed: Radio RX memory check failed with actual:%b and ideal:%b at time %t",radio_sram_rdata_ideal,rdata_ideal,$realtime);
                $stop;
            end
        end
    endtask
    
    task    read_byte_tx_radio_sram;
        //Inputs from simulation (global)

        // [7:0]    radio_sram_rdata_ideal
        
        //Outputs to simulation (global)
        
        //    clk_36
        //    radio_sram_txrxaccess_ideal
        //    radio_sram_address_tx_ideal
        
        //Input arguments
        input    [7:0]    rdata_ideal;
        input    [8:0]    raddr;
        
        //Task Declarations
        //Local Variable Declarations
        //Task statement
        begin
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            radio_sram_address_tx_ideal    =    raddr;
            radio_sram_txrxaccess_ideal    =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                         =    1'b1;
            if(rdata_ideal != radio_sram_rdata_ideal)    begin
                $display("The simulation failed: Radio TX memory check failed at time %t",$realtime);
                $stop;
            end
        end
    endtask
    
/////////////////////////////////////////////////////////////////////////////////////////
// Define High Level Tasks
/////////////////////////////////////////////////////////////////////////////////////////

    task    fill_sx1257_sram_from_ideal;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [7:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;

        //Task statement
        begin
            //In Verilog 'seed' is like 'state'
            //In other words, the value of this actually gets changed from run to run, but it needs to start at a defined value
            //We don't know if internal routines can change the seed input value (I'm guessing not)
            //So we first transfer this value into an internal variable which should be alterable by the runtime environment,
            //giving the proper seeded random behavior.
            seed_intl    =    seed;
            for(loop_addr = 8'b0; loop_addr < 8'b1000_0000; loop_addr = loop_addr + 8'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                write_byte_sx1257_sram(data_intl,loop_addr[6:0]);        //Here's hoping the casting all works out for the data byte
            end
        end
    endtask
    
    task    read_sx1257_sram_to_ideal;
    
        //Input arguments
        input      [7:0]      seed;
    
        //Local Variable Declarations
        reg        [7:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 8'b0; loop_addr < 8'b1000_0000; loop_addr = loop_addr + 8'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                read_byte_sx1257_sram(data_intl,loop_addr[6:0]);        //Here's hoping the casting all works out for the data byte
            end
        end
    endtask
    
    task    read_sx1257_gain_sram_to_ideal;
        //Input arguments
        input      [7:0]      seed;
    
        //Local Variable Declarations
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            data_intl    =    {$random(seed_intl)} % 256;
            read_byte_sx1257_sram(data_intl,7'b0001100);        //Here's hoping the casting all works out for the data byte
        end
    endtask
    
    task    read_dtc_sram_to_ideal;
    
        //Input arguments
        input      [7:0]      seed;
    
        //Local Variable Declarations
        reg        [2:0]    loop_addr;
        integer             seed_intl;
        reg        [4:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 3'b0; loop_addr < 3'b100; loop_addr = loop_addr + 3'd1)    begin
                data_intl    =    {$random(seed_intl)} % 32;
                //$display("Got to %d at time %t",loop_addr[1:0],$realtime);
                read_byte_dtc_sram({3'b000,data_intl},loop_addr[1:0]);        //Here's hoping the casting all works out for the data byte
            end
        end
    endtask
    
    task    fill_waveform_sram_from_ideal;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [13:0]    loop_addr;
        integer              seed_intl;
        reg        [7:0]     data_intl;

        //Task statement
        begin
            //In Verilog 'seed' is like 'state'
            //In other words, the value of this actually gets changed from run to run, but it needs to start at a defined value
            //We don't know if internal routines can change the seed input value (I'm guessing not)
            //So we first transfer this value into an internal variable which should be alterable by the runtime environment,
            //giving the proper seeded random behavior.
            seed_intl    =    seed;
            wave_ram_ideal_wren       =    1'b1;
            for(loop_addr = 14'b0; loop_addr < 14'b10_0000_0000_0000; loop_addr = loop_addr + 14'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                //$display("Data_intl is %d at %t",data_intl,$realtime);
                write_byte_waveform_sram(data_intl,loop_addr[12:0]);        //Here's hoping the casting all works out for the data byte
            end
            #CLK_36_HALF_PERIOD                                             //Make sure the last data gets in before releasing wren
            clk_36                    =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                    =    1'b1;
            wave_ram_ideal_wren       =    1'b0;
        end
    endtask
    
    task    read_tx_cancel_sram_to_ideal;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [10:0]    loop_addr;
        integer              seed_intl;
        reg        [7:0]     data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 11'b0; loop_addr < 11'b100_0000_0000; loop_addr = loop_addr + 11'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                read_byte_tx_cancel_sram(data_intl,loop_addr[9:0]);        //Here's hoping the casting all works out for the data byte
            end
        end
    endtask
    
    task    fill_radio_rx_sram_from_ideal;
    
        //Input arguments
        input      [7:0]      seed;
    
        //Local Variable Declarations
        reg        [9:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;

        //Task statement
        begin
            seed_intl    =    seed;
            radio_sram_wren_ideal    =    1'b1;
            for(loop_addr = 10'b0; loop_addr < 10'b10_0000_0000; loop_addr = loop_addr + 10'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                write_byte_rx_radio_sram(data_intl,loop_addr[8:0]);        //Here's hoping the casting all works out for the data byte
            end
            #CLK_36_HALF_PERIOD                                            //Make sure the last data gets in before releasing wren
            clk_36                   =    1'b0;
            #CLK_36_HALF_PERIOD
            clk_36                   =    1'b1;
            radio_sram_wren_ideal    =    1'b0;
        end
    endtask
    
    task    read_radio_rx_sram_to_ideal;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [9:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 10'b0; loop_addr < 10'b10_0000_0000; loop_addr = loop_addr + 10'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                read_byte_rx_radio_sram(data_intl,loop_addr[8:0]);        //Here's hoping the casting all works out for the data byte
            end
        end
    endtask
        
    task    read_radio_tx_sram_to_ideal;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [9:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 10'b0; loop_addr < 10'b10_0000_0000; loop_addr = loop_addr + 10'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                read_byte_tx_radio_sram(data_intl,loop_addr[8:0]);        //Here's hoping the casting all works out for the data byte
            end
        end
    endtask
        
    task    read_waveform_sram_to_nrf51822;
    
        //Input arguments
        input      [7:0]       seed;
        
        //Local Variable Declarations
        reg        [13:0]    loop_addr;
        integer              seed_intl;
        reg        [7:0]     data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 14'b0; loop_addr < 14'b10_0000_0000_0000; loop_addr = loop_addr + 14'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{1'b1,loop_addr[12:0]},8'b0,data_intl);        //Here's hoping the casting all works out for the data byte
                        //input                      write_readb;
                        //input            [13:0]    address;
                        //input            [7:0]     data_in;
                        //input            [7:0]     data_return_ideal;
            end
        end
    endtask
        
    task    fill_tx_cancel_sram_from_nrf51822;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [10:0]    loop_addr;
        integer              seed_intl;
        reg        [7:0]     data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 11'b0; loop_addr < 11'b100_0000_0000; loop_addr = loop_addr + 11'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0010,loop_addr[9:0]},data_intl,8'b0000_0000);        //Here's hoping the casting all works out for the data byte
                        //input                      write_readb;
                        //input            [13:0]    address;
                        //input            [7:0]     data_in;
                        //input            [7:0]     data_return_ideal;
            end
        end
    endtask
    
    task    read_tx_cancel_sram_from_nrf51822;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [10:0]    loop_addr;
        integer            seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 11'b0; loop_addr < 11'b100_0000_0000; loop_addr = loop_addr + 11'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0010,loop_addr[9:0]},8'b0000_0000,data_intl);        //Here's hoping the casting all works out for the data byte
                        //input                      write_readb;
                        //input            [13:0]    address;
                        //input            [7:0]     data_in;
                        //input            [7:0]     data_return_ideal;
            end
        end
    endtask
    
    task    fill_radio_rx_sram_from_nrf51822;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [9:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 10'b0; loop_addr < 10'b10_0000_0000; loop_addr = loop_addr + 10'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0100,1'b1,loop_addr[8:0]},data_intl,8'b0000_0000);         //Radio RAM RX address has MSB=1
                        //input                     write_readb;
                        //input            [13:0]   address;
                        //input            [7:0]    data_in;
                        //input            [7:0]    data_return_ideal;
            end
        end
    endtask
        
    task    fill_radio_tx_sram_from_nrf51822;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [9:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 10'b0; loop_addr < 10'b10_0000_0000; loop_addr = loop_addr + 10'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0101,1'b0,loop_addr[8:0]},data_intl,8'b0000_0000); //Radio RAM TX address has MSB=0
                        //input                     write_readb;
                        //input            [13:0]   address;
                        //input            [7:0]    data_in;
                        //input            [7:0]    data_return_ideal;
            end
        end
    endtask
    
    task    read_radio_rx_sram_to_nrf51822;
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [9:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 10'b0; loop_addr < 10'b10_0000_0000; loop_addr = loop_addr + 10'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0100,1'b1,loop_addr[8:0]},8'b0,data_intl);        //Radio RAM RX address has MSB=1
                        //input                     write_readb;
                        //input            [13:0]   address;
                        //input            [7:0]    data_in;
                        //input            [7:0]    data_return_ideal;
            end
        end
    endtask
        
    task    fill_sx1257_sram_from_nrf51822;
    
        //This one gets a little tricky because we have to access the user memory a few times for this to work.
    
        //Input arguments
        input      [7:0]      seed;
    
        //Local Variable Declarations
        reg        [7:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 8'b0; loop_addr < 8'b1000_0000; loop_addr = loop_addr + 8'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?00?_????);             //Check to see that pending and done registers are properly set
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b100},{1'b1,loop_addr[6:0]},8'b0000_0000);    //Write SX1257 WNR bit + ADDR to SPI cntrlr passthrough address byte
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b101},data_intl,8'b0000_0000);                //Write SX1257 DATA byte to SPI cntrlr passthrough data byte
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b110},8'b0000_0001,8'b0000_0000);             //Write cntrlr spi ready, but how do we know when it's done?
                //wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?10?_????);           
                //Can't check to see if pending is actually set here b/c it will be done in 16 ~7MHz clock cycles whereas it will take 32 5 MHz clock cycles to perform the interrogation.
                //@(negedge dut.cntrlr_spi_pending);    //We should be able to catch this, however. - Nope
                //@(posedge mcu_irq_pin); - Not even this
                wait(dut.cntrlr_spi_done == 1'b1);    //Fine, we will do this to ensure proper gating of flow.
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?01?_????);                //Check to see that pending and done registers are properly set
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b110},8'b0000_0000,8'b0000_0000);                //Write cntrlr spi deassert
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?00?_????);                //Check to see that pending and done registers are properly set
            end
        end
    endtask

    task    read_sx1257_sram_to_nrf51822;
    
        //This one gets a little tricky because we have to access the user memory a few times for this to work.
    
        //Input arguments
        input      [7:0]    seed;
    
        //Local Variable Declarations
        reg        [7:0]    loop_addr;
        integer             seed_intl;
        reg        [7:0]    data_intl;
        
        //Task statement
        begin
            seed_intl    =    seed;
            for(loop_addr = 8'b0; loop_addr < 8'b1000_0000; loop_addr = loop_addr + 8'd1)    begin
                data_intl    =    {$random(seed_intl)} % 256;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?00?_????);             //Check to see that pending and done registers are properly set
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b100},{1'b0,loop_addr[6:0]},8'b0000_0000);    //Write SX1257 RNW bit + ADDR to SPI cntrlr passthrough address byte
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b101},8'b0000_0000,8'b0000_0000);             //Write SX1257 DATA byte to SPI cntrlr passthrough data byte
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b110},8'b0000_0001,8'b0000_0000);             //Write cntrlr spi ready, but how do we know when it's done?
                //wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?10?_????);           
                //Can't check to see if pending is actually set here b/c it will be done in 16 ~7MHz clock cycles whereas it will take 32 5 MHz clock cycles to perform the interrogation.
                //@(negedge dut.cntrlr_spi_pending);    //We should be able to catch this, however. - Nope
                //@(posedge mcu_irq_pin); - Not even this
                wait(dut.cntrlr_spi_done == 1'b1);    //Fine, we will do this to ensure proper gating of flow.
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?01?_????);             //Check to see that pending and done registers are properly set
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b110},8'b0000_0000,8'b0000_0000);             //Write cntrlr spi deassert
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b?00?_????);             //Check to see that pending and done registers are properly set
                //Then we need to read out the result and compare it with the data that should be in there
                //$display("Checking pulls from sx1257 ram, data: %b at time %t",data_intl,$realtime);
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b111},8'b0000_0000,data_intl);                //Write command to pull data from the sx1257
            end
        end
    endtask
    
    task    run_txcancel_iteration;
    
        //Here, we write values to both the sx1257 and the DTCs through the TX cancellation interface
        
        //Input arguments
        input    [7:0]      seed_sx1257;
        input    [7:0]      seed_dtc;        //Separate seeds are needed because we need to plug in the same seed for the read dtc high level function
        
        //Local variable declarations
        integer             seed_sx1257_intl;
        integer             seed_dtc_intl;
        reg        [7:0]    data_intl;
        reg        [4:0]    data_intl0;
        reg        [4:0]    data_intl1;
        reg        [4:0]    data_intl2;
        reg        [4:0]    data_intl3;
        
        //Task statement
        
        begin
            seed_sx1257_intl    =    seed_sx1257;
            seed_dtc_intl       =    seed_dtc;
            data_intl           =    {$random(seed_sx1257_intl)} % 256;
            write_spi_from_txcancel_module(data_intl,15'b0,1'b1);
            data_intl0          =    {$random(seed_dtc_intl)} % 32;
            data_intl1          =    {$random(seed_dtc_intl)} % 32;
            data_intl2          =    {$random(seed_dtc_intl)} % 32;
            data_intl3          =    {$random(seed_dtc_intl)} % 32;
            write_spi_from_txcancel_module({3'b000,data_intl0},{data_intl1,data_intl2,data_intl3},1'b0);
        end
        
    endtask
    
    task    test_user_registers_pos_polarity;
        
        //Since there aren't that many user registers, we aren't going to get clever and test them with loops, functions, etc.
        //In fact, we've already tested half of the user registers by testing the spi cntrlr interface
        //The plan for testing the user registers (there are four bytes of them) is this:
        
        //0. Pick a pattern. it is [01010101;10101010;01010101;10101010].
        //1. Write ~pattern via reg setting on the reg side.
        //2. Write pattern via spi on the mcu side.
        //3. Check that one shots are properly asserted (this can be done via fork/join)
        //4. Check that written registers were correct on the reg side.
        //5. Read all of the bytes, check for the proper result.
    
        //reg map (for reference)
        //000:radio_exit_code[2:0](ro),radio_mode[2:0](wr),irq_ack(os)/clk_36_valid(ro),go_radio(os)/clk_36_running(ro)
        //001:clk_36_start(os)/radio_num_tags[3],radio_num_tags[2:0](ro),wave_storage_running(ro),wave_storage_done(ro),radio_running(ro),radio_done(ro)
        //010:1'b0,cntrlr_spi_pending(ro-1'b0 here),cntrlr_spi_done(ro-1'b0 here),tx_error[2:0](ro),use_i(wr),sw_reset(os)
        //011:wvfm_offset[7:0] (wr)
        
        //declare internal registers
        
        reg                 error;
        reg        [2:0]    flag_1;
        reg        [2:0]    flag_2;
        reg        [2:0]    flag_3;
        reg                 done;
        
        begin
            //Step 1:
            radio_exit_code         =    3'b101;
            clk_36_valid            =    1'b1;
            clk_36_running          =    1'b0;
            radio_num_tags          =    4'b0101;
            wave_storage_running    =    1'b0;
            wave_storage_done       =    1'b1;
            radio_running           =    1'b0;
            radio_done              =    1'b1;
            tx_error                =    3'b010;
        
            //Step 2/3: Here, the tricky part is to check that the one-shot bits we wanted to assert(go_radio, clk_36_start, sw_reset) did and that irq_ack did not.
            //Also we want to check that the one-shot bits were asserted before the spi transaction ends.
            //This can be done by flag-setting. The SPI branch of the fork needs to set its flag last, or else we have an error.
            //Same thing with checking for bad assert - put a while loop on the case that breaks once the main task is done.
            //Ideally we check for the one-shot assert after each byte write, but we don't want to make the code a mess so we check them all in bulk
            flag_1    =    3'b000;
            flag_2    =    3'b000;
            flag_3    =    3'b000;
            done      =    1'b0;
            fork    begin
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b000},8'b0101_0101,8'b0000_0000);
                flag_1    =    3'b010;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b001},8'b1010_1010,8'b0000_0000);
                flag_2    =    3'b010;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b010},8'b0101_0101,8'b0000_0000);
                flag_3    =    3'b010;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b011},8'b1010_1010,8'b0000_0000);
                done      =    1'b1;
            end        begin
                wait(go_radio);
                flag_1    =    3'b101;
            end        begin
                wait(clk_36_start);
                flag_2    =    3'b111;
            end        begin
                wait(sw_reset);
                flag_3    =    3'b110;
            end        begin
                while (!done)    begin:    look_for_bad_assert
                    #CLK_36_HALF_PERIOD
                    if(irq_ack)    begin
                        $display("The simulation failed: one-shot that was supposed to assert did not%t",$realtime);
                        $stop;
                    end
                end
            end
            join
            if(flag_1 != 3'b010 || flag_2 != 3'b010 || flag_3 != 3'b010)    begin
                $display("The simulation failed: one-shots did not all assert prior to end of SPI transactions%t",$realtime);
                $stop;
            end
        
            //Step 4:
            error    =    radio_mode != 3'b101 || wvfm_offset != 8'b1010_1010 || use_i != 1'b0;
            if(error)    begin
                $display("The simulation failed: User regs check on write reg check failed at time %t",$realtime);
                $stop;
            end
            
        //reg map (for reference)
        //000:radio_exit_code[2:0](ro),radio_mode[2:0](wr),irq_ack(os)/clk_36_valid(ro),go_radio(os)/clk_36_running(ro)
        //001:clk_36_start(os)/radio_num_tags[3],radio_num_tags[2:0](ro),wave_storage_running(ro),wave_storage_done(ro),radio_running(ro),radio_done(ro)
        //010:1'b0,cntrlr_spi_pending(ro-1'b0 here),cntrlr_spi_done(ro-1'b0 here),tx_error[2:0](ro),use_i(wr),sw_reset(os)
        //011:wvfm_offset[7:0] (wr)
            
            //Step 5:
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b000},8'b0000_0000,8'b1011_0110);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b001},8'b0000_0000,8'b0101_0101);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b0000_1000);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b011},8'b0000_0000,8'b1010_1010);
        end
    endtask
    
    task    test_user_registers_neg_polarity;
        
        //Since there aren't that many user registers, we aren't going to get clever and test them with loops, functions, etc.
        //In fact, we've already tested half of the user registers by testing the spi cntrlr interface
        //The plan for testing the user registers (there are four bytes of them) is this:
        
        //0. Pick a pattern. it is ~[01010101;10101010;01010101;10101010].
        //1. Write ~pattern via reg setting on the reg side.
        //2. Write pattern via spi on the mcu side.
        //3. Check that one shots are properly asserted (this can be done via fork/join)
        //4. Check that written registers were correct on the reg side.
        //5. Read all of the bytes, check for the proper result.
    
        //reg map (for reference)
        //000:radio_exit_code[2:0](ro),radio_mode[2:0](wr),irq_ack(os)/clk_36_valid(ro),go_radio(os)/clk_36_running(ro)
        //001:clk_36_start(os)/radio_num_tags[3],radio_num_tags[2:0](ro),wave_storage_running(ro),wave_storage_done(ro),radio_running(ro),radio_done(ro)
        //010:1'b0,cntrlr_spi_pending(ro-1'b0 here),cntrlr_spi_done(ro-1'b0 here),tx_error[2:0](ro),use_i(wr),sw_reset(os)
        //011:wvfm_offset[7:0] (wr)
        
        //declare internal registers
        
        reg                 error;
        reg        [2:0]    flag_1;
        reg        [2:0]    flag_2;
        reg        [2:0]    flag_3;
        reg                 done;
        
        begin
            //Step 1:
            radio_exit_code         =    3'b010;
            clk_36_valid            =    1'b0;
            clk_36_running          =    1'b1;
            radio_num_tags          =    4'b1010;
            wave_storage_running    =    1'b1;
            wave_storage_done       =    1'b0;
            radio_running           =    1'b1;
            radio_done              =    1'b0;
            tx_error                =    3'b101;
        
            //Step 2/3: Here, the tricky part is to check that the one-shot bits we wanted to assert irq_ack did and that (go_radio, clk_36_start, sw_reset) did not.
            //Also we want to check that the one-shot bits were asserted before the spi transaction ends.
            //This can be done by flag-setting. The SPI branch of the fork needs to set its flag last, or else we have an error.
            //Same thing with checking for bad assert - put a while loop on the case that breaks once the main task is done.
            //Ideally we check for the one-shot assert after each byte write, but we don't want to make the code a mess so we check them all in bulk
            flag_1    =    3'b000;
            flag_2    =    3'b000;
            flag_3    =    3'b000;
            done      =    1'b0;
            fork    begin
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b000},8'b1010_1010,8'b0000_0000);
                flag_1    =    3'b010;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b001},8'b0101_0101,8'b0000_0000);
                flag_2    =    3'b010;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b010},8'b1010_1010,8'b0000_0000);
                flag_3    =    3'b010;
                wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0001,7'b0,3'b011},8'b0101_0101,8'b0000_0000);
                done      =    1'b1;
            end        begin
                wait(irq_ack);
                flag_1    =    3'b101;
            end        begin
                while (!done)    begin:    look_for_bad_assert
                    #CLK_36_HALF_PERIOD
                    if(go_radio || clk_36_start || sw_reset)    begin
                        $display("The simulation failed: one-shot that was supposed to assert did not%t",$realtime);
                        $stop;
                    end
                end
            end
            join
            if(flag_1 != 3'b010 || flag_2 != 3'b010 || flag_3 != 3'b010)    begin
                $display("The simulation failed: one-shots did not all assert prior to end of SPI transactions%t",$realtime);
                $stop;
            end
        
            //Step 4:
            error    =    radio_mode != 3'b010 || wvfm_offset != 8'b0101_0101 || use_i != 1'b1;
            if(error)    begin
                $display("The simulation failed: User regs check on write reg check failed at time %t",$realtime);
                $stop;
            end
            
        //reg map (for reference)
        //000:radio_exit_code[2:0](ro),radio_mode[2:0](wr),irq_ack(os)/clk_36_valid(ro),go_radio(os)/clk_36_running(ro)
        //001:clk_36_start(os)/radio_num_tags[3],radio_num_tags[2:0](ro),wave_storage_running(ro),wave_storage_done(ro),radio_running(ro),radio_done(ro)
        //010:1'b0,cntrlr_spi_pending(ro-1'b0 here),cntrlr_spi_done(ro-1'b0 here),tx_error[2:0](ro),use_i(wr),sw_reset(os)
        //011:wvfm_offset[7:0] (wr)
            
            //Step 5:
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b000},8'b0000_0000,8'b0100_1001);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b001},8'b0000_0000,8'b1010_1010);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b010},8'b0000_0000,8'b0001_0110);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b0,{4'b0001,7'b0,3'b011},8'b0000_0000,8'b0101_0101);
        end
    endtask
    
    task    switch_radio_running;            //Call this task when we want to switch SPI Controller from SPI prphrl Control (0) to TX Cancel Control (1)
    
        input    running;
        
        begin
            radio_running    =    running;
        end
    endtask
    
/////////////////////////////////////////////////////////////////////////////////////////
// Run the entire simulation by executing a series of tasks
/////////////////////////////////////////////////////////////////////////////////////////

    //fill_sx1257_sram_from_ideal(seed[7:0])    - check
    //read_sx1257_sram_to_ideal(seed[7:0])    - check
    //read_dtc_sram_to_ideal(seed[7:0])
    //read_sx1257_gain_sram_to_ideal(seed[7:0])
    //fill_waveform_sram_from_ideal(seed[7:0])    - check
    //read_tx_cancel_sram_to_ideal(seed[7:0])    - check
    //fill_radio_rx_sram_from_ideal(seed[7:0])    - check
    //read_radio_rx_sram_to_ideal(seed[7:0])    - check
    //read_radio_tx_sram_to_ideal(seed[7:0])    - check
    //read_waveform_sram_to_nrf51822(seed[7:0])    - check
    //fill_tx_cancel_sram_from_nrf51822(seed[7:0])    - check
    //fill_radio_rx_sram_from_nrf51822(seed[7:0])    - check
    //fill_radio_tx_sram_from_nrf51822(seed[7:0])    - check
    //read_radio_rx_sram_to_nrf51822(seed[7:0])    - check
    //fill_sx1257_sram_from_nrf51822(seed[7:0])    - check
    //read_sx1257_sram_to_nrf51822(seed[7:0])    - check
    //run_txcancel_iteration(seed_sx1257[7:0],seed_dtc[7:0])
    //test_user_registers_pos_polarity    - check
    //test_user_registers_neg_polarity    - check
    //switch_radio_running(running)

    initial    begin: main_sim_run
        //Set radio running to zero
        switch_radio_running(1'b0);
        //Check waveform ram transfers
        fill_waveform_sram_from_ideal(142);
        read_waveform_sram_to_nrf51822(142);
        $display("Successful waveform data transfer at time %t",$realtime);
        //Check tx cancel transfers
        fill_tx_cancel_sram_from_nrf51822(26);
        read_tx_cancel_sram_from_nrf51822(26);
        $display("Successful TX cancel data transfer A at time %t",$realtime);
        read_tx_cancel_sram_to_ideal(26);
        $display("Successful TX cancel data transfer B at time %t",$realtime);
        //Check user transfers
        test_user_registers_pos_polarity;
        test_user_registers_neg_polarity;
        $display("Successful user registers data transfer at time %t",$realtime);
        //Make sure that radio running to zero
        switch_radio_running(1'b0);
        //Test radio sram filling from MCU
        fill_radio_rx_sram_from_nrf51822(243);
        fill_radio_tx_sram_from_nrf51822(73);
        read_radio_rx_sram_to_ideal(243);
        read_radio_tx_sram_to_ideal(73);
        $display("Successful radio SRAM filling from MCU at time %t",$realtime);
        //Test radio sram filling from the digital side
        fill_radio_rx_sram_from_ideal(52);
        read_radio_rx_sram_to_nrf51822(52);
        $display("Successful radio SRAM reading to MCU at time %t",$realtime);
        //Switch radio running to 1
        switch_radio_running(1'b1);
        //Permit TX Cancel block to operate the spi cntrlr(twice)
        run_txcancel_iteration(225,213);
        read_sx1257_gain_sram_to_ideal(225);
        read_dtc_sram_to_ideal(213);
        run_txcancel_iteration(128,47);
        read_sx1257_gain_sram_to_ideal(128);
        read_dtc_sram_to_ideal(47);
        $display("Successful first TX Cancel-to-SPI cntrlr operation completed at time %t",$realtime);
        //Now operate SX1257 from MCU
        switch_radio_running(1'b0);
        //Test writing from MCU to SX1257 and verifying and vice versa
        fill_sx1257_sram_from_nrf51822(179);
        read_sx1257_sram_to_ideal(179);
        $display("Successful MCU-to-SPI cntrlr operation completed at time %t",$realtime);
        fill_sx1257_sram_from_ideal(136);
        read_sx1257_sram_to_nrf51822(136);
        $display("Successful SPI cntrlr-to-MCU operation completed at time %t",$realtime);
        //Go back and see if txcancel still works
        switch_radio_running(1'b1);
        run_txcancel_iteration(33,107);
        read_sx1257_gain_sram_to_ideal(33);
        read_dtc_sram_to_ideal(107);
        $display("Successful second TX cancel-to-SPI cntrlr operation completed at time %t",$realtime);
        $display("Simulation completed successfully at time %t",$realtime);
        $stop;
    end
endmodule