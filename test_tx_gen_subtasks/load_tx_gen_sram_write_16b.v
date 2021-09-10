/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Load Write 16b Command                                                    //
//                                                                                     //
// Filename: load_tx_gen_sram_write_16b.v                                              //
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
//    Load 16 bits of the WRITE command into the TX section of the radio SRAM.         //
//    This is done through directly into the radio SRAM for TX GEN only sim.           //
//                                                                                     //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

task    load_tx_gen_sram_write_16b;
    
    input    [9:0]     write_packet_bits;
    input    [7:0]     ebv;
    input    [15:0]    data;
    input    [2:0]     write_offset;
    input              is_last_write;

    `include "../../../sim_tb/test_tx_gen_subtasks/load_tx_gen_sram_localparam_defs.v"
    
    reg                done_flag;
    integer            loop_sram;
    integer            seed_intl;
    
    reg    [17:0]      write_vector;
    reg    [3:0]       write_offset_new;
    
    
    begin
        write_vector    =    {write_packet_bits,ebv};
        done_flag       =    1'b0;
        clk_ram         =    1'b0;
        case(write_offset)
            3'd0    :    begin    write_offset_new    =    4'b0000;    end
            3'd1    :    begin    write_offset_new    =    4'b0011;    end
            3'd2    :    begin    write_offset_new    =    4'b0110;    end
            3'd3    :    begin    write_offset_new    =    4'b1001;    end
            3'd4    :    begin    write_offset_new    =    4'b1100;    end
            3'd5    :    begin    write_offset_new    =    4'b1111;    end
            default :    begin    write_offset_new    =    4'b0000;    end
        endcase        
        fork    
            begin
                while (done_flag == 1'b0)    begin
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                    =    1'b1;
                    #CLK_RAM_HALF_PERIOD;
                    clk_ram                    =    1'b0;                                    //When this ends, have it end low.
                end
            end
            begin
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b1;                                    //This is an access of a global variable in the top level of the simulation
                radio_sram_addr_27p5           =    (TX_RAM_ADDR_OFFSET_WRITE0 << 4) + {2'b00,write_offset_new,3'b000};
                radio_sram_wdata_27p5          =    {DUMMY_ZERO,BEGIN_REGULAR};
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {write_vector[17] ? SINGLE_ONE : SINGLE_ZERO,RTCAL};
                for(loop_sram=0;loop_sram<8;loop_sram=loop_sram+1)    begin                            //We should find a way to determine the loop length based on the specified bit string
                    @(negedge clk_ram);
                    radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                    radio_sram_wdata_27p5      =    {write_vector[15-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,write_vector[15-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
                end
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {XOR_NEXT_16B,write_vector[0] ? SINGLE_ONE : SINGLE_ZERO};
                for(loop_sram=0;loop_sram<8;loop_sram=loop_sram+1)    begin                            //We should find a way to determine the loop length based on the specified bit string
                    @(negedge clk_ram);
                    radio_sram_addr_27p5       =    radio_sram_addr_27p5+9'd1;
                    radio_sram_wdata_27p5      =    {data[14-2*loop_sram] ? SINGLE_ONE : SINGLE_ZERO,data[14-2*loop_sram+1] ? SINGLE_ONE : SINGLE_ZERO};
                end
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {INSERT_CRC16,INSERT_HANDLE};
                @(negedge clk_ram);
                radio_sram_addr_27p5           =    radio_sram_addr_27p5+9'd1;
                radio_sram_wdata_27p5          =    {TXCW0,is_last_write ? LAST_WRITE : END_PACKET};
                @(negedge clk_ram);
                radio_sram_we_data_27p5        =    1'b0;
                @(negedge clk_ram);
                done_flag                      =    1'b1;
            end
        join
    end
endtask