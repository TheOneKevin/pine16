`include "cpu/rom_jump.v"
`include "cpu/rom_uc.v"

module DECODER(
    input wire clk,

    // PQ Interface
    output  wire rqi_p,
    input   wire aki_n,
    input   wire[31:0] cmd_n
);

    wire[7:0] inb0, inb1, inb2, inb3;
    assign inb0 = cmd_n[31:24];
    assign inb1 = cmd_n[23:16];
    assign inb2 = cmd_n[15:8];
    assign inb3 = cmd_n[7:0];

    reg eol = 0;
    reg[31:0] instr;
    assign rqi_p = !eol;

    reg[3:0] fsm1 = 0;
    always @(posedge clk) case(fsm1)
        4'b0000: begin // Send reqi signal
            fsm1 <= 4'b0001;
        end
        4'b0001: if(aki_n) begin
            eol <= 1;
            instr <= cmd_n;
            case(inb0[7:4]) // (J) Get jump table
                default: begin
                    // Mask 1111_0011 0000_0010
                    opcode <= { inb0[7:4], inb0[1:0], inb1[1:0] };
                end
                4'b1100: begin
                end
                4'b1101, 4'b1110, 4'b1111: begin
                    // Mask 1111_1100, 1100_0000
                    opcode <= { inb0[7:2], inb1[7:6] };
                end
            endcase
            fsm1 <= 4'b0010;
        end
        4'b0010: begin
            uop_address <= jmp_address;
            fsm1 <= 4'b0011;
        end
        4'b0011: begin
            if(uop[4]) begin
                eol <= 0;
                fsm1 <= 4'b0001;
            end else begin
                
            end
        end
    endcase
    
    reg[7:0] opcode;
    reg[7:0] uop_address;
    wire[7:0] jmp_address; // Latched
    wire[15:0] uop; // Latched
    ROM_JUMP rom_jump(.clk(clk), .adr_p(opcode), .dout_n(jmp_address));
    ROM_UC rom_uc(.clk(clk), .adr_p(uop_address), .dout_n(uop));
endmodule