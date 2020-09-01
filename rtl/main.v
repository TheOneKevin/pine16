`include "cpu/io.v"
`include "cpu/prefetch.v"
`include "uart/uart.v"

`define IO_PINS { \
    PIN_1, PIN_2,  PIN_3,  PIN_4,  PIN_5,  PIN_6,  PIN_7,  PIN_8, \
    PIN_9, PIN_10, PIN_11, PIN_12, PIN_13, PIN_14, PIN_15, PIN_16 }

module CPU (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    output USBPU, // USB pull-up resistor
    // IO Pins
    inout PIN_1,  inout PIN_2,  inout PIN_3,  inout PIN_4,
    inout PIN_5,  inout PIN_6,  inout PIN_7,  inout PIN_8,
    inout PIN_9,  inout PIN_10, inout PIN_11, inout PIN_12,
    inout PIN_13, inout PIN_14, inout PIN_15, inout PIN_16,
    // Output pins
    output PIN_17, output PIN_18, output PIN_19, output PIN_20,
    output PIN_21, output PIN_22, output PIN_23, output PIN_24,
    // UART
    input PIN_25, output PIN_26
);
    // Disable the USB
    assign USBPU = 0;
    
    // Memory module wiring
    wire isout, ale_neg, oe, oe_neg, we, pio;
    wire [3:0] adr_hi;
    wire [15:0] dout;
    wire [15:0] din;

    // Physical pin assignments
    assign `IO_PINS = isout ? dout : 16'bz;
    assign din = `IO_PINS;
    assign { PIN_17, PIN_18, PIN_19, PIN_20 } = adr_hi;
    assign PIN_21 = pio;
    assign PIN_22 = !oe & !oe_neg;
    assign PIN_23 = ale_neg;
    assign PIN_24 = !we;

    // Decode Signals
    reg rw0 = 1;
    wire req0, ack0;
    wire[15:0] dtr0;
    wire [19:0] adr0;
    
    // XU Signals
    reg req1 = 0; wire ack1; reg rw1 = 0;
    reg [15:0] dtw1 = 0;
    wire[15:0] dtr1;
    reg [19:0] adr1 = 0;

    // I/O Pin Arbitrator
    IO_SYNC mem(
        // Module Signals
        .clk(CLK),
        // Instruction Queue
        .req0(req0), .ack0(ack0),
        .rw0(rw0), /*.dtw0(dtw0),*/
        .dtr0(dtr0), .adr0(adr0),
        // Execution Engine
        .req1(req1), .ack1(ack1),
        .rw1(rw1), .dtw1(dtw1),
        .dtr1(dtr1), .adr1(adr1),
        // External IO
        .din(din), .dout(dout), .adr_hi(adr_hi),
        .oe(oe), .oe_neg(oe_neg), .we(we), .ale_neg(ale_neg),
        .pio(pio), .isout(isout)
    );

    PREFETCH prefetch(
        // Module Signals
        .clk(CLK),
        // Instruction Queue
        .req(req0), .ack(ack0), .dtr(dtr0), .adr(adr0)
        // XU Interface
    );

    // UART communication
    assign LED = !PIN_25;
	wire rdy;
	wire rxn;
    reg  txn = 0;
	wire[7:0] rx_data;
    reg [7:0] tx_buf = 0;
	uart_tx uart_tx1(
        .clk(CLK),
		.new_data(txn),
		.char(tx_buf),
		.rdy(rdy),		
		.out_bit(PIN_26)
	);
	uart_rx uart_rx1(
        .clk(CLK),
		.data_in(PIN_25),
		.data_out(rx_data),
		.new_data(rxn)
	);

    // FSM
    reg[3:0] state = 0;
    always @(posedge CLK) begin
        
    end

    always @(negedge CLK) begin
        
    end
endmodule