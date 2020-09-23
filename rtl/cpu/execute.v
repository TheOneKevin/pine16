`include "cpu/alu.v"
`include "cpu/regfile.v"

/* verilator lint_off PINMISSING */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off WIDTH */

module EXECUTE(
    input wire clk,

    // Decoder Interface
    input   wire rqx,
    output  reg  byx = 0,
    input   wire[15:0] opout,
    input   wire[3:0] regsrc, regdst, aluop,
    input   wire[15:0] opimm,

    // Flush
    /*output  reg sigflush_n,
    output  wire[20:0] fladr_n,*/

    // MEM Interface
    output  reg  rqm_n = 0,
    output  reg  rwm_n,
    input   wire akm_n,
    input   wire[15:0] drm_n,
    output  wire[15:0] dwm_n,
    output  wire[19:0] adm_n,
    
    output wire led
);
    reg[15:0] uop;
    reg[1:0] fsm1 = 0;
    //assign led = byx;

    always @(negedge clk) case(fsm1)
        2'b00: if(rqx) begin
            byx <= 1;
            fsm1 <= 2'b01;
            // Latch inputs
            rs <= regsrc;
            rd <= regdst;
            imm <= opimm;
            aop <= opout[11] ? opout[10:7] : aluop;
            uop <= opout;
            we <= 0;
            if(uop[15]) begin
            end else case(uop[14:12])
                default: begin end
            endcase
        end else begin
            we <= 0;
        end
        2'b01: begin
            if(uop[15]) begin
                fsm1 <= 2'b00;
                byx <= 0;
                we <= uop[14];
                if(uop[14]) case(uop[6:5])
                    2'b00: mar <= wbus;
                    2'b01: mdr <= wbus;
                endcase
            end else case(uop[14:12])
                default: begin end
            endcase
        end
    endcase

    /*always @(negedge clk) begin
        if(rqx && !active) begin
            active <= 1;
            // Latch inputs
            rs <= regsrc;
            rd <= regdst;
            imm <= opimm;
            aop <= opout[11] ? opout[10:7] : aluop;
            uop <= opout;
            we <= 0;
        end
        if(rqx || active) if(uop[15]) case(fsm1)
            2'b00: begin
                byx <= 1;
                fsm1 <= 2'b01; // Allow read to happen
            end
            2'b01: begin // Set up for write
                fsm1 <= 0;
                byx <= 0;
                active <= 0;
                we <= uop[14];
                if(uop[14]) case(uop[6:5])
                    2'b00: mar <= wbus;
                    2'b01: mdr <= wbus;
                endcase
            end
        endcase else case(uop[14:12])
            3'b000: begin
                //byx <= 0;
                //active <= 0;
            end
            3'b001: case(fsm1)
                2'b00: begin
                    if(akm_n) begin
                        rqm_n <= 0;
                        fsm1 <= 0;
                    end else begin
                        rqm_n <= 1;
                        rwm_n <= uop[11];
                    end
                end
                2'b01: begin
                    
                end
            endcase
        endcase
    end*/

    reg we = 0;
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
        .clk(clk), .we(we),
        .wadr(wadr), .din(wbus),
        .radr1(radr), .dout1(rout), .led(led)
    );
endmodule

/* verilator lint_on PINMISSING */
/* verilator lint_on CASEINCOMPLETE */
/* verilator lint_on WIDTH */
