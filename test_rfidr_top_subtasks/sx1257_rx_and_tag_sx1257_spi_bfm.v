/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : SX1257 RX and TAG SX1257-over-SPI sub BFM                                 //
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
//    This file handles SPI traffic destined for the SX1257                            //
//    (namely RX gain) and applies the result internally to the gain                   //
//    Make this a module, because all of this task business is                         //
//    getting out of hand with the global variable accessing.                          //
//                                                                                     //
//    091016 - File created                                                            //
//    101017 - Updated to reflect new LNA gain strategy, and LNA saturation.           //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

module    sx1257_rx_and_tag_sx1257_spi_bfm
    (
        input     wire              cntrlr_nps_rdio,
        input     wire              cntrlr_pclk,
        input     wire              cntrlr_copi,
        input     wire              sx1257_clk,
        output    reg               cntrlr_cipo_sx1257_drive,
        output    reg               cntrlr_cipo_sx1257_out,
        output    wire    [63:0]    lna_gain_bits
    );

        localparam    SX1257_IDLE                 =    3'd0;
        localparam    SX1257_WNR_BIT_PCLK_LOW     =    3'd1;
        localparam    SX1257_WNR_BIT_PCLK_HIGH    =    3'd2;
        localparam    SX1257_RX_ADDR_CLK_LOW      =    3'd3;
        localparam    SX1257_RX_ADDR_CLK_HIGH     =    3'd4;
        localparam    SX1257_RX_DATA_CLK_LOW      =    3'd5;
        localparam    SX1257_RX_DATA_CLK_HIGH     =    3'd6;
        localparam    SX1257_LIMBO                =    3'd7;
        
        localparam    HI_GAIN_SETTING             =    8'b001_1010_0;    //Set to 0x34 - Max LNA gain, LNA and SDM saturate at similar levels
        localparam    MD_GAIN_SETTING             =    8'b100_1010_0;    //Set to 0x94 - Med LNA gain, LNA and SDM saturate at similar levels
        localparam    LO_GAIN_SETTING             =    8'b110_1010_0;    //Set to 0xD4 - Min LNA gain, LNA and SDM saturate at similar levels
        localparam    RADIO_RX_ADDRESS            =    7'b000_1100;      //First bit is a 1 for write, 0x0c is address for Rx Gain
        
        reg    [2:0]    sx1257_state;
        reg    [3:0]    sx1257_ctr;
        reg    [6:0]    sx1257_addr;
        reg    [7:0]    sx1257_rdata;
        reg    [7:0]    sx1257_wdata;
        reg             sx1257_wnr_bit;
        reg    [7:0]    sx1257_mem    [0:127];
        
        integer         sx1257_addr_int;
        integer         loop_ram_init;
        
        real            lna_gain;
        
        assign          lna_gain_bits    =    $realtobits(lna_gain);
    
        initial begin
            sx1257_state               =    SX1257_IDLE;
            cntrlr_cipo_sx1257_drive   =    1'b0;
            cntrlr_cipo_sx1257_out     =    1'bz;
            lna_gain                   =    0.070794578438;
            
            for(loop_ram_init=0;loop_ram_init<128;loop_ram_init=loop_ram_init+1)    begin
                sx1257_mem[loop_ram_init]    =    8'b0;
            end
            
            sx1257_mem[RADIO_RX_ADDRESS]    =    LO_GAIN_SETTING;
        end
    
        always @(posedge sx1257_clk)    begin
            case(sx1257_state)
                SX1257_IDLE: begin
                    cntrlr_cipo_sx1257_drive   =    1'b0;
                    cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
                    sx1257_ctr                 =    4'b0;                        //Indirectly initialize state variables after a reset
                    sx1257_addr                =    7'b0;
                    sx1257_rdata               =    8'b0;
                    sx1257_wdata               =    8'b0;
                    if(!cntrlr_nps_rdio && !cntrlr_pclk) begin                   //Stay here and wait until we get a falling edge on cntrlr_nps_radio
                        sx1257_state           =    SX1257_WNR_BIT_PCLK_LOW;
                    end
                end
                SX1257_WNR_BIT_PCLK_LOW: begin
                    cntrlr_cipo_sx1257_drive       =    1'b1;
                    cntrlr_cipo_sx1257_out         =    1'b0;
                    if (cntrlr_pclk) begin
                        sx1257_wnr_bit             =    cntrlr_copi;
                        sx1257_state               =    SX1257_WNR_BIT_PCLK_HIGH;
                    end
                    if(cntrlr_nps_rdio)    begin
                        cntrlr_cipo_sx1257_drive   =    1'b0;
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
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
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
                        sx1257_state               =    SX1257_IDLE;
                    end
                end
                SX1257_RX_ADDR_CLK_LOW: begin
                    cntrlr_cipo_sx1257_drive       =    1'b1;
                    cntrlr_cipo_sx1257_out         =    1'b0;
                    if(cntrlr_pclk)    begin
                        sx1257_ctr                 =    sx1257_ctr+4'd1;
                        sx1257_addr                =    {sx1257_addr[5:0],cntrlr_copi};
                        sx1257_state               =    SX1257_RX_ADDR_CLK_HIGH;
                    end
                    if(cntrlr_nps_rdio)    begin
                        cntrlr_cipo_sx1257_drive   =    1'b0;
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
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
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
                        sx1257_state               =    SX1257_IDLE;
                    end
                end
                SX1257_RX_DATA_CLK_LOW: begin
                    if(cntrlr_pclk)    begin
                        sx1257_ctr                 =    sx1257_ctr+4'd1;
                        sx1257_rdata               =    {sx1257_rdata[6:0],cntrlr_copi};
                        sx1257_state               =    SX1257_RX_DATA_CLK_HIGH;
                    end
                    if(cntrlr_nps_rdio)    begin
                        cntrlr_cipo_sx1257_drive   =    1'b0;
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
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
                        sx1257_ctr                 =    4'b0;
                        if(sx1257_wnr_bit) begin
                            sx1257_addr_int                =    sx1257_addr;
                            sx1257_mem[sx1257_addr_int]    =    sx1257_rdata;
                            if(sx1257_addr != RADIO_RX_ADDRESS)    begin
                                $display("Wrong address %b vs. correct address %b written to SX1257 SPI at time %t",sx1257_addr,RADIO_RX_ADDRESS,$realtime);
                                $stop;
                            end
                            case(sx1257_rdata)
                                HI_GAIN_SETTING:    begin    lna_gain    =    10; end
                                MD_GAIN_SETTING:    begin    lna_gain    =    0.63095734448; end
                                LO_GAIN_SETTING:    begin    lna_gain    =    0.070794578438; end
                                default:    begin
                                    $display("Wrong data written to SX1257 SPI at time %t",$realtime);
                                    $stop;
                                end
                            endcase
                        end
                        sx1257_state               =    SX1257_LIMBO;
                    end
                    if(cntrlr_nps_rdio)    begin
                        cntrlr_cipo_sx1257_drive   =    1'b0;
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
                        sx1257_state               =    SX1257_IDLE;
                    end
                end
                SX1257_LIMBO: begin                                                  //Wait for rise of NPS or PCLK to determine a return to idle or BURST mode
                    if(cntrlr_nps_rdio)    begin
                        //While waiting for this to happen in the wait statement at the beginning of this simulation, SX1257 and FPGA will drive each other
                        //This results in a short 1'bx on cntrlr_cipo in the simulation.
                        //This is a simulation artifact that does nothing and I'm not going to solve it at the moment.
                        cntrlr_cipo_sx1257_drive   =    1'b0;
                        cntrlr_cipo_sx1257_out     =    1'bz;                        //Must tristate when NPS goes low
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
endmodule