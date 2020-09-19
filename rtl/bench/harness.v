`include "main.v"

module harness(
    input wire CLK,
    inout wire[15:0] ad0,
    inout wire[7:0] ad1,
    input wire[15:0] din,
    output wire pio, oe, ale, we
);

    wire io1, io2, io3, io4, io5, io6, io7, io8, io9, io10, io11, io12, io13, io14, io15, io16;
    wire io17, io18, io19, io20;

    assign ad0 = { io1, io2, io3, io4, io5, io6, io7, io8, io9, io10, io11, io12, io13, io14, io15, io16 };
    assign ad1 = { io17, io18, io19, io20, 4'b0 };
    assign { io1, io2, io3, io4, io5, io6, io7, io8, io9, io10, io11, io12, io13, io14, io15, io16 } = !oe ? din : 16'bz;

    CPU u0(CLK,,, io1, io2, io3, io4, io5, io6, io7, io8, io9, io10, io11, io12, io13, io14, io15, io16,
           io17, io18, io19, io20, pio, oe, ale, we,,);
endmodule