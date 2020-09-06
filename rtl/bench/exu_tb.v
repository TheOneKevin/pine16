`include "cpu/exu.v"
`timescale 1ns / 1ns

module EXU_tb();
    parameter PERIOD = 2;
    parameter PERIOD3 = PERIOD * 3;
    
    reg clk = 0;

    // Instruction Queue

    always #(PERIOD/2) clk=~clk;

    initial begin
        $dumpfile("IO.vcd");
        $dumpvars(0, exu);
        #PERIOD3
        #PERIOD3
        #PERIOD3
        $finish;
    end

    EXU exu(
        .clk(clk)
    );
endmodule