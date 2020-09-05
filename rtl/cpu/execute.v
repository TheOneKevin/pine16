`include "cpu/alu.v"
`include "cpu/regfile.v"

module EXECUTE(
    input wire clk,

    // Decoder Interface
    input   wire rqx_p,
    output  reg  akx_n = 0,
    input   wire[15:0] opout_p,
    input   wire[3:0] regsrc, regdst, aluop,
    input   wire[15:0] opimm,

    // Flush
    /*output  reg sigflush_n,
    output  wire[20:0] fladr_n,*/

    // MEM Interface
    output  reg  rqm_n = 0,
    output  reg  rwm_n = 0,
    input   wire akm_n,
    input   wire[15:0] drm_n,
    output  wire[15:0] dwm_n,
    output  wire[19:0] adm_n
);
    reg active = 0;
    reg[15:0] uop;
    reg[3:0] fsm1 = 0;

    always @(negedge clk) begin
        if(!akx_n) begin
            active = 0;
        end
        if(rqx_p && !active) begin
            active = 1;
            akx_n = 1;
            rs <= regsrc;
            rd <= regdst;
            imm <= opimm;
            aop <= opout_p[11] ? opout_p[10:7] : aluop;
            uop <= opout_p;
        end
        if(active) if(uop[15]) case(fsm1)
            4'b0000: begin
                fsm1 <= 4'b0001;
            end
            4'b0001: begin
                fsm1 <= 4'b0000;
                akx_n <= 0;
                if(uop[14]) case(uop[6:5])
                    2'b00: mar <= wbus;
                    2'b01: mdr <= wbus;
                endcase
            end
        endcase
    end

    always @(posedge clk) if(active) if(uop[15]) case(fsm1)
        4'b0001: begin
            
        end
    endcase

    wire [15:0] rbus, wbus, rout;
    reg[15:0] mar = 0, mdr = 0, imm;
    reg[3:0] rs, rd, aop;
    wire[3:0] wadr, radr;
    
    assign wadr = uop[6:5] == 2'b11 ? rd : rs;
    assign radr = uop[13:12] == 2'b11 ? rd : rs;
    assign rbus = uop[13:12] == 2'b00 ? imm :
                  uop[13:12] == 2'b01 ? mdr : rout;
    assign dwm_n = mdr;
    assign adm_n = mar;
    ALU alu0(.clk(clk), .a(rbus), .r(wbus), .op(aop));
    REGFILE regs(
        .clk(clk), .we_p(uop[14] & uop[15] & active),
        .wadr_n(wadr), .din(wbus),
        .radr_p(radr), .dout(rout)
    );
endmodule