/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Tag and RX BFM                                                            //
//                                                                                     //
// Filename: tag_and_rx_bfm.v                                                          //
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
//    This file is the RFID tag and RX composite BFM.                                  //
//    Here, we would like to use a task that does not access global variables.         //
//    However, the problem is that, according to page 371 of the CRC Verilog book,     //
//    output and inout arguments are only passed back to the variables in the task     //
//    invocation statement upon completion of the task.                                //
//                                                                                     //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    tag_and_rx_bfm;

    //These are the inputs and outputs that we model for now.
    //In principle we can model reading bit lengths from the SRAM
    //but we actually check that in the data recovery sim.

    //input              clk_4p5;
    //input              rx_go;
    //input     [4:0]    radio_state;

    //output    [8:0]    radio_sram_address_rx;
    //output    [7:0]    radio_sram_wdata_4p5;
    //output             radio_sram_wren;
    //output             rx_done;
    //output             bit_decision_from_dr;
    //output             shift_rn16_from_dr;
    //output             shift_handle_from_dr;
        
    input    [15:0]    rn16_i_bits;
    input    [15:0]    handle_bits;
    input    [31:0]    seed_rn16_bits;
    input    [31:0]    seed_misc_bits;
    
    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_rx_gen_sram_localparam_defs.v"
    
    integer            seed_rn16_bits_intl;
    integer            seed_misc_bits_intl;
    integer            state_bit_cntr;
    integer            rn16_cntr;
    
    reg      [15:0]    state;
    reg      [15:0]    state_next;
    reg      [15:0]    rn16_bits    [0:5];
    
    begin
        rn16_cntr                =    0;
        state_bit_cntr           =    0;
        seed_rn16_bits_intl      =    seed_rn16_bits;
        seed_misc_bits_intl      =    seed_misc_bits;
        rx_done                  =    1'b0;
        radio_sram_address_rx    =    9'b0;
        radio_sram_wdata_4p5     =    8'b0;
        radio_sram_wren          =    1'b0;
        bit_decision_from_dr     =    1'b0;
        shift_rn16_from_dr       =    1'b0;
        shift_handle_from_dr     =    1'b0;
        state                    =    DR_STATE_DONE;
        state_next               =    DR_STATE_DONE;
        
        rn16_bits[0]    =    {$random(seed_rn16_bits_intl)} % (2**16);
        rn16_bits[1]    =    {$random(seed_rn16_bits_intl)} % (2**16);
        rn16_bits[2]    =    {$random(seed_rn16_bits_intl)} % (2**16);
        rn16_bits[3]    =    {$random(seed_rn16_bits_intl)} % (2**16);
        rn16_bits[4]    =    {$random(seed_rn16_bits_intl)} % (2**16);
        rn16_bits[5]    =    {$random(seed_rn16_bits_intl)} % (2**16);
    
        forever begin
        
            @(posedge clk_4p5);
                        
            state_next    =    state;    //Default state transition
            
            case(state)
                DR_STATE_DONE:    begin
                    rx_done            =    1'b0;
                    radio_sram_wren    =    1'b0;
                    state_bit_cntr     =    0;
                    if(rx_go)    begin
                        state_next     =    DR_STATE_RESET;
                        case(radio_state)
                            STATE_RX_RN16_I:    begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_RN16_I;   end
                            STATE_RX_RN16:      begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_RN16;     end
                            STATE_RX_PCEPC:     begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_PCEPC;    end
                            STATE_RX_HANDLE:    begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_HANDLE;   end
                            STATE_RX_WRITE:     begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_WRITE;    end
                            STATE_RX_READ:      begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_READ;     end
                            STATE_RX_LOCK:      begin    radio_sram_address_rx = RX_RAM_ADDR_OFFSET_LOCK;     end
                            default:    begin
                                $display("The simulation failed: radio state machine asserted a bad state during RX operation %t",$realtime);    //Note: we don't have this check in HW, we assume it is correct by design.
                                $stop;
                            end
                        endcase
                    end
                end
                DR_STATE_RESET:    begin
                    state_bit_cntr    =    0;
                    state_next        =    DR_STATE_IDLE;
                end
                DR_STATE_IDLE: begin
                    case(radio_state)
                        STATE_RX_RN16_I:    begin    if(state_bit_cntr>=EFFECTIVE_REG_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end    
                        STATE_RX_RN16:      begin    if(state_bit_cntr>=EFFECTIVE_REG_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end    
                        STATE_RX_PCEPC:     begin    if(state_bit_cntr>=EFFECTIVE_REG_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end    
                        STATE_RX_HANDLE:    begin    if(state_bit_cntr>=EFFECTIVE_REG_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end    
                        STATE_RX_WRITE:     begin    if(state_bit_cntr>=EFFECTIVE_EXT_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end    
                        STATE_RX_READ:      begin    if(state_bit_cntr>=EFFECTIVE_EXT_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end    
                        STATE_RX_LOCK:      begin    if(state_bit_cntr>=EFFECTIVE_REG_RPLY_BITS) begin state_next=DR_STATE_LOCKED;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end
                        default:    begin
                            $display("The simulation failed: radio state machine asserted a bad state during RX operation %t",$realtime);    //Note: we don't have this check in HW, we assume it is correct by design.
                            $stop;
                        end
                    endcase    
                end
                DR_STATE_LOCKED: begin
                    if(state_bit_cntr >= EFFECTIVE_PILOT_BITS)    begin
                        state_next        =    DR_STATE_SYNC;
                        state_bit_cntr    =    0;
                    end else begin
                        state_bit_cntr    =    state_bit_cntr+1;
                    end
                end
                DR_STATE_SYNC:    begin
                    if(state_bit_cntr >= EFFECTIVE_SYNC_BITS)    begin
                        state_next        =    DR_STATE_BITS;
                        state_bit_cntr    =    0;
                    end else begin
                        state_bit_cntr    =    state_bit_cntr+1;
                    end
                end
                DR_STATE_BITS: begin
                    if(state_bit_cntr % 8 == 7)  begin                                         //If we've received a byte
                        radio_sram_address_rx    =    radio_sram_address_rx+1;                 //Yes, do this on the very first one since the first byte is the number of bits to process
                        radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;    //Generate a random byte. Note that this data may differ from RN16s and handles
                        radio_sram_wren          =    1'b1;                                    //We need to make sure that this gets deasserted properly if we end the bits on a byte. 
                    end    else begin                                                          //This is done by deasserting wren at the beginning of the next state.
                        radio_sram_wren          =    1'b0;                                    //Oh wait - next state for sure writes a byte, so we don't need to worry about it
                    end
                
                    case(radio_state)
                        STATE_RX_PCEPC:    begin    if(state_bit_cntr>=RX_BITS_PCEPC)    begin state_next=DR_STATE_RPT_EXIT_CODE;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end        
                        STATE_RX_WRITE:    begin    if(state_bit_cntr>=RX_BITS_WRITE)    begin state_next=DR_STATE_RPT_EXIT_CODE;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end
                        STATE_RX_READ:     begin    if(state_bit_cntr>=RX_BITS_READ)     begin state_next=DR_STATE_RPT_EXIT_CODE;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end
                        STATE_RX_LOCK:     begin    if(state_bit_cntr>=RX_BITS_LOCK)     begin state_next=DR_STATE_RPT_EXIT_CODE;    state_bit_cntr=0; end else begin state_bit_cntr=state_bit_cntr+1; end end
                        STATE_RX_RN16_I:   begin
                            if(state_bit_cntr < 16)    begin 
                                bit_decision_from_dr      =    rn16_i_bits[15-state_bit_cntr];
                                shift_rn16_from_dr        =    1'b1;
                                state_bit_cntr            =    state_bit_cntr+1; 
                            end else if(state_bit_cntr    >=    RX_BITS_RN16_I)     begin
                                shift_rn16_from_dr        =    1'b0;
                                state_next                =    DR_STATE_RPT_EXIT_CODE;
                                state_bit_cntr            =    0; 
                            end else begin
                                shift_rn16_from_dr        =    1'b0;
                                state_bit_cntr            =    state_bit_cntr+1;
                            end 
                        end    
                        STATE_RX_RN16:    begin    
                            if(state_bit_cntr < 16)     begin 
                                bit_decision_from_dr      =    rn16_bits[rn16_cntr][15-state_bit_cntr];
                                shift_rn16_from_dr        =    1'b1;
                                state_bit_cntr            =    state_bit_cntr+1; 
                            end else if(state_bit_cntr    >=    RX_BITS_RN16)     begin
                                rn16_cntr                 =    (rn16_cntr + 1) % 6;
                                shift_rn16_from_dr        =    1'b0;
                                state_next                =    DR_STATE_RPT_EXIT_CODE;
                                state_bit_cntr            =    0; 
                            end else begin
                                shift_rn16_from_dr        =    1'b0;
                                state_bit_cntr            =    state_bit_cntr+1; 
                            end 
                        end    
                        STATE_RX_HANDLE:    begin    
                            if(state_bit_cntr < 16)     begin 
                                bit_decision_from_dr      =    handle_bits[15-state_bit_cntr];
                                shift_handle_from_dr      =    1'b1;
                                state_bit_cntr            =    state_bit_cntr+1; 
                            end else if(state_bit_cntr    >=    RX_BITS_RN16)     begin
                                shift_handle_from_dr      =    1'b0;
                                state_next                =    DR_STATE_RPT_EXIT_CODE;
                                state_bit_cntr            =    0; 
                            end else begin
                                shift_handle_from_dr      =    1'b0;
                                state_bit_cntr            =    state_bit_cntr+1; 
                            end 
                        end
                        default:    begin
                            $display("The simulation failed: radio state machine asserted a bad state during RX operation %t",$realtime);    //Note: we don't have this check in HW, we assume it is correct by design.
                            $stop;
                        end
                    endcase    
                end
                DR_STATE_RPT_EXIT_CODE:    begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MI_BYT0;
                end
                DR_STATE_RPT_MI_BYT0: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MI_BYT1;
                end
                DR_STATE_RPT_MI_BYT1: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MI_BYT2;
                end
                DR_STATE_RPT_MI_BYT2: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MI_BYT3;
                end
                DR_STATE_RPT_MI_BYT3: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MQ_BYT0;
                end
                DR_STATE_RPT_MQ_BYT0: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MQ_BYT1;
                end    
                DR_STATE_RPT_MQ_BYT1: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MQ_BYT2;
                end
                DR_STATE_RPT_MQ_BYT2: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_RPT_MQ_BYT3;
                end
                DR_STATE_RPT_MQ_BYT3: begin
                    radio_sram_address_rx    =    radio_sram_address_rx+1;
                    radio_sram_wdata_4p5     =    {$random(seed_misc_bits_intl)} % 256;
                    radio_sram_wren          =    1'b1;
                    state_next               =    DR_STATE_DONE;
                    rx_done                  =    1'b1;            //Signal to the radio fsm that the rx operation is done
                end
                DR_STATE_DUMMY: begin
                    $display("The simulation failed: RX BFM entered bad state at %t",$realtime);
                    $stop;
                end
                default: begin
                    $display("The simulation failed: RX BFM entered bad state at %t",$realtime);
                    $stop;
                end    
            endcase
            state    =    state_next;
        end
    end
endtask