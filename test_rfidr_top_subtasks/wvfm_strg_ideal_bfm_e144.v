/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : SX1257 RX and TAG DTC-over-SPI sub BFM                                    //
//                                                                                     //
// Filename: sx1257_rx_and_tag_dtc_spi_bfm.v                                           //
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
//    This file serves as a bfm that conducts the same operations as                   //
//    does the real waveform storage block. The reason for having this is              //
//    to confirm the proper connectivity of the real waveform storage                  //
//    block at top level.                                                              //
//                                                                                     //
//    091016 - File created                                                            //
//    091116 - This should probably be instantiated as a module, the                   //
//    task and always blocks are not working well together.                            //
//    However, the problem is that we are accessing some global ideal RAM              //
//    which would require an inout statement to access the ram?                        //
//    In addition, in Verilog you can't pass arrays between modules.                   //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    wvfm_strg_ideal_bfm_e144;

    // Global Inputs
    //input    wire            in_i_extl,
    //input    wire            in_q_extl,
    //input    wire            clk_36_extl,
    //input    wire            rst_n_extl,
    //input    wire            rfidr_top0.wvfm_go,

    // Parameter and localparam declarations
    
    localparam    MEM_SAMPLE_DEPTH    =    16'd32767; // One sample = one sample of i and q data. There are 81920 bits available in RAM.
    
    localparam    STATE_DONE          =    2'd0;
    localparam    STATE_WAIT          =    2'd1;
    localparam    STATE_SHIFT         =    2'd2;
    localparam    STATE_LOAD          =    2'd3;
    
    // Register and wire declarations
    
    reg              in_i_dly, in_q_dly;
    reg    [7:0]     shift_reg_next, shift_reg;
    reg    [24:0]    wait_idx_next, wait_idx;
    reg    [14:0]    smpl_idx_next, smpl_idx;
    reg    [1:0]     state_next, state;
    reg    [1:0]     load_ctr_next, load_ctr;
    reg              wait_idx_clear, smpl_idx_clear, load_ctr_clear;
    reg    [12:0]    wraddress;
    
    begin
    
        //Initialize state variables
        
        wait_idx        =    24'b0;
        smpl_idx        =    15'b0;
        load_ctr        =    2'b0;
        state           =    STATE_DONE;
        shift_reg       =    8'b0;
        in_i_dly        =    1'b0;
        in_q_dly        =    1'b0;

        forever begin
            @(posedge clk_36_extl)
            // Defaults
        
            shift_reg_next    =    {in_q_dly,in_i_dly,shift_reg[7:2]};        //We may actually save LUT if we break this up into two 1-bit shift registers and interleave the outputs
            wait_idx_next     =    wait_idx+24'd1;
            smpl_idx_next     =    smpl_idx+15'd1;
            state_next        =    state;
            load_ctr_next     =    load_ctr+2'b01;
            wait_idx_clear    =    1'b1;
            smpl_idx_clear    =    1'b1;
            load_ctr_clear    =    1'b1;
            wraddress         =    smpl_idx[14:2];
        
            case(state)
        
                STATE_DONE: begin
                    if(rfidr_top_e144_0.wvfm_go)    begin
                        state_next    =    STATE_WAIT;
                    end
                end
            
                STATE_WAIT: begin
                    wait_idx_clear    =    1'b0;
                
                    if(wait_idx >= (8'd5 << 16))                            //This value is from the mcu_bfm_rfidr_top.v BFM. Maybe bring out as input?
                        state_next    =    STATE_SHIFT;
                end
            
                STATE_SHIFT: begin
                    smpl_idx_clear        =    1'b0;
                    load_ctr_clear        =    1'b0;
            
                    if(smpl_idx >= MEM_SAMPLE_DEPTH) begin
                        state_next    =    STATE_DONE;
                    end
                    else if(load_ctr    ==    2'b10) begin
                        state_next        =    STATE_LOAD;
                    end
                end
            
                STATE_LOAD: begin
            
                    smpl_idx_clear                    =    1'b0;
                    load_ctr_clear                    =    1'b0;
                    wvfm_mem_ideal[wraddress]         =    shift_reg;
                
                    if(smpl_idx >= MEM_SAMPLE_DEPTH) begin
                        state_next    =    STATE_DONE;
                    end else begin
                        state_next    =    STATE_SHIFT;
                    end
            
                end
            endcase

            if(wait_idx_clear)
                wait_idx    =    24'b0;
            else
                wait_idx    =    wait_idx_next;
            if(smpl_idx_clear)
                smpl_idx    =    15'b0;
            else
                smpl_idx    =    smpl_idx_next;
            if(load_ctr_clear)
                load_ctr    =    2'b0;
            else
                load_ctr    =    load_ctr_next;
            
            state           =    state_next;
            shift_reg       =    shift_reg_next;
            in_i_dly        =    in_i_extl;
            in_q_dly        =    in_q_extl;
        end
    end
endtask