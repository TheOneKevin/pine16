module REGFILE(
    input clk,
    input reset,
    // Write
    input we_p,
    input [addr_width-1:0] wadr_p,
    input [data_width-1:0] din,
    // Read
    input [addr_width-1:0] radr_n,
    output reg [data_width-1:0] dout
);
    parameter addr_width = 4;
    parameter data_width = 16;

    reg[data_width-1:0] regs[(1<<addr_width)-1:0];

    integer i;
    initial begin
        for(i = 0; i < (1<<addr_width); i++)
            regs[i] = 0;
    end
    
    always @(negedge clk) begin
        if(we_p)
            regs[wadr_p] = din;
    end
    always @(posedge clk) begin
        dout = regs[radr_n];
    end
endmodule