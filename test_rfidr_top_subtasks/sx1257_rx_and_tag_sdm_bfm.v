/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// Subtask : SX1257 RX and TAG SDM sub BFM                                             //
//                                                                                     //
// Filename: sx1257_rx_and_tag_sdm_bfm.v                                               //
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
//                                                                                     //
//                                                                                     //
// Because this file is derivative of code in Schreier's delta sigma toolbox, we       //
// reproduce the relevant copyright notice herein.                                     //
//                                                                                     //
// Copyright (c) 2020, Richard Schreier                                                //
// All rights reserved.                                                                //
//                                                                                     //
// Redistribution and use in source and binary forms, with or without                  //
// modification, are permitted provided that the following conditions are met:         //
//                                                                                     //
//* Redistributions of source code must retain the above copyright notice, this        //
//  list of conditions and the following disclaimer.                                   //
//                                                                                     //
//* Redistributions in binary form must reproduce the above copyright notice,          //
//  this list of conditions and the following disclaimer in the documentation          //
//  and/or other materials provided with the distribution                              //
//* Neither the name of none nor the names of its                                      //
//  contributors may be used to endorse or promote products derived from this          //
//  software without specific prior written permission.                                //
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"        //
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE          //
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE     //
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE        //
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL         //
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR         //
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER         //
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,      //
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE      //
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               //
//                                                                                     //
//                                                                                     //
//  Description:                                                                       //
//    This file recreates the SDM used in the Schreier Delta-Sigma Matlab toolbox that //
//    we used to approximate what we think was in the SX1257. The                      //
//    same terminology used internal to the Schreier toolbox was used                  //
//    as much as possible to minimize confusion during examination.                    //
//                                                                                     //
//    In this hierarchy and others we want to use ports declared as                    //
//    reals, but this is not supported by Verilog.    The work around                  //
//    is here: http://www.deepchip.com/items/0466-04.html in Section                   //
//    4.7.                                                                             //
//                                                                                     //
//    091016 - File created                                                            //
//    090521 - Replaced tabs with 4-spaces. Added copyright to header.                 //
//    This file is out of date and was not re-run after cleanup for release, so        //
//    please temper expectations for use accordingly.                                  //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////

module    sx1257_rx_and_tag_sdm_bfm
    (
        input    wire    [63:0]    u_i_bits,
        input    wire    [63:0]    u_q_bits,
        input    wire              sx1257_clk,
        output   reg               sx1257_out_i,
        output   reg               sx1257_out_q
    );
    
    //Define the state-space model of the sigma-delta modulator that we employed in Matlab
    real    ssm_A       [0:4][0:4];
    real    ssm_B       [0:4][0:1];
    real    x0_i        [0:4];
    real    x0_q        [0:4];
    real    x0_i_new    [0:4];
    real    x0_q_new    [0:4];
    real    u_i, u_q, v_i, v_q, y_i, y_q;
    
    integer    loop_a, loop_b;

    always @(*)    begin
        u_i    =    $bitstoreal(u_i_bits);
        u_q    =    $bitstoreal(u_q_bits);
    end
    
    initial    begin
        //Fill out the matrix entries of the sigma-delta modulator state-space model
        //Matrix format will be like Matlab: mat[row][column]

        for(loop_a=0;loop_a<5;loop_a=loop_a+1)    begin
            for(loop_b=0;loop_b<5;loop_b=loop_b+1)    begin
                ssm_A[loop_a][loop_b]    =    0.0000000000000;
            end
        end
        
        
        for(loop_a=0;loop_a<5;loop_a=loop_a+1)    begin
            x0_i[loop_a]        =    0.0000000000000;
            x0_q[loop_a]        =    0.0000000000000;
            x0_i_new[loop_a]    =    0.0000000000000;
            x0_q_new[loop_a]    =    0.0000000000000;
        end
        
        //Using high-precision numbers really helped out with the quality of the simulation.
        
        ssm_A[0][0]    =     4.989296663285129;
        ssm_A[1][0]    =    -0.099999999999999;
        ssm_A[2][0]    =    0.498929666328513;
        ssm_A[3][0]    =    0.996791208834985;
        ssm_A[4][0]    =    -0.996791208834985;
        ssm_A[0][4]    =    10;
        ssm_A[1][4]    =    0.000000000000002;
        ssm_A[2][1]    =    1;
        ssm_A[3][2]    =    -1;
        ssm_A[4][3]    =    1;
        
        ssm_B[0][0]    =    0.8022736985510867;
        ssm_B[1][0]    =    -0.0557929668604005;
        ssm_B[2][0]    =    0.2419551978907811;
        ssm_B[3][0]    =    0.3959203996677355;
        ssm_B[4][0]    =    -0.2899179825118727;
        ssm_B[0][1]    =    -ssm_B[0][0];
        ssm_B[1][1]    =    -ssm_B[1][0];
        ssm_B[2][1]    =    -ssm_B[2][0];
        ssm_B[3][1]    =    -ssm_B[3][0];
        ssm_B[4][1]    =    -ssm_B[4][0];
    end
    
    always @(posedge sx1257_clk)    begin    //Yes, it is posedge, I checked the data sheet
    
        //Follow the same state-space operations as in the Schreier Delta-Sigma toolbox.
    
        y_i             =    x0_i[0]    +    u_i;
        y_q             =    x0_q[0]    +    u_q;
        
        sx1257_out_i    =    y_i        >     0.0;
        sx1257_out_q    =    y_q        >     0.0;
        
        v_i             =    y_i        >     0.0 ? 1.0000000000000 : -1.00000000000000;
        v_q             =    y_q        >     0.0 ? 1.0000000000000 : -1.00000000000000;
        
        for(loop_a=0;loop_a<5;loop_a=loop_a+1)    begin
            x0_i_new[loop_a]    =    0.0;
            x0_q_new[loop_a]    =    0.0;
        end
        
        for(loop_a=0;loop_a<5;loop_a=loop_a+1)    begin        //Loop through rows
            for(loop_b=0;loop_b<5;loop_b=loop_b+1)    begin    //Loop through columns
                x0_i_new[loop_a]    =    x0_i_new[loop_a]    +    x0_i[loop_b]*ssm_A[loop_a][loop_b];
                x0_q_new[loop_a]    =    x0_q_new[loop_a]    +    x0_q[loop_b]*ssm_A[loop_a][loop_b];
            end

            x0_i_new[loop_a]    =    x0_i_new[loop_a]    +    u_i*ssm_B[loop_a][0];    
            x0_q_new[loop_a]    =    x0_q_new[loop_a]    +    u_q*ssm_B[loop_a][0];
            
            x0_i_new[loop_a]    =    x0_i_new[loop_a]    +    v_i*ssm_B[loop_a][1];    
            x0_q_new[loop_a]    =    x0_q_new[loop_a]    +    v_q*ssm_B[loop_a][1];
            
        end
        
        for(loop_a=0;loop_a<5;loop_a=loop_a+1)    begin
            x0_i[loop_a]    =    x0_i_new[loop_a];
            x0_q[loop_a]    =    x0_q_new[loop_a];
        end
    end
endmodule
        
    