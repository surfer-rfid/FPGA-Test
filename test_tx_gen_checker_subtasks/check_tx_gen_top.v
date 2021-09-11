/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Check TX GEN TOP Generation                                               //
//                                                                                     //
// Filename: check_tx_gen_top.v                                                        //
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
//    Top level wrapper for checking the proper outputs of the TX GEN block.           //
//                                                                                     //
//    090621 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task check_tx_gen_top;
    
    //Send in all of the complicated bit patterns that can in fact vary
    
    input    [31:0]    seed_epc_select;
    input    [31:0]    seed_epc_write;
    input    [31:0]    seed_rn16_bits;
    
    input    [27:0]    select_bits;
    input    [27:0]    select_blank_bits;
    input    [21:0]    query_bits;
    input    [25:0]    read_bits;
    input    [27:0]    lock_bits;
    input    [9:0]     write_bits;
    input    [15:0]    rn16_i_bits;
    input    [15:0]    handle_bits;
    
    //It seems as if we need to define these included tasks at test_tx_gen.v top level.
    
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_txcw0.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_select.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_select_blank_epc.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_query.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_query_rep.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_ack_rn16.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_ack_handle.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_nak.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_reqhdl.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_reqrn16.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_write.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_read.v"
    //`include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_lock.v"
    
    `include "../../../FPGA-Test/test_tx_gen_subtasks/load_rx_gen_sram_localparam_defs.v"
    `include "../../../FPGA-Test/test_tx_gen_checker_subtasks/check_tx_gen_localparam_defs.v"
    
    integer    seed_epc_select_int;
    integer    seed_epc_write_int;
    integer    seed_rn16_bits_int;
    integer    write_packet_counter;
    
    begin
        seed_epc_select_int     =    seed_epc_select;
        seed_epc_write_int      =    seed_epc_write;
        seed_rn16_bits_int      =    seed_rn16_bits;
        write_packet_counter    =    0;
    
        forever    begin
            //@(posedge clk_4p5);
            if(tx_go) begin
                @(posedge clk_4p5);    //Put this here to compensate for delay of tx_gen
                case(radio_state)
                    STATE_TX_TXCW0:       begin    check_tx_gen_txcw0;                                      end
                    STATE_TX_SELECT:      begin    check_tx_gen_select(select_bits,seed_epc_select_int);    end
                    STATE_TX_QUERY:       begin    check_tx_gen_query(query_bits);                          end
                    STATE_TX_QRY_REP:     begin    check_tx_gen_query_rep;                                  end
                    STATE_TX_ACK_RN16:    begin    check_tx_gen_ack_rn16(rn16_i_bits);                      end
                    STATE_TX_NAK_CNTE:    begin    check_tx_gen_nak;                                        end
                    STATE_TX_NAK_EXIT:    begin    check_tx_gen_nak;                                        end
                    STATE_TX_REQHDL:      begin    check_tx_gen_reqrn16(rn16_i_bits);                       end //Need to check if we even need to feed this rn16_bits 
                    STATE_TX_REQRN16:     begin    check_tx_gen_reqrn16(handle_bits);                       end //(I'm guessing not, but I don't have the RFID specification on me at the moment)
                    STATE_TX_READ:        begin    check_tx_gen_read(read_bits,handle_bits);                end
                    STATE_TX_LOCK:        begin    check_tx_gen_lock(lock_bits,handle_bits);                end
                    STATE_TX_ACK_HDL:     begin    check_tx_gen_ack_rn16(handle_bits);                      end
                    STATE_TX_SEL_2:       begin    check_tx_gen_select_blank_epc(select_blank_bits);        end
                    STATE_TX_WRITE:       begin
                        check_tx_gen_write(write_bits,seed_epc_write_int,seed_rn16_bits_int,handle_bits,write_packet_counter);
                        write_packet_counter    =    (write_packet_counter + 1) % 6;
                    end
                    default: begin    $display("Error - got an RX state %b with tx_go at time %t",radio_state,$realtime); $stop; end
                endcase
            end
            else    begin
                @(posedge clk_4p5);
            end
            if(out_i_baseband_4p5 == 1'b0 && tx_en == 1'b1)    begin
                $display("Error - TX level is zero while outside of a TX state at time %t",$realtime);
                $stop;
            end
        end
    end
endtask

//Problem with handling write is that we are going to be getting different data each time for sure
//But, we know what the data is and what order it is coming in
//So in this block, we would want a counter of which write packet we are receiving, then inside the write block choose a set of data to check against the received values.
//One issue with this is that we should in principle utilize a different rn16 for each of these writes (to xor against the bits to be written).
//To solve this problem what we need to do is to send in an rn16 seed which is used to generate one of 6 seeded rn16 values.
//Thus, we also need to make sure that we use this same seed as part of the tag/rx bfm to generate 6 rn16 values that are sent back
//The problem is that we really want to send rn16 values back that are willy nilly.
//This would be trivial if we only used the rn16 for writes but we also seem to use it for ack_rn16.
//Remind ourselves: when do we use ack_rn16 vs. ack_hdl? Answer: see page 79 of the spec. We only ack_rn16 when we get the first rn16 as part of the querying process.
//The rest of the time, we ack the handle back.
//So this is fine. But when we are acking back oodles of different tags as part of our programming check in this simulation, what happens in the tag and rx bfm?
//Answer is: right now we send the same rn16_i_bits over and over. Same with the rn16_bits.
//It's probably OK for now to send the same rn16_i_bits over and over but in the tag and rx bfm we need to send multiple rn16_bits based on an initial seed.