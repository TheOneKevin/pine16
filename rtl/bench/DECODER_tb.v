`include "cpu/DECODER.v"
`timescale 1ns / 1ns
`define CASE1

module DECODER_tb();
    parameter PERIOD = 2;
    parameter PERIOD3 = PERIOD * 3;
    reg clk = 0;
    always #(PERIOD/2) clk=~clk;
    initial begin
        $dumpfile("DECODER.vcd");
        $dumpvars(0, decoder);
    end

    wire  req;
    reg ack;
    reg [15:0] dtr;
    wire [19:0] adr;
    reg reqi;
    wire acki;
    wire[31:0] instr;
    reg sigflush;
    reg[20:0] fadr;

`ifdef CASE1
    initial begin
        ack = 0; dtr = 0; reqi = 0; sigflush = 1; fadr = 21'hA2C1;
        
        #PERIOD
        sigflush = 0;
        ack = 1;
        dtr = 16'b0000_0000_0000_0000;
        
        #(7*PERIOD/2)
        ack = 0;
        
        #(5*PERIOD/2)
        ack = 1;
        
        #(PERIOD/2)
        
        #(PERIOD*8)
        reqi = 1;
        
        #(PERIOD/2)
        ack = 0;
        #(PERIOD/2)

        #(PERIOD*4)
        reqi = 0;

        #(PERIOD/2)
        ack = 1;
        #(PERIOD/2)
        
        #(PERIOD*4)
        
        #(PERIOD/2)
        ack = 0;
        #(PERIOD/2)

        reqi = 1;
        #(PERIOD*16)

        $finish;
    end
`endif

    DECODER decoder(
        .clk(clk),
        .req(req), .ack(ack), .dtr(dtr), .adr(adr),
        .reqi(reqi), .acki(acki), .instr(instr),
        .sigflush(sigflush), .fadr(fadr)
    );
endmodule