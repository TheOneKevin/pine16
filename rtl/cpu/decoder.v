`include "cpu/rom_jump.v"
`include "cpu/rom_uc.v"

module DECODER(
    input wire clk,

    // PQ Interface
    output  reg  rqi,
    input   wire nxi,
    input   wire[31:0] cmd,

    // XU Interface
    input   wire byx,
    output  reg  rqx = 0,
    output  wire[15:0] opout,
    output  reg [3:0] regsrc, regdst, aluop,
    output  reg [15:0] opimm
);
    wire[7:0] inb0, inb1, inb2, inb3;
    assign inb0 = cmd[31:24];
    assign inb1 = cmd[23:16];
    assign inb2 = cmd[15:8];
    assign inb3 = cmd[7:0];
    reg[31:0] instr;

    reg[1:0] fsm1 = 0;
    always @(negedge clk) case(fsm1)
        2'b00: begin
            if(nxi) begin
                rqi <= 1;
                instr <= cmd;
                case(inb0[7:4]) // (J) Read jump table
                    default: begin
                        // Mask 1111_0011 0000_0010
                        opcode <= { inb0[7:4], inb0[1:0], inb1[1:0] };
                        regsrc <= { inb0[3], inb1[7:5] };
                        regdst <= { inb0[2], inb1[4:2] };
                        aluop  <= { inb0[7:4] };
                        opimm  <= { inb2, inb3 };
                    end
                    4'b1100: begin
                        // Mask 1111_1000 0000_0011
                        opcode <= { inb0[7:3], 1'b0, inb1[1:0] };
                    end
                    4'b1101, 4'b1110, 4'b1111: begin
                        // Mask 1111_1100 1100_0000
                        opcode <= { inb0[7:2], inb1[7:6] };
                    end
                endcase
                fsm1 <= 2'b01;
            end else begin
                rqi <= 0;
            end
        end
        2'b01: begin // Read uop from rom
            uip <= jmp_address;
            fsm1 <= 2'b10;
            rqi <= 0;
        end
        2'b10: begin
            if(rqx) begin
                if(opout[4]) begin
                    fsm1 <= 2'b00;
                end else begin
                    uip <= uip + 1;
                end
            end
        end
        2'b11: begin end
    endcase

    always @(posedge clk) case(fsm1)
        default: begin
            rqx <= 0;
        end
        2'b10: begin
            if(!byx) begin
                rqx <= 1;
            end else begin
                rqx <= 0;
            end
        end
    endcase

    reg[7:0] opcode;
    reg[7:0] uip;
    wire[7:0] jmp_address; // Latched
    //wire[15:0] uop; // Latched
    ROM_JUMP rom_jump(.clk(clk), .adr_n(opcode), .dout_p(jmp_address));
    ROM_UC rom_uc(.clk(clk), .adr_n(uip), .dout_p(opout));
endmodule