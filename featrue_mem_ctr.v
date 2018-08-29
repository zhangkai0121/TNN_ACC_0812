`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/02/2018 02:27:25 PM
// Design Name: 
// Module Name: featrue_mem_ctr
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

module featrue_mem_ctr#(
    parameter Tn = `Tn,
    parameter Tm = `Tm,
    parameter FEATURW_SIZE = `FEATURE_SIZE,
    parameter FEATURE_WIDTH = `FEATURE_WIDTH,
    parameter KERNEL_SIZE = `KERNEL_SIZE
)(
    input wire                                                                    clk,
    input wire                                                                    rst_n,
    input wire   [2:0]                                                            current_kernel_size,
    input wire                                                                    state,
    input wire   [9:0]                                                            feature_amount,
    input wire   [14:0]                                                           featrue_mem_init_addr,
    input wire   [9:0]                                                            output_data_addr_init,
    input wire                                                                    CLP_output_flag,
    input wire   [ Tm * FEATURE_WIDTH - 1 : 0 ]                                   CLP_output,
    output wire  [ Tn * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH - 1 : 0 ]       feature_wire
    );
    
genvar i,j,k,x,y,z;

reg                                             feature_mem_write_enable;
reg                                             feature_mem_write_enable_p;
reg     [9:0]                                   feature_mem_write_addr;
reg     [9:0]                                   feature_mem_write_addr_n;
reg     [Tm * FEATURE_WIDTH - 1:0]              feature_mem_write_data;

reg                                             feature_mem_read_enable;
reg                                             feature_mem_read_enable_p;
reg                                             feature_read_ready;
reg     [10:0]                                  feature_mem_read_cnt;
reg     [5:0]                                   feature_mem_read_cnt2;

reg     [7:0]                                   feature_mem_read_addr;
wire    [Tn * FEATURE_WIDTH * 8 - 1 :0]         feature_mem_read_data;
reg     [Tn * FEATURE_WIDTH * 8 - 1 :0]         feature_mem_read_data_tmp;

reg                                             line_buffer_enable;


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_enable <= 0;
    else 
        if(state == 0)
            feature_mem_read_enable <= 0;
        else
            if(feature_read_ready == 1)
                feature_mem_read_enable <= 0;
            else    
                feature_mem_read_enable <= 1;
            
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_enable_p <= 0;
    else
        feature_mem_read_enable_p <= feature_mem_read_enable;     
 
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            feature_mem_read_addr <= 0;
            feature_mem_read_cnt2 <= 0;
        end          
    else
        if(state == 0)
            feature_mem_read_cnt2 <= 0;
        else
            if((feature_mem_read_enable_p == 0)&&(feature_mem_read_enable == 1))
                feature_mem_read_addr <= featrue_mem_init_addr;
            else if(feature_mem_read_enable_p == 1)
                begin
                    if(current_kernel_size != 1)
                        if(feature_mem_read_addr <= (featrue_mem_init_addr + FEATURW_SIZE-2))
                            feature_mem_read_addr <= feature_mem_read_addr + 1;
                        else
                            begin
                                if(feature_mem_read_cnt2 == 0)
                                    begin
                                        feature_mem_read_addr <= feature_mem_read_addr + 1;
                                        feature_mem_read_cnt2 <= 1;
                                    end  
                                else if(feature_mem_read_cnt2 == 7)
                                    begin
                                        feature_mem_read_addr <= feature_mem_read_addr + 1;
                                        feature_mem_read_cnt2 <= 8;
                                    end
                                else if(feature_mem_read_cnt2 == 8)
                                    feature_mem_read_cnt2 <= 1;    
                                else
                                    begin
                                        feature_mem_read_cnt2 <= feature_mem_read_cnt2 + 1;
                                    end
                            end
                    else   //kernel_size = 1 
                        begin
                            if(feature_mem_read_cnt2 == 7)
                                begin
                                    feature_mem_read_cnt2 <= 0;   
                                end
                            else if(feature_mem_read_cnt2 == 6)
                                begin
                                    feature_mem_read_addr <= feature_mem_read_addr + 1;
                                    feature_mem_read_cnt2 <= feature_mem_read_cnt2 + 1;  
                                end    
                            else
                                feature_mem_read_cnt2 <= feature_mem_read_cnt2 + 1; 
                        end                       
                end
 
 
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_data_tmp <= 0;
    else 
        if ((current_kernel_size != 1) && (feature_mem_read_cnt2 == 2))
            feature_mem_read_data_tmp <= feature_mem_read_data >> (FEATURE_WIDTH*4);
        else if ((current_kernel_size == 1) && (feature_mem_read_cnt2 == 0))
            feature_mem_read_data_tmp <= feature_mem_read_data >> (FEATURE_WIDTH*4);
        else
            feature_mem_read_data_tmp <= feature_mem_read_data_tmp >> (FEATURE_WIDTH*4);
 
            
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_read_cnt <= 0;
    else
        if(state == 0)
            feature_mem_read_cnt <= 0;
        else         
            if(feature_mem_read_enable_p == 1)
                feature_mem_read_cnt <= feature_mem_read_cnt + 1;
            else
                feature_mem_read_cnt <= feature_mem_read_cnt;            
        
always@(posedge clk or negedge rst_n)
    if(!rst_n) 
        feature_read_ready <= 0;
    else 
        if(feature_mem_read_cnt >= feature_amount-2)
            feature_read_ready <= 1;
        else
            feature_read_ready <= 0;           

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        line_buffer_enable <= 0;
    else
        if(state == 0)
            line_buffer_enable <= 0;
        else
            if((feature_mem_read_enable_p == 0)&&(feature_mem_read_enable == 1))
                line_buffer_enable <= 1;
            else
                line_buffer_enable <= line_buffer_enable;
 
 featrure_memory_gen feature_memory (
              .clka(clk),    // input wire clka
              .ena(feature_mem_write_enable),      // input wire ena
              .wea(1),      // input wire [0 : 0] wea
              .addra(feature_mem_write_addr),  // input wire [9 : 0] addra
              .dina(feature_mem_write_data),    // input wire [191 : 0] dina
              .clkb(clk),    // input wire clkb
              .enb(feature_mem_read_enable),      // input wire enb
              .addrb(feature_mem_read_addr),  // input wire [7 : 0] addrb
              .doutb(feature_mem_read_data)  // output wire [767 : 0] doutb
            );
 
 
reg  [ FEATURE_WIDTH - 1 : 0 ]                                          feature_in_buf[Tn * KERNEL_SIZE * KERNEL_SIZE - 1 : 0];
wire [ Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 : 0 ]                       feature_transfer_wire;
wire [ Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 : 0 ]                       line_buffer_in;   
wire [ Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 : 0 ]                       line_buffer_out;   
reg                                                                     read_mem_mode;
wire [ Tn * FEATURE_WIDTH * KERNEL_SIZE * KERNEL_SIZE - 1 : 0 ]         feature_transfer_wire_for_1X1;

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        read_mem_mode <= 1'd0;
    else
        if(feature_mem_read_addr < (featrue_mem_init_addr + FEATURW_SIZE))
            read_mem_mode <= 1'd0;
        else
            read_mem_mode <= 1'd1;


 
assign feature_transfer_wire = (read_mem_mode == 0) ? feature_mem_read_data[ Tn * FEATURE_WIDTH * KERNEL_SIZE - 1 : 0 ]: line_buffer_out;
assign line_buffer_in = (read_mem_mode == 0) ? feature_transfer_wire : ((feature_mem_read_cnt2 == 2) ?  
                {{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data[FEATURE_WIDTH*4-1:FEATURE_WIDTH*3],{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data[FEATURE_WIDTH*3-1:FEATURE_WIDTH*2],{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data[FEATURE_WIDTH*2-1:FEATURE_WIDTH],{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data[FEATURE_WIDTH-1:0]} :
                {{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data_tmp[FEATURE_WIDTH*4-1:FEATURE_WIDTH*3],{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data_tmp[FEATURE_WIDTH*3-1:FEATURE_WIDTH*2],{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data_tmp[FEATURE_WIDTH*2-1:FEATURE_WIDTH],{FEATURE_WIDTH*4{1'd0}},feature_mem_read_data_tmp[FEATURE_WIDTH-1:0]});
           
generate
for(i = 0 ; i < Tn; i = i+1) begin:line_buffer_i
    line_buffer line_buffer0(
                    .clk(clk),
                    .enable(line_buffer_enable),
                    .line_buffer_mod(read_mem_mode),   
                    .current_kernel_size(current_kernel_size),
                    .data_in(line_buffer_in[(i+1) * KERNEL_SIZE * FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH]),
                    .data_out(line_buffer_out[(i+1) * FEATURE_WIDTH * KERNEL_SIZE - 1 : i * FEATURE_WIDTH * KERNEL_SIZE])
                    );
end


endgenerate
generate
for(i = 0 ; i < Tn; i = i + 1) begin:feature_in_buf_i
    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_in_buf_j
        always@(posedge clk or negedge rst_n)
            if(!rst_n)
                begin
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE ]       <= 0;    
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 1]    <= 0;   
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 2]    <= 0;  
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 3]    <= 0; 
//                    feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 4]    <= 0;
                end
            else
                begin
                    if(current_kernel_size == 5)
                        begin
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE ]       <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 1];    
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 1]    <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 2];
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 2]    <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 3];
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 3]    <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 4];  
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 4]    <= feature_transfer_wire[i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH];
                        end
                    else if(current_kernel_size == 3)
                        begin
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE ]       <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 1];    
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 1]    <= feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 2];
                            feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 2]    <= feature_transfer_wire[i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * KERNEL_SIZE * FEATURE_WIDTH + j * FEATURE_WIDTH];
                           // feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 3]    <= 0; 
                           // feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE  + j * KERNEL_SIZE + 4]    <= 0;
                        end
                end
    end
end
endgenerate


generate
    for(i = 0;i < Tn; i = i + 1)  begin:feature_transfer_wire_for_1X1_i
        for(j = 1 ; j < KERNEL_SIZE;j = j + 1) begin:feature_transfer_wire_for_1X1_j
            for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_transfer_wire_for_1X1_k
                assign feature_transfer_wire_for_1X1[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
                                                     i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH ] = {FEATURE_WIDTH{1'd0}};
            end
        end
        for(x = 1; x < KERNEL_SIZE; x = x + 1) begin:feature_transfer_wire_for_1X1_x
            assign feature_transfer_wire_for_1X1[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + x * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
                                                 i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + x * FEATURE_WIDTH ] =  {FEATURE_WIDTH{1'd0}};
        end
        assign feature_transfer_wire_for_1X1[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + FEATURE_WIDTH - 1 :  i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH ] 
           = (feature_mem_read_cnt2 == 0) ? feature_mem_read_data[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH]:feature_mem_read_data_tmp[i * FEATURE_WIDTH + FEATURE_WIDTH - 1 : i * FEATURE_WIDTH];       
    end
endgenerate




generate
for(i = 0 ; i <Tn ; i = i + 1) begin:feature_wire_i
    for(j = 0 ; j < KERNEL_SIZE; j = j + 1) begin:feature_wire_j
        for(k = 0 ; k < KERNEL_SIZE; k = k + 1) begin:feature_wire_k
            assign feature_wire[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
                                i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
                    = (current_kernel_size == 1) ? feature_transfer_wire_for_1X1[i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH + FEATURE_WIDTH - 1 : 
                                                                                 i * KERNEL_SIZE * KERNEL_SIZE * FEATURE_WIDTH + j * KERNEL_SIZE * FEATURE_WIDTH + k * FEATURE_WIDTH]
                                                  :feature_in_buf[i * KERNEL_SIZE * KERNEL_SIZE + j * KERNEL_SIZE + k];
        end
    end
end
endgenerate


always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_write_enable <= 0;
    else 
        if(state == 0)
            feature_mem_write_enable <= 0;
        else
            feature_mem_write_enable <= 0;
 
always@(posedge clk or negedge rst_n)
    if(!rst_n)
        feature_mem_write_enable_p <= 0;
    else
        feature_mem_write_enable_p <= feature_mem_write_enable;             

always@(posedge clk or negedge rst_n)
    if(!rst_n)
        begin
            feature_mem_write_addr_n <= 0;
            feature_mem_write_addr <= 0;
            feature_mem_write_data <= 0;
        end
    else 
        if(state == 0)
            begin
                feature_mem_write_addr_n <= 0;
                feature_mem_write_addr <= 0;
            end
        else    
            if((feature_mem_write_enable_p == 0) && (feature_mem_write_enable == 1))
                feature_mem_write_addr_n <= output_data_addr_init;
            else
                if(CLP_output_flag == 1)
                    begin
                        feature_mem_write_addr_n <= feature_mem_write_addr_n + 1;
                        feature_mem_write_data <= CLP_output;
                        feature_mem_write_addr<=feature_mem_write_addr_n;
                    end
                else
                    ;        
endmodule