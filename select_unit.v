module select_unit#(
    parameter FEATURE_WIDTH = 32, 
    parameter KERNEL_WIDTH = 2
)(
    input wire                                      clk,
    input wire                                      rst_n,
    input wire  signed [FEATURE_WIDTH-1:0]          select_in,
    input wire  signed [KERNEL_WIDTH - 1 : 0]       kernel,
    output reg  signed [FEATURE_WIDTH-1:0]          select_out
    );

always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            select_out <= 0;
        else
            begin
            if(kernel == 1)
                select_out <= select_in;
            else if(kernel == -1)
                select_out <= -select_in;
            else 
                select_out <= 0;
            end
    end
endmodule