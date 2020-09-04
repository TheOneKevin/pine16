`include "cpu/rom_uc.v"
`include "cpu/alu.v"
`include "cpu/regfile.v"

module EXU(
    input wire clk,

    // Flush
    output  reg sigflush_n,
    output  wire[20:0] fladr_n,

    // MEM Interface
    output  reg  req_n,
    input   wire ack_n,
    input   wire[15:0] dtr_n,
    output  reg [19:0] adr_n
);
    reg active = 0;
    reg[31:0] instr;

    reg[7:0] uip = 0;
    reg[15:0] uop;
    always @(negedge clk) begin
        uop <= rom_dout_p;
        /*if(!uop[15])
            fsm1 <= 0;*/
    end

    wire [15:0] rbus;
    reg[15:0] mar, mdr, imm;
    reg[3:0] rs, rd;
    wire[3:0] wadr, radr;
    assign wadr = uop[6:5] == 2'b11 ? rd : rs;
    assign radr = uop[13:12] == 2'b11 ? rd : rs;
    

    wire[15:0] rom_dout_p;
    ROM_UC rom(.clk(clk), .adr_n(uip), .dout_p(rom_dout_p));

    ALU alu0(
        .clk(clk)
    );

    REGFILE regs(
        .clk(clk)
    );
endmodule