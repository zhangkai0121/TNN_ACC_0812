`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2018 12:12:24 PM
// Design Name: 
// Module Name: weight_mem_ctr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "network_para.vh"
module weight_mem_ctr#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter KERNEL_SIZE = `KERNEL_SIZE,
    parameter KERNEL_WIDTH = `KERNEL_WIDTH    
)(
    input wire                                                                      clk,
    input wire                                                                      rst_n,
    input wire                                                                      state,
    input wire [9:0]                                                                weight_mem_init_addr,
    output wire [ Tn * Tm * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH - 1 : 0 ]      weight_wire
    );

genvar i,j,k,x,y,z;
reg     [8:0]                                                               weight_mem_addr;
wire    [KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH * Tm - 1:0]               weight_mem_dout;

reg                                                                         weight_mem_read_enable;
reg                                                                         weight_mem_read_enable_p;
reg                                                                         weight_mem_read_enable_p2;

reg     [KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH * Tm - 1 : 0 ]            weight_in_buf[Tn - 1 : 0];
reg     [8:0]                                                               weight_mem_read_cnt; 
reg                                                                         weight_wire_ready;
reg     [3:0]                                                               weight_mem_ctr_cnt;
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        weight_mem_read_enable <= 0;
    else
        if(state == 0)
            weight_mem_read_enable <= 0;
        else
            if(weight_wire_ready == 0)
                weight_mem_read_enable <= 1;
            else 
                weight_mem_read_enable <= 0;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            weight_mem_read_enable_p <= 0;
            weight_mem_read_enable_p2 <= 0;
        end
    else
        begin
            weight_mem_read_enable_p <= weight_mem_read_enable;
            weight_mem_read_enable_p2 <= weight_mem_read_enable_p;
        end

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            weight_mem_addr <= 0;
        end
    else
        begin
            if((weight_mem_read_enable_p == 0) && (weight_mem_read_enable == 1))
                begin
                    weight_mem_addr <= weight_mem_init_addr[8:0];
                end
            else if(weight_mem_read_enable == 1)
                begin
                    weight_mem_addr <= weight_mem_addr + 1;
                end
        end

always@(posedge clk or negedge rst_n)
    if(!rst_n)
         weight_mem_read_cnt <= 0;    
    else
        begin
            if(state == 0)
                weight_mem_read_cnt <= 0;
            else
                if((weight_mem_read_enable_p2 == 0) && (weight_mem_read_enable_p == 1))
                    begin
                        weight_mem_read_cnt <= 0;
                    end
                else if(weight_mem_read_enable_p2 == 1)
                    begin
                        weight_mem_read_cnt <= weight_mem_read_cnt + 1;
                    end
        end

always@(posedge clk)
    if(weight_mem_read_enable_p2 == 1)
        begin
            weight_in_buf[weight_mem_read_cnt] <= weight_mem_dout;
        end
    else
        ;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            weight_wire_ready <= 0;
        end
    else 
        begin
            if(state == 0)
                weight_wire_ready <= 0;
            else
                if(weight_mem_ctr_cnt >= 3)
                    weight_wire_ready <= 1;
                else
                    weight_wire_ready <= 0;
        end

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        weight_mem_ctr_cnt <= 0;
    else
        if(weight_mem_read_enable == 1)
            weight_mem_ctr_cnt <= weight_mem_ctr_cnt + 1;
        else
            if(state == 0)
                weight_mem_ctr_cnt <= 0;
            else
                weight_mem_ctr_cnt <= weight_mem_ctr_cnt;


weight_ram_gen weight_ram (
  .clka(clk),    // input wire clka
  .ena(0),      // input wire ena
  .wea(1),      // input wire [0 : 0] wea
  .addra(0),  // input wire [9 : 0] addra
  .dina(0),    // input wire [49 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(weight_mem_read_enable_p),      // input wire enb
  .addrb(weight_mem_addr[6:0]),  // input wire [6 : 0] addrb
  .doutb(weight_mem_dout)  // output wire [399 : 0] doutb
);


generate
    for(i = 0 ; i < 4 ; i = i + 1) begin:weight_wire_i
        for(j = 0 ; j < 8 ; j = j + 1) begin:weight_wire_j
            for(k = 0 ; k < KERNEL_SIZE * KERNEL_SIZE ; k = k + 1) begin:weight_wire_k
                assign weight_wire[i * 8 * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + k * KERNEL_WIDTH + KERNEL_WIDTH - 1 :
                                   i * 8 * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + k * KERNEL_WIDTH ]
                       = weight_in_buf[i][j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + ( 24 - k ) * KERNEL_WIDTH + KERNEL_WIDTH - 1:
                                          j * KERNEL_SIZE * KERNEL_SIZE * KERNEL_WIDTH + ( 24 - k ) * KERNEL_WIDTH];
                     //  = weight_in_buf[i*Tn+j][( 24 - k ) * KERNEL_WIDTH + KERNEL_WIDTH - 1:( 24 - k ) * KERNEL_WIDTH];
            end
        end
    end
endgenerate
        
endmodule