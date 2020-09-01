module REGFILE(
    input clock,
    input reset,
    input [2:0] addr,
    input write_enable,
    input [7:0] din,
    output [7:0] dout
);
    reg[7:0] regs[7:0];
    integer i;
    always@(posedge reset) begin
        for(i = 0; i < 8; i++)
            regs[i] = 0;
        out <= regs[0];
    end
    always@(posedge clock) if(write_enable) begin
        regs[addr] <= din;
    end
    always@(negedge clock) if(!write_enable) begin
        out <= regs[addr];
    end
    reg[7:0] out;
    assign dout = out;
endmodule