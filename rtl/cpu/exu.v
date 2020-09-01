module XU(
    input wire clk,

    // IQ Interface
    output  reg reqi,
    input   wire acki,
    input   wire[31:0] instr,
    output  reg sigflush,
    output  wire[20:0] fadr,

    // MEM Interface
    output  reg  req = 0,
    input   wire ack,
    input   wire[15:0] dtr,
    output  reg [19:0] adr
);
    
endmodule