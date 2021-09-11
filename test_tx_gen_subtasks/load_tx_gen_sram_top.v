/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load TX GEN SRAM Top                                                      //
//                                                                                     //
// Filename: load_tx_gen_sram_top.v                                                    //
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
//    Wrapper subtask for calling all of the individual ram-loading functions.         //
//    This is done directly to the radio SRAM for a TX GEN only simulation.            //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_top;
    
    //Send in all of the complicated bit patterns that can in fact vary
    
    input    [31:0]    seed_epc_select;
    input    [31:0]    seed_epc_write;
    
    input    [27:0]    select_bits;
    input    [27:0]    select_blank_bits;
    input    [21:0]    query_bits;
    input    [25:0]    read_bits;
    input    [27:0]    lock_bits;
    input    [9:0]     write_bits;

    //We may need to do these includes at the top level testbench module
    //We are getting an "unexpected task" error if we have them here
    
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_txcw0.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_select.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_select_blank_epc.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_query.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_query_rep.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_ack_rn16.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_ack_handle.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_nak.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_reqhdl.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_reqrn16.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_write.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_read.v"
    //`include "../../../FPGA-Test/test_tx_gen_subtasks/load_tx_gen_sram_lock.v"
    
    integer    seed_epc_select_int;
    integer    seed_epc_write_int;
    
    begin
        seed_epc_select_int    =    seed_epc_select;
        seed_epc_write_int     =    seed_epc_write;
        
        load_tx_gen_sram_txcw0;
        $display("Loaded TXCW0 RAM at time %t",$realtime);
        load_tx_gen_sram_select(select_bits,seed_epc_select_int);
        $display("Loaded select RAM at time %t",$realtime);
        load_tx_gen_sram_select_blank_epc(select_blank_bits);
        $display("Loaded select blank RAM at time %t",$realtime);
        load_tx_gen_sram_query(query_bits);
        $display("Loaded query RAM at time %t",$realtime);
        load_tx_gen_sram_query_rep;
        $display("Loaded query rep RAM at time %t",$realtime);
        load_tx_gen_sram_ack_rn16;
        $display("Loaded ack rn16 RAM at time %t",$realtime);
        load_tx_gen_sram_ack_handle;
        $display("Loaded ack handle RAM at time %t",$realtime);
        load_tx_gen_sram_nak;
        $display("Loaded nak RAM at time %t",$realtime);
        load_tx_gen_sram_reqhdl;
        $display("Loaded req handle RAM at time %t",$realtime);
        load_tx_gen_sram_reqrn16;
        $display("Loaded req rn16 RAM at time %t",$realtime);
        load_tx_gen_sram_write(write_bits,seed_epc_write_int);
        $display("Loaded write RAM at time %t",$realtime);
        load_tx_gen_sram_read(read_bits);
        $display("Loaded read RAM at time %t",$realtime);
        load_tx_gen_sram_lock(lock_bits);
        $display("Loaded lock RAM at time %t",$realtime);
    end
endtask