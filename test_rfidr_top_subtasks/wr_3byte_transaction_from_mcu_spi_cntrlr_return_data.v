/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : Write/read 3 bytes over MCU controller SPI while returning data           //
//                                                                                     //
// Filename: wr_3byte_transaction_from_mcu_spi_cntrlr_return_data.v                    //
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
//    Write a general task for reading and writing from the MCU SPI Controller         //
//    Note that cipo in this case doesn't need to be tristated since the only          //
//    peripheral addressed by the MCU is the FPGA.                                     //
//    This task returns data.                                                          //
//                                                                                     //
//    091016 - File created                                                            //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////
    
    task    wr_3byte_transaction_from_mcu_spi_cntrlr_return_data;
        //Emulate NRF51822 SPI CPHA=0; namely, data transitions on the falling edge and is sampled on the rising edge
        //This means that the first data must be placed on the line a half clock cycle prior to the first rising edge
        //Inputs from simulation
        //input            prphrl_cipo;     - Access as global variable
        //Input arguments
        input                     write_readb;
        input            [13:0]   address;
        input            [7:0]    data_in;
        output           [7:0]    data_return_out;
        //Outputs
        //output           prphrl_copi_extl; - Access as global variable
        //output           prphrl_nps_extl;  - Access as global variable
        //output           prphrl_pclk_extl; - Access as global variable
        
        //Localparam Definitions
        localparam     CLK_SPI_HALF_PERIOD    =    (0.5e9)/(4.8e6);        //Max. of NRF51822 is 4Mbps. But with respect to CLK27P5 it's effectively 4.8MHz worst case in this sim. Use a 1x clock to make the SPI 
        
        //Task Declarations
        reg              [7:0]    data_return;
        reg                       done_flag;
        reg                       clk_pclk_nrf51822;
        //Local Variable Declarations
        reg    signed    [5:0]    loop_i;          //Use a reg instead of an integer to ensure that we are properly using case syntax.
        reg    signed    [5:0]    loop_j;
        reg              [22:0]   tx_data;
        //Task statement
        begin
            done_flag            =    1'b0;
            clk_pclk_nrf51822    =    1'b0;
            prphrl_nps_extl      =    1'b1;
            prphrl_pclk_extl     =    1'b0;
            prphrl_copi_extl     =    1'b0;
            fork    begin
                while (done_flag == 1'b0)    begin
                    #CLK_SPI_HALF_PERIOD;
                    clk_pclk_nrf51822        =    1'b1;
                    #CLK_SPI_HALF_PERIOD;
                    clk_pclk_nrf51822        =    1'b0;            //When this ends, have it end low.
                end
            end    begin
                tx_data               =    {write_readb,address,data_in};    //As per our LUT optimizations, we adopted a unified memory map for the FPGA. Writes to the SX1257 are done through the user register map.
                prphrl_nps_extl       =    1'b0;                     //Drive chip select low to signal the start of a transaction
                @(posedge clk_pclk_nrf51822);                        //This two clock cycle delay is based on the diagrams in the NRF51822 reference manual (page 134) but may not in fact be accurate
                @(posedge clk_pclk_nrf51822);
                for (loop_i = 6'sd31; loop_i >= 6'sd0; loop_i=loop_i-6'sd1)    begin
                    loop_j    =    loop_i-6'sd9;
                    @(negedge clk_pclk_nrf51822);                    //Data changes on the falling edge. 
                    if(loop_i < 6'sd31)    begin
                        prphrl_pclk_extl    =    1'b0;               //Except for the first data transition, have the clock edge fall. We will need an extra clock FE after the final RE
                    end
                    if(loop_i >= 6'sd9 && loop_i <= 6'sd31) begin
                        prphrl_copi_extl =    tx_data[loop_j[4:0]];  //Play the tx_data vector backwards
                    end else begin
                        prphrl_copi_extl    =    1'b0;
                    end
                    @(posedge clk_pclk_nrf51822);
                    prphrl_pclk_extl    =    1'b1;
                    if(loop_i < 6'sd8) begin
                        data_return[loop_i[4:0]]    =    prphrl_cipo_extl;   //Data is captured on the rising edge
                    end
                end
                @(negedge clk_pclk_nrf51822)
                prphrl_pclk_extl    =    1'b0;                               //Have the final falling clock edge to complete the bit transfer portion of the transaction
        
                data_return_out    =    data_return;    
        
                @(posedge clk_pclk_nrf51822);                                //This two clock cycle delay is based on the diagrams in the NRF51822 reference manual (page 134) but may not in fact be accurate
                @(posedge clk_pclk_nrf51822);
                prphrl_nps_extl       =    1'b1;                             //Drive chip select high to signal the end of a transaction
                @(posedge clk_pclk_nrf51822);                                //Give a 2 clock cycle delay before we attempt any other transactions.
                @(posedge clk_pclk_nrf51822);
                @(negedge clk_pclk_nrf51822);
                done_flag            =    1'b1;
            end        join
        end
    endtask