//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
// Module : Test Clock and Reset Management                                     //
//                                                                              //
// Filename: test_clk_and reset_mgmt.v                                          //
// Creation Date: 8/05/2016                                                     //
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
//                                                                              //
//    This block contains the testbench for the clock and reset mgmt module.    //
//    The clock and reset management modules are surrounded by a wrapper to     //
//    ensure that their mutual verification is valid at the top level of the    //
//    design.                                                                   //
//                                                                              //
//    The things to be tested in the clock management module are:               //
//    1. Proper division of clocks.                                             //
//    2. Proper generation of clk_55.                                           //
//    3. Detect when SX1257 36MHz clock stops                                   //
//    4. Show proper detection of 36MHz clock running again                     //
//    5. Show proper restart of internal 36MHz clock when MCU commands it.      //
//    6. We should stop clock in all 7 states of the state machine.             //
//    7. Check that IRQ gets generated when clock valid changes state.          //
//    8. Apply external reset during all 7 states of the state machine.         //
//    9. Apply sw reset during all 7 states of the state machine.               //
//                                                                              //
//    083021 - Replaced tabs with 4-spaces. Added copyright to header.          //
//    This file is out of date and was not re-run after cleanup for release, so //
//    please temper expectations for use accordingly.                           //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

`timescale    1ns/100ps
`define        NULL    0

module test_clk_and_reset_mgmt();

  //Declare variables associated with the DUT I/O.

  reg     clk_36_in, clk_36_start, rst_n_ext, rst_4p5_sw;
  wire    clk_36, clk_4p5, clk_27p5;
  wire    rst_n_27p5, rst_n_4p5, rst_n_36_in;
  wire    clk_36_valid_reg, clk_36_running_reg, clk_36_irq;
  
  //Declare loop control integers
  //If I understand how Verilog simulation is working, we need a different integer for each initial statement in which for loops are executed
  
  integer    loop_i;
  integer    loop_j;
  
  //Declare time variables used for checking the three output clocks
  
  realtime    edge_prev_4p5, edge_dlta_4p5;
  realtime    edge_prev_36, edge_dlta_36;
  
  //Declare parameters
  
  parameter CLK_36_HALF_PERIOD        =    (0.5e9)/(36e6);
  parameter CLK_4P5_HALF_PERIOD       =    8*CLK_36_HALF_PERIOD;
  parameter CLK_55_HALF_PERIOD        =    (0.5e9)/(86e6);        //Added 120416 because we think this might be an issue with getting clk running to show up, but it's not.
  parameter CLK_27P5_HALF_PERIOD      =    2*CLK_55_HALF_PERIOD;
  parameter CLK_ERROR_WINDOW          =    0.5;                   //When checking clocks, ensure that edges occur 0.5 ns away from where we expect.
  parameter    RST_DEASSERT_DLY       =    100;
  parameter    CLK_36_INTERRUN_DLY_0  =    100.9*(1e9)/(36e6);    //Wait about 100 cycles to keep the clock off. Don't wait integer cycle to see if we can mess something up.
  parameter    CLK_36_RUN_1_ITERS     =    2*(8+100);             //8 cycles to move to clock valid states, 100 clocks (an arbitrary number, but large enough to cause transitions through all states)
                                                                  //Choosing the number of run iterations to be an even number results in the clock stopping at the same level it started (0).
  parameter    CLK_36_INTERRUN_DLY_1  =    100.6*(1e9)/(36e6);    //Wait about 100 cycles to keep the clock off. Don't wait integer cycle to see if we can mess something up.
  parameter    CLK_36_RUN_2_ITERS     =    2*(8+100)+1;           //8 cycles to move to clock valid states, 100 clocks (an arbitrary number, but large enough to cause transitions through all states)
                                                                  //Choosing the number of run iterations to be an odd number results in the clock stopping at the opposite level at which it started (1).
                                                                  //This helps to ensure that we can restart the internal clock no matter which level the external clock stops at.
  parameter    CLK_36_INTERRUN_DLY_2  =    100.2*(1e9)/(36e6);    //Wait about 100 cycles to keep the clock off. Don't wait integer cycle to see if we can mess something up.
  parameter    TIMEOUT_DLY            =    RST_DEASSERT_DLY+CLK_36_INTERRUN_DLY_0+CLK_36_INTERRUN_DLY_1+CLK_36_INTERRUN_DLY_2+324*(1e9)/(36e6)+300*(1e9)/(36e6);
  //Set TIMEOUT_DLY to be slightly greater than the known delays plus some margin (the last term is the somewhat arbitrary margin
  
  //Declare dut module
  
  clk_and_reset_mgmt dut(
    //Clk Mgmt Inputs
      .clk_36_in(clk_36_in),
      .clk_36_start(clk_36_start),                //Needs to come from spi.v
    //Reset Mgmt Inputs
      .rst_n_ext(rst_n_ext),                      //Active low reset from external pin
      .rst_4p5_sw(rst_4p5_sw),
    //Clk Mgmt Outputs
      .clk_36(clk_36),
      .clk_4p5(clk_4p5),
      .clk_36_valid_reg(clk_36_valid_reg),        //Needs to go to spi.v. This signal means that we have a valid clock from the SX1257.
      .clk_36_running_reg(clk_36_running_reg),    //Needs to go to spi.v. This signal means that the internal 36MHz clock is running. It is delayed somewhat from the actual state machine.
      .clk_36_irq(clk_36_irq),                    //Needs to go to rfidr_fsm.v. This signal informs the MCU that the clock has stopped. 
      .clk_27p5(clk_27p5),
     //Reset Mgmt Outputs
      .rst_n_27p5(rst_n_27p5),
      .rst_n_4p5(rst_n_4p5),
      .rst_n_36_in(rst_n_36_in)
  );

  //Initial block statement controlling the timeout simulation failure catch
  
    initial    $timeformat(-9,1,"ns",10);
  
    initial begin : catch_timeout
        #TIMEOUT_DLY
        $display("The simulation failed: we reached the timeout at time %t",$realtime);
        $stop;
    end
  
      //Initial block statement controlling clk_36_in
  
    initial begin : control_input_clk
        clk_36_in        =    1'b0;
        loop_i=0;
        wait(rst_n_ext);
    
        #CLK_36_INTERRUN_DLY_0
    
        for(loop_i=0;loop_i<=CLK_36_RUN_1_ITERS;loop_i=loop_i+1) begin
            #CLK_36_HALF_PERIOD
            clk_36_in    = ~clk_36_in;
        end
  
        #CLK_36_INTERRUN_DLY_1
    
        for(loop_i=0;loop_i<=CLK_36_RUN_2_ITERS;loop_i=loop_i+1) begin
            #CLK_36_HALF_PERIOD
            clk_36_in    = ~clk_36_in;
        end    

        #CLK_36_INTERRUN_DLY_2

        //After the third start, run clock until the end of the simulation
        
        forever begin
            #CLK_36_HALF_PERIOD
            clk_36_in    = ~clk_36_in;
        end    
    end
  
  //Initial block statement checking the periodicity of clk_4p5
  //This should run for the entire simulation so we put it in a forever loop
  //We put the forever loop inside the initial loop to ensure that the forever loop starts after the first clk_4p5 posedge (we might have to do this anyway)
  
  //A few options that we thought of here that don't seem to work well:
  //1. Wait for a posedge of 4p5 then check that clk_4p5 stays high for 4 clk_36_in cycles then is low for 4 clk_36_in cycles.
  //The problem with this is that if clk_36_in just stops and clk_4p5 transitions early, such a situation will not be caught.

  //2. Wait for a posedge of 4p5 then check that a transition occurs within a defined time interval
  //So use a # statement to delay nearly half of a 4p5 period, check to see that the level is still the same,
  //then use another # statement to delay an epsilon interval, then check to see that the clock changed in this epsilon interval
  
  //3. Use posedge clk_4p5, negedge clk_4p5, then use some time recording function t.b.d. to record the time between edges.
  //If the time is not correct +/- some uncertainty, flag an error.
  //We can do posedge clk_4p5 or posedge irq and then do something different based on which one occurred.
  //But there still may be the issue that the IRQ is delayed until posedge clk_4p5 happens.
  //Let's go through the scenarios.
  //3a) clk_36_in stops. IRQ is delayed. clk_4p5 shows up early. An error is flagged, as it should be.
  //3b) clk_36_in stops. IRQ is delayed. clk_4p5 shows up late but before IRQ. In this case, we can:
  //    -also look to see if clk_36_in is still running.
  //    -look at clk_mgmt.v state. It goes to an invalid state very quickly. This is probably as fast as we can detect a stopped clk_36 anyway
  //    -also consider this a bug, because if the clk_36 does stop then 4p5 should stop immediately, and only change value later if a reset takes place.
  //
  //So this sounds good.
  //So when we see the IRQ, we can consider it a reset of the loop - i.e. we allow the loop to proceed.
  //So we watch the clk_4p5 toggle back and forth until there is a IRQ, then when we see a posedge clk_4p5 we start the loop going all over again.
  //What about when clk_4p5 is brought down via reset or sw reset?
  //The clock gate signal does indeed go low during one of these resets - the question is what does the clock gate do?
  //Well, take a look at Page 2-7 of the MAX 10 FPGA user guide - the clock_out signal will stay low and still meet timing.
  
    //Check timing on 4p5 MHz clock.
  
    initial begin : check_clk_4p5_timing
        edge_dlta_4p5    =    0;
        forever begin : outer_4p5
            //First check that clk_4p5 is low. If not, flag an error.
            if(clk_4p5 != 1'b0) begin
                $display("The simulation failed: clk_4p5 does not start out at 0");
                $stop;
            end
            //Store the current time as the previous time.
            edge_prev_4p5=$realtime;
    
            //For the first posedge back, we don't care if the time between the previous edge was too long. But too short is not OK.
            @(posedge clk_4p5 or posedge clk_36_irq);
            if(clk_36_irq) begin
                //Do nothing
            end else begin
                edge_dlta_4p5=$realtime-edge_prev_4p5;
                if(edge_dlta_4p5 < CLK_4P5_HALF_PERIOD - CLK_ERROR_WINDOW) begin
                    $display("The simulation failed: clk_4p5 had an out of bounds positive edge at time %t",$realtime);
                    $stop;
                end else begin
                    edge_prev_4p5=$realtime;
                end
            end    
    
            forever begin : inner_4p5
                @(negedge clk_4p5 or posedge clk_36_irq);
                if(clk_36_irq) begin
                    disable inner_4p5;
                end else begin
                    edge_dlta_4p5=$realtime-edge_prev_4p5;
                    if(edge_dlta_4p5 < CLK_4P5_HALF_PERIOD - CLK_ERROR_WINDOW) begin
                        $display("The simulation failed: clk_4p5 had an out of bounds negative edge at time %t",$realtime);
                        $stop;
                    end else begin
                        edge_prev_4p5=$realtime;
                    end
                end
                @(posedge clk_4p5 or posedge clk_36_irq);
                if(clk_36_irq) begin
                    disable inner_4p5;
                end else begin
                    edge_dlta_4p5=$realtime-edge_prev_4p5;
                    if(edge_dlta_4p5 < CLK_4P5_HALF_PERIOD - CLK_ERROR_WINDOW) begin
                        $display("The simulation failed: clk_4p5 had an out of bounds positive edge at time %t",$realtime);
                        $stop;
                    end else begin
                        edge_prev_4p5=$realtime;
                    end
                end    
            end
        end
    end
  
    //Check timing on 36MHz clock.
  
    initial begin : check_clk_36_timing
        edge_dlta_36    =    0;
        forever begin : outer_36
            //First check that clk_36 is low. If not, flag an error.
            if(clk_36 != 1'b0) begin
                $display("The simulation failed: clk_36 does not start out at 0 at time %t",$realtime);
                $stop;
            end
            //Store the current time as the previous time.
            edge_prev_36=$realtime;
    
            //For the first posedge back, we don't care if the time between the previous edge was too long. But too short is not OK.
            @(posedge clk_36 or posedge clk_36_irq);
            if(clk_36_irq) begin
                //Do nothing
            end else begin
                edge_dlta_36=$realtime-edge_prev_36;
                if(edge_dlta_36 < CLK_36_HALF_PERIOD - CLK_ERROR_WINDOW) begin
                    $display("The simulation failed: clk_36 had an out of bounds positive edge at time %t",$realtime);
                    $stop;
                end else begin
                    edge_prev_36=$realtime;
                end
            end
    
            forever begin : inner_36
                @(negedge clk_36 or posedge clk_36_irq);
                if(clk_36_irq) begin
                    disable inner_36;
                end else begin
                    edge_dlta_36=$realtime-edge_prev_36;
                    if(edge_dlta_36 < CLK_36_HALF_PERIOD - CLK_ERROR_WINDOW) begin
                        $display("The simulation failed: clk_36 had an out of bounds negative edge at time %t",$realtime);
                        $stop;
                    end else begin
                        edge_prev_36=$realtime;
                    end
                end
                @(posedge clk_36 or posedge clk_36_irq);
                if(clk_36_irq) begin
                    disable inner_36;
                end else begin
                    edge_dlta_36=$realtime-edge_prev_36;
                    if(edge_dlta_36 < CLK_36_HALF_PERIOD - CLK_ERROR_WINDOW) begin
                        $display("The simulation failed: clk_36 had an out of bounds positive edge at time %t",$realtime);
                        $stop;
                    end else begin
                        edge_prev_36=$realtime;
                    end
                end    
            end
        end
    end
  
  //Initial block statement controlling the other input signals.
  //recall that to access the internal state variable, it is dut.clk_mgmt0.state[2:0]
  //Note that this changes on a clk55 cycle, so any code conditioned on waiting for this variable change also is like writing @(posedge clk_55)
  
  //Idea: maybe instead of creating side-by-side comparison vectors as we did to test other modules, perhaps what we should
  //do is to use wait() statements to ensure that events that are required to happen actually happen.
  //If the simulation completes, then the simulation has passed.
  //If the simulation stalls, then we will have another initial statement that acts as a watchdog timer.
  //If the timeout for this initial statement finishes first, then it outputs a message saying simulation failed before asserting $stop.
  //If the initial statement that waits for all of the required events to complete finishes first, it outputs a success message before asserting $stop
  
  //The problem with doing this as we have described is that events may occur, but not in the order that we had hoped.
  //If we want to make sure that an event does not happen, we need to be a little bit more explicit about it.
  //Therefore, we will include several more initial blocks to check:
  //1. In clk_36_in runs 1 and 2, check to see that the output clocks are not asserted until the proper time.
  //2. Check proper response to sw reset of clk_4p5
  
  //081216 - Here we check that the clock gating signal does not arise until it is commanded to.
  //It turns out that we can't check that the clock doesn't transition until it is commanded to because
  //the clock gate lets through one pulse after the gate is disabled and the clock stops.
  //An analysis of the gaiting circuit shows this to be a fundamental result.
  //We allow this to happen and instead check for proper behavior of the gating signal itself.
  
    initial begin    : catch_no_clk_4p5_before_clk_enable
        wait(rst_n_ext);
    
        forever begin : pre_clk_enable_1_4p5
            @(posedge dut.clk_mgmt0.clk_36_running_resync_to_clk4p5_3 or posedge dut.clk_mgmt0.clk_36_running) begin
                if(dut.clk_mgmt0.clk_36_running) begin
                    disable pre_clk_enable_1_4p5;
                end else begin
                    $display("The simulation failed: clk_4p5 gating transitioned before it was enabled at time %t",$realtime);
                    $stop;
                end
            end
        end
        @(negedge clk_36_valid_reg)
        forever begin : pre_clk_enable_2_4p5
            @(posedge dut.clk_mgmt0.clk_36_running_resync_to_clk4p5_3 or posedge dut.clk_mgmt0.clk_36_running) begin
                if(dut.clk_mgmt0.clk_36_running) begin
                    disable pre_clk_enable_2_4p5;
                end else begin
                    $display("The simulation failed: clk_4p5 gating transitioned before it was enabled at time %t",$realtime);
                    $stop;
                end
            end
        end  
    end
  
    initial begin    : catch_no_clk_36_before_clk_enable
        wait(rst_n_ext);
    
        forever begin : pre_clk_enable_1_36
            @(posedge dut.clk_mgmt0.clk_36_running_resync_to_clk36_3 or posedge dut.clk_mgmt0.clk_36_running) begin
                if(dut.clk_mgmt0.clk_36_running) begin
                    disable pre_clk_enable_1_36;
                end else begin
                    $display("The simulation failed: clk_36 gating transitioned before it was enabled at time %t",$realtime);
                    $stop;
                end
            end
        end
        @(negedge clk_36_valid_reg)
        forever begin : pre_clk_enable_2_36
            @(posedge dut.clk_mgmt0.clk_36_running_resync_to_clk36_3 or posedge dut.clk_mgmt0.clk_36_running) begin
                if(dut.clk_mgmt0.clk_36_running) begin
                    disable pre_clk_enable_2_36;
                end else begin
                    $display("The simulation failed: clk_36 gating transitioned before it was enabled at time %t",$realtime);
                    $stop;
                end
            end
        end  
    end
  
  initial begin    : run_inputs_check_things_happen
  
    rst_n_ext         =    1'b0;
    clk_36_start      =    1'b0;
    rst_4p5_sw        =    1'b0;
    loop_j            =    0;
  
    #RST_DEASSERT_DLY
    
    rst_n_ext        =    1'b1;
  
    wait(dut.clk_mgmt0.state[2:0]==3'b001);    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
  
    @(posedge dut.clk_mgmt0.clk_55)
  
    wait(dut.clk_mgmt0.state[2:0]==3'b000);    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;

    @(posedge dut.clk_mgmt0.clk_55)
    
    wait(dut.clk_mgmt0.state[2:0]==3'b001);    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
        
    wait(clk_36_valid_reg);                    //Make sure that the clock valid signal gets asserted
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    
    $display("Got to checkpoint 1 at time %t",$realtime);
    
    //After trying all of this time to false-start the internal clocks, let's check to see if we have succeeded.
    //If we have, flag an error.
    
    //Now we could check at the end of this sequence to see if we have started the clocks.
    //But this wouldn't cover the situation in which the clocks start and then stop.
    //To do this properly, we need to have another forever block checking dut.clk_mgmt0.clk_36_running to make sure that it never goes high until we got to state 010.
    //We don't need to check any resynced derivatives since we are just checking clk_36_running.
    
    wait(dut.clk_mgmt0.state[2:0]==3'b010);    //Enable the internal clock
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
    
    wait(clk_36_running_reg);    //Make sure that the clock running signal gets asserted
    
    //In this initial statement, we will merely check that a fixed number of complete cycles occurs.
    //Proper division ratios are checked in another initial statement(s).
    
    @(posedge clk_36);    //Make sure that we get two complete cycles of clk_36 before moving along
    @(negedge clk_36);
    @(posedge clk_36);
    @(negedge clk_36);
    
    @(posedge clk_27p5);    //Make sure that we get two complete cycles of clk_27p5 before moving along
    @(negedge clk_27p5);
    @(posedge clk_27p5);
    @(negedge clk_27p5);
    
    @(posedge clk_4p5);    //Make sure that we get two complete cycles of clk_4p5 before moving along
    @(negedge clk_4p5);
    @(posedge clk_4p5);
    @(negedge clk_4p5);
   
    //Let the input clock stop on its own. We wait until the IRQ goes high and low.
    
    @(posedge clk_36_irq);
    @(negedge clk_36_irq);
    
    //Check to see that clock is no longer running or valid.
    //Use wait statements since we probably missed the edges
    
    wait(!clk_36_running_reg);
    wait(!clk_36_valid_reg);
    
    $display("Got to checkpoint 2 at time %t",$realtime);
    
    //Wait several clock cycles of clk_55
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    
    //Assert a software reset. Make sure that it asserts rst_n_4p5 low until we see two posedge on clk_4p5.
    //We need another initial block to monitor that condition.
    
    rst_4p5_sw        =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    rst_4p5_sw        =    1'b0;
    
    //Wait several clock cycles of clk_55
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    
    //Check to see that we can start clock properly again
    //This time we abuse the state machine in a different fashion
    
    wait(dut.clk_mgmt0.state[2:0]==3'b000);    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
  
    @(posedge dut.clk_mgmt0.clk_55);
  
    wait(dut.clk_mgmt0.state[2:0]==3'b001);    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;

    @(posedge dut.clk_mgmt0.clk_55);
    
    wait(dut.clk_mgmt0.state[2:0]==3'b000);    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
        
    wait(clk_36_valid_reg);                    //Make sure that the clock valid signal gets asserted
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    
    //After trying all of this time to false-start the internal clocks, let's check to see if we have succeeded.
    //If we have, flag an error.
    
    //Now we could check at the end of this sequence to see if we have started the clocks.
    //But this wouldn't cover the situation in which the clocks start and then stop.
    //To do this properly, we need to have another forever block checking dut.clk_mgmt0.clk_36_running to make sure that it never goes high until we got to state 010.
    //We don't need to check any resynced derivatives since we are just checking clk_36_running.
    
    wait(dut.clk_mgmt0.state[2:0]==3'b011);    //Enable the internal clock
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
    
    wait(clk_36_running_reg);                //Make sure that the clock running signal gets asserted
    
    //In this initial statement, we will merely check that a fixed number of complete cycles occurs.
    
    $display("Got to checkpoint 3 at time %t",$realtime);
    
    @(posedge clk_36);    //Make sure that we get two complete cycles of clk_36 before moving along
    @(negedge clk_36);
    @(posedge clk_36);
    @(negedge clk_36);
    
    @(posedge clk_27p5);    //Make sure that we get two complete cycles of clk_27p5 before moving along
    @(negedge clk_27p5);
    @(posedge clk_27p5);
    @(negedge clk_27p5);
    
    @(posedge clk_4p5);    //Make sure that we get two complete cycles of clk_4p5 before moving along
    @(negedge clk_4p5);
    @(posedge clk_4p5);
    @(negedge clk_4p5);
   
    //Let the input clock stop on its own. We wait until the IRQ goes high and low.
    
    @(posedge clk_36_irq);
    @(negedge clk_36_irq);
    
    //Check to see that clock is no longer running or valid.
    //Use wait statements since we probably missed the edges
    
    wait(!clk_36_running_reg);
    wait(!clk_36_valid_reg);
    
    //Wait several clock cycles of clk_55
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    
    //Eventually the clocks will start again and we will restart the clock. This time we will end the simulation with a full reset.
    
    wait(dut.clk_mgmt0.state[2:0]==3'b001)    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
  
    @(posedge dut.clk_mgmt0.clk_55);
  
    wait(dut.clk_mgmt0.state[2:0]==3'b000)    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;

    @(posedge dut.clk_mgmt0.clk_55);
    
    wait(dut.clk_mgmt0.state[2:0]==3'b001)    //Try to break the code - see that a start attempt before the clock is ready does not result in the internal clock being enabled.
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
        
    wait(clk_36_valid_reg);                   //Make sure that the clock valid signal gets asserted
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    
    $display("Got to checkpoint 4 at time %t",$realtime);
    
    //After trying all of this time to false-start the internal clocks, let's check to see if we have succeeded.
    //If we have, flag an error.
    
    //Now we could check at the end of this sequence to see if we have started the clocks.
    //But this wouldn't cover the situation in which the clocks start and then stop.
    //To do this properly, we need to have another forever block checking dut.clk_mgmt0.clk_36_running to make sure that it never goes high until we got to state 010.
    //We don't need to check any resynced derivatives since we are just checking clk_36_running.
    
    wait(dut.clk_mgmt0.state[2:0]==3'b010)    //Enable the internal clock
    clk_36_start    =    1'b1;
    @(posedge dut.clk_mgmt0.clk_55);
    clk_36_start    =    1'b0;
    
    wait(clk_36_running_reg);                 //Make sure that the clock running signal gets asserted
    
    //In this initial statement, we will merely check that a fixed number of complete cycles occurs.
    
    @(posedge clk_36);    //Make sure that we get two complete cycles of clk_36 before moving along
    @(negedge clk_36);
    @(posedge clk_36);
    @(negedge clk_36);
    
    @(posedge clk_27p5);    //Make sure that we get two complete cycles of clk_27p5 before moving along
    @(negedge clk_27p5);
    @(posedge clk_27p5);
    @(negedge clk_27p5);
    
    @(posedge clk_4p5);    //Make sure that we get two complete cycles of clk_4p5 before moving along
    @(negedge clk_4p5);
    @(posedge clk_4p5);
    @(negedge clk_4p5);
    
    //Wait for some clk_55 cycles then assert an external reset at weird times.
    
    $display("Got to checkpoint 5 at time %t",$realtime);
    
    for(loop_j=0;loop_j<20;loop_j=loop_j+1) begin
        @(posedge dut.clk_mgmt0.clk_55);
    end
    #0.2
    rst_n_ext    =     1'b0;
    #0.5
    rst_n_ext    =     1'b1;
    
    //We need to see that all of the internal resets go low.
    //We also need to see that timing is properly maintained.
    //In other words, each of the clocks associated with the three resets should have at least two positive edges prior to the reset signal coming up.
    //In addition, the reset signal needs to deassert on a positive edge.
    //These are best handled in three separate initial statements to check each of these three signals.
    //But then how do we get to the success message?
    
    //Option 1: We can use wait signals to wait for all of the resets to come back up then wait a few clk_55 cycles (to give time for the three aforementioned initial blocks to fail).
    
    @(posedge clk_27p5);    //Make sure that we get two complete cycles of clk_27p5 before moving along
    @(negedge clk_27p5);
    @(posedge clk_27p5);
    @(negedge clk_27p5);
    
    @(posedge dut.clk_4p5_unbuf);    //Make sure that we get two complete cycles of clk_4p5 unbuf before moving along
    @(negedge dut.clk_4p5_unbuf);    //Clk 4p5 gets gated after the reset.
    @(posedge dut.clk_4p5_unbuf);
    @(negedge dut.clk_4p5_unbuf);
    
    wait(rst_n_27p5);
    wait(rst_n_4p5);
    wait(rst_n_36_in);
    
    $display("The simulation passed: all of the events that we were waiting for occurred before the timeout at time %t",$realtime);
    $stop;
  
  end
  
  //Check for proper behavior of rst_n_27p5. Proper clock behavior is tested elsewhere.
  
    initial begin : catch_improper_rst_n_27p5
        @(negedge rst_n_ext);    //Fast forward to the final test
        @(posedge rst_n_ext);    //Wait until the final test is over    
        @(posedge clk_27p5 or posedge rst_n_27p5);
        if(rst_n_27p5) begin
            $display("The simulation failed: rst_n_27p5 came too early at time %t",$realtime);
            $stop;
        end
        @(posedge clk_27p5 or posedge rst_n_27p5); //Should work because according to our understanding of order of events, the clock comes before the reset signal. (just) So rst_n_27p5 should not be up quite yet.
        if(rst_n_27p5) begin
            $display("The simulation failed: rst_n_27p5 came too early at time %t",$realtime);
            $stop;
        end
        //We don't need to check if rst_n_27p5 comes up at all because that is check in the main (longest) initial statement.
    end
    
    //Check for proper behavior of rst_n_4p5 to the external reset. Proper clock behavior is tested elsewhere.
    
    initial begin : catch_improper_rst_n_4p5
        @(negedge rst_n_ext);    //Fast forward to the final test
        @(posedge rst_n_ext);    //Wait until the final test is over    
        @(posedge dut.clk_4p5_unbuf or posedge rst_n_4p5);
        if(rst_n_4p5) begin
            $display("The simulation failed: rst_n_4p5 came too early after ext reset at time %t",$realtime);
            $stop;
        end
        @(posedge dut.clk_4p5_unbuf or posedge rst_n_4p5); //Should work because according to our understanding of order of events, the clock comes before the reset signal. (just) So rst_n_4p5 should not be up quite yet.
        if(rst_n_4p5) begin
            $display("The simulation failed: rst_n_4p5 came too early after ext reset at time %t",$realtime);
            $stop;
        end
        //We don't need to check if rst_n_4p5 comes up at all because that is check in the main (longest) initial statement.
    end
    
    //Check for proper behavior of rst_n_36_in to the external reset. Proper clock behavior is tested elsewhere.
    
    initial begin : catch_improper_rst_n_36_in
        @(negedge rst_n_ext);    //Fast forward to the final test
        @(posedge rst_n_ext);    //Wait until the final test is over    
        @(posedge clk_36_in or posedge rst_n_36_in);
        if(rst_n_36_in) begin
            $display("The simulation failed: rst_n_36_in came too early at time %t",$realtime);
            $stop;
        end
        @(posedge clk_36_in or posedge rst_n_36_in); //Should work because according to our understanding of order of events, the clock comes before the reset signal. (just) So rst_n_36_in should not be up quite yet.
        if(rst_n_36_in) begin
            $display("The simulation failed: rst_n_36_in came too early at time %t",$realtime);
            $stop;
        end
        //We don't need to check if rst_n_36_in comes up at all because that is check in the main (longest) initial statement.
    end
    
    //Check proper response of clk_4p5 and rst_n_4p5 to sw reset
    
    initial begin : catch_improper_rst_n_4p5_sw
        @(posedge rst_4p5_sw);    //Fast forward to the final test
        @(negedge rst_4p5_sw);    //Wait until the final test is over    
        @(posedge dut.clk_4p5_unbuf or posedge rst_n_4p5);
        if(rst_n_4p5) begin
            $display("The simulation failed: rst_n_4p5 came too early after sw reset at time %t",$realtime);
            $stop;
        end
        @(posedge dut.clk_4p5_unbuf or posedge rst_n_4p5); //Should work because according to our understanding of order of events, the clock comes before the reset signal. (just) So rst_n_4p5 should not be up quite yet.
        if(rst_n_4p5) begin
            $display("The simulation failed: rst_n_4p5 came too early after sw reset at time %t",$realtime);
            $stop;
        end
        //We don't need to check if rst_n_4p5 comes up at all because that is check in the main (longest) initial statement.
    end
  
endmodule