`include "cpu/io.v"
`timescale 1ns / 1ns

module IO_SYNC_tb();
    parameter PERIOD = 2;
    parameter PERIOD3 = PERIOD * 3;
    
    reg clk = 0;

    // Instruction Queue
    reg  req0 = 0;
    wire ack0;
    reg  rw0 = 1;
    reg [15:0] dtw0 = 1;
    wire[15:0] dtr0;
    reg [19:0] adr0 = 2;
    
    // Execution Engine
    reg  req1 = 0;
    wire ack1;
    reg  rw1 = 1;
    reg [15:0] dtw1 = 3;
    wire[15:0] dtr1;
    reg [19:0] adr1 = 4;

    always #(PERIOD/2) clk=~clk;

    initial begin
        $dumpfile("IO.vcd");
        $dumpvars(0, io);

        req0 = 1;
        req1 = 1;
        #PERIOD3

        req0 = 0;
        req1 = 1;
        #PERIOD3

        req0 = 1;
        req1 = 0;
        #PERIOD3

        req0 = 1;
        req1 = 1;
        rw0 = 0;
        #PERIOD3

        req0 = 1;
        req1 = 0;
        #PERIOD3

        req0 = 0;
        req1 = 0;
        #PERIOD
        $finish;
    end

    IO_SYNC io(
        .clk(clk),
        .req0(req0), .rw0(rw0), .dtw0(dtw0), .dtr0(dtr0), .adr0(adr0),
        .req1(req1), .rw1(rw1), .dtw1(dtw1), .dtr1(dtr1), .adr1(adr1)
    );
endmodule