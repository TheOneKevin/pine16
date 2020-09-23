`include "cpu/io.v"
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

    // Test
    reg req0 = 0; wire ack0; reg rw0 = 0;
    reg [15:0] dtw0 = 0;
    wire[15:0] dtr0;
    reg [19:0] adr0 = 0;
    
    reg req1 = 0; wire ack1; reg rw1 = 0;
    reg [15:0] dtw1 = 0;
    wire[15:0] dtr1;
    reg [19:0] adr1 = 0;

    // Summon Satan!
    IO_SYNC mem(
        // Module Signals
        .clk(CLK),
        // Instruction Queue
        .req0(req0), .ack0(ack0), .rw0(rw0), .dtw0(dtw0), .dtr0(dtr0), .adr0(adr0),
        // Execution Engine
        .req1(req1), .ack1(ack1), .rw1(rw1), .dtw1(dtw1), .dtr1(dtr1), .adr1(adr1),
        // External IO
        .din(din), .dout(dout), .adr_hi(adr_hi),
        .oe(oe), .oe_neg(oe_neg), .we(we), .ale_neg(ale_neg), .pio(pio),
        .isout(isout)
    );

    // UART communication
    assign LED = !PIN_26;
	wire rdy;
	wire rxn;
    reg  txn = 0, init = 0;
	wire[7:0] rx_data;
    reg [7:0] tx_buf = 0;
    reg [15:0] tx_buf_buf = 0;
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
    reg[3:0] fsm1 = 0;
    reg[3:0] fsm2 = 0;
    reg[7:0] cmd = 0;
    always @(negedge CLK) case(fsm1)
        default: begin // Get r/w
            if(rxn) begin 
                fsm1 <= 1;
                if(rx_data == 8'h77) begin // 'w'
                    rw1 <= 1;
                end else begin
                    rw1 <= 0;
                end
                cmd <= rx_data;
            end
        end
        1: if(rxn) begin // Get address
            if(cmd == 8'h68 || cmd == 8'h6C) begin // 'h' || 'l'
                fsm1 <= 2;
            end else if(cmd == 8'h77) begin // 'w'
                fsm1 <= 10;
            end else begin
                fsm1 <= 0;
            end
            adr1 <= { 12'b0, rx_data };
        end
        2: fsm1 <= 3; // Go!
        3: fsm1 <= 4;
        4: fsm1 <= 5;
        5: fsm1 <= 0;
        10: if(rxn) begin // Get data
            fsm1 <= 11;
            dtw1[15:8] <= rx_data;
        end
        11: if(rxn) begin
            fsm1 <= 2;
            dtw1[7:0] <= rx_data;
        end
    endcase

    always @(negedge CLK) case(fsm2)
        0: begin
            txn <= 0;
            if(ack1 && (cmd == 8'h68 || cmd == 8'h6C)) begin
                fsm2 <= 1;
                tx_buf_buf <= dtr1;
            end
        end
        1: begin
            if(rdy) begin
                txn <= 1;
                if(cmd == 8'h68) begin
                    tx_buf <= tx_buf_buf[15:8];
                end else if(cmd == 8'h6C) begin
                    tx_buf <= tx_buf_buf[7:0];
                end else begin
                    tx_buf <= cmd;
                end
                fsm2 <= 0;
            end else txn <= 0;
        end
    endcase

    always @(negedge CLK) case(fsm1)
        2: req1 <= 1;
        3: req1 <= 0;
    endcase
endmodule