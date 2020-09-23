module REGFILE(
    input clk,
    input reset,
    // Write
    input we,
    input [addr_width-1:0] wadr,
    input [data_width-1:0] din,
    // Read
    input [addr_width-1:0] radr1,
    output reg [data_width-1:0] dout1,

    output reg led
);
    parameter addr_width = 4;
    parameter data_width = 16;

    reg[data_width-1:0] regs[(1<<addr_width)-1:0];

    integer i;
    initial begin
        for(i = 0; i < (1<<addr_width); i++)
            regs[i] = 0;
`ifdef SIMULATION
        $dumpvars(1, regs[0], regs[1]);
`endif
    end
    
    always @(posedge clk) begin
        if(we) begin
            regs[wadr] = din;
            led <= 1;
            /*if(din == 16'h0005) begin
                led <= 1;
            end else begin
                led <= 0;
            end*/
        end else begin
            led <= 0;
        end
    end
    always @(posedge clk) begin
        dout1 <= regs[radr1];
    end
endmodule