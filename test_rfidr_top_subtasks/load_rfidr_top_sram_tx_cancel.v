/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load TX Cancel RAM                                                        //
//                                                                                     //
// Filename: load_rfidr_top_sram_tx_cancel.v                                           //
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
//    Load TX Cancel SRAM. This feature isn't used anymore. This feature was used for  //
//    the nonblind TX cancellation algorithm which used a map of the tunable micro-    //
//    wave network reflection coefficients to help converge the TX cancellation        //
//    algorithm very quickly.                                                          //
//    This is done through SPI at the top level of the FPGA image.                     //
//                                                                                     //
//    090121 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

`define    NULL    0

task    load_rfidr_top_sram_tx_cancel;
    
    reg    [10:0]    txcancel_sram_addr_27p5;
    reg    [7:0]     txcancel_sram_wdata_27p5;
    
    integer    ram_in_fid, ram_in_rslt;
    
    begin
        ram_in_fid                =    $fopen("../../../octave_tb/rtl_test_vectors/txcancel_2bit_ram.txt","r");
        if (ram_in_fid    == `NULL) begin
            $display("The TX cancel RAM was null");
            $stop;
        end
    
        for(txcancel_sram_addr_27p5 = 11'b0; txcancel_sram_addr_27p5 < 11'b100_0000_0000; txcancel_sram_addr_27p5=txcancel_sram_addr_27p5+11'd1)    begin
            ram_in_rslt             =    $fscanf(ram_in_fid,"%d\n",txcancel_sram_wdata_27p5);
            if (ram_in_rslt == 0)    begin
                $display("Error: ASCII data file containing tx cancel SRAM information could not be read at time %t",$realtime);
                $stop;
            end
            //$display("Loading TX Cancel RAM Address %d against value %d at time %t",txcancel_sram_addr_27p5[9:0],txcancel_sram_wdata_27p5,$realtime);
            wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0010,txcancel_sram_addr_27p5[9:0]},txcancel_sram_wdata_27p5,8'b0000_0000);
        end
        
        wr_3byte_transaction_from_mcu_spi_cntrlr(1'b1,{4'b0010,10'b0},8'd47,8'b0000_0000); //For some reason this isn't getting loaded in
        
        $display("Loaded TX Cancel RAM at time %t",$realtime);    
    end
endtask