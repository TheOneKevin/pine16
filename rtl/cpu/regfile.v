module REGFILE(
    input clk,
    input reset,
    // Write
    input we_p,
    input [addr_width-1:0] wadr_n,
    input [data_width-1:0] din,
    // Read
    input [addr_width-1:0] radr_p,
    output reg [data_width-1:0] dout
);
    parameter addr_width = 4;
    parameter data_width = 16;

    reg[data_width-1:0] regs[(1<<addr_width)-1:0];

    integer i;
    initial begin
        for(i = 0; i < (1<<addr_width); i++)
            regs[i] = 0;
        regs[0] = 1;
        $dumpvars(1, regs[0], regs[1]);
    end
    
    always @(posedge clk) begin
        if(we_p)
            regs[wadr_n] = din;
    end
    always @(negedge clk) begin
        dout = regs[radr_p];
    end
endmodule