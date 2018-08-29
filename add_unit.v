module add_unit#(
        parameter data_in_width = 32
)(
        input wire                              clk,
        input wire                              rst_n,
        input wire [data_in_width-1:0]          adder_a,
        input wire [data_in_width-1:0]          adder_b,
        output wire [data_in_width-1:0]          adder_out
);    
reg [data_in_width:0]sum;

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        sum <= 0;
    else
        sum <= adder_a + adder_b;
end
assign adder_out = sum[data_in_width - 1:0];

endmodule
