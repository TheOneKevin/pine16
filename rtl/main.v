`include "cpu/io.v"
`include "cpu/prefetch.v"
`include "cpu/decoder.v"
`include "cpu/execute.v"
//`include "uart/uart.v"

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
    assign PIN_22 = !(oe & oe_neg);
    assign PIN_23 = ale_neg;
    assign PIN_24 = !we;
    
    // Prefetch-Memory Signals
    wire rqm_pq, akm_pq;
    wire[15:0] drm_pq;
    wire[19:0] adm_pq;

    // Decode-Prefetch Signals
    wire rqi_dc, aki_dc;
    wire[31:0] instr_dc;

    // Execute-Memory Signals
    wire rqm_xu, akm_xu, rwm_xu;
    wire[15:0] drm_xu, dwm_xu;
    wire [19:0] adm_xu;

    // Execute-Decode Signals
    wire akx_dc, rqx_dc;
    wire [15:0] uop_dc, opimm;
    wire [3:0] regsrc, regdst, aluop;

    // Reg reset
    reg reset = 0;

    // I/O Pin Arbitrator
    IO_SYNC mem(
        .clk(CLK),
        // Instruction Queue
        .req0(rqm_pq), .ack0(akm_pq), .rw0(1'b0),
        .adr0(adm_pq), .dtr0(drm_pq), .dtw0(16'b0),
        // Execute
        .req1(rqm_xu), .ack1(akm_xu),
        .rw1(rwm_xu), .dtw1(dwm_xu),
        .dtr1(drm_xu), .adr1(adm_xu),
        // External IO (physical pins)
        .din(din), .dout(dout), .adr_hi(adr_hi),
        .oe(oe), .oe_neg(oe_neg), .we(we), .ale_neg(ale_neg),
        .pio(pio), .isout(isout)
    );

    PREFETCH prefetch(
        .clk(CLK),
        // Memory
        .req(rqm_pq), .ack(akm_pq), .dtr(drm_pq), .adr(adm_pq),
        // Decoder Interface
        .rqi_p(rqi_dc), .aki_n(aki_dc), .instr(instr_dc),
        // Flush/Reset
        .sigflush(reset), .fadr(21'b0)
    );

    DECODER decoder(
        .clk(CLK),
        // PQ Interface
        .rqi_p(rqi_dc), .aki_n(aki_dc), .cmd(instr_dc),
        // XU Interface
        .akx_n(akx_dc), .rqx_p(rqx_dc), .opout_p(uop_dc),
        .regsrc(regsrc), .regdst(regdst), .aluop(aluop),
        .opimm(opimm)
    );

    EXECUTE execute(
        .clk(CLK),
        // XU Interface
        .akx_n(akx_dc), .rqx_p(rqx_dc), .opout_p(uop_dc),
        .regsrc(regsrc), .regdst(regdst), .aluop(aluop),
        .opimm(opimm),
        // Memory
        .rqm_n(rqm_xu), .rwm_n(rwm_xu),
        .akm_n(akm_xu), .drm_n(drm_xu),
        .dwm_n(dwm_xu), .adm_n(adm_xu)
    );

    // UART communication
    /*assign LED = !PIN_25;
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
	);*/

    // FSM
    reg[3:0] state = 0;
    always @(posedge CLK) case(state)
        4'b0000: begin
            reset <= 1;
            state <= 4'b0001;
        end
        4'b0001: state <= 4'b0010;
        4'b0010: begin
            reset <= 0;
            state <= 4'b0011;
        end
    endcase

    always @(negedge CLK) begin
        
    end
endmodule