module IO_SYNC(
    // Instruction Queue
    input   wire req0,
    output  wire ack0,
    input   wire rw0,
    input   wire[15:0] dtw0,
    output  wire[15:0] dtr0,
    input   wire[19:0] adr0,
    
    // Execution Engine
    input   wire req1,
    output  wire ack1,
    input   wire rw1,
    input   wire[15:0] dtw1,
    output  wire[15:0] dtr1,
    input   wire[19:0] adr1,
    
    // Module Signals
    input   wire clk,
    output  reg  busy,

    // External IO
    input  [15:0] din,
    output reg [15:0] dout,
    output reg [3:0] adr_hi,
    output reg oe, output reg oe_neg,
    output reg we, output reg ale_neg,
    output reg pio, output reg isout
);
    // Configure data and signals
    reg st, ack;
    wire[15:0] data_write;
    assign dtr0 = din;
    assign dtr1 = din;
    assign data_write = st ? dtw1 : dtw0;
    assign ack0 = st ? 0 : ack;
    assign ack1 = st ? ack : 0;

    // FSM: 1 read/write cycle = 3 clock cycles
    reg[2:0] state = 0;
    always @(posedge clk) begin case(state)
        default: begin
            { we, oe, pio } <= 3'b001;
            busy <= req0 || req1;
            isout <= req0 || req1;
            // Execute 1 cycle, although messy it saves us 1 clock
            // Choose which module should get priority
            if(req1) begin
                st <= 1;
                state <= { rw1, 2'b01 };
                { adr_hi, dout } <= adr1;
            end else if(req0) begin
                st <= 0;
                state <= { rw0, 2'b01 };
                { adr_hi, dout } <= adr0;
            // Reset them all
            end else begin
                state <= 0;
            end
        end
        3'b001: begin
            isout <= 0;
            oe <= 1;
            state <= 3'b010;
        end
        3'b010: begin
            state <= 0;
        end
        3'b101: begin
            { we, oe } <= 2'b11;
            dout <= data_write;
            state <= 3'b110;
        end
        3'b110: begin
            { we, oe } <= 2'b00;
            isout <= 0;
            state <= 3'b000;
        end
    endcase; end

    // ALE_NEG allows 1/2T pulses and ACK must be read on rising edge
    always @(negedge clk) begin case(state)
        3'b001: begin 
            ale_neg <= 0;
            oe_neg <= 1;
        end
        3'b010: ack <= 1;
        3'b101: begin
            ale_neg <= 0;
            oe_neg <= 1;
        end
        3'b110: ack <= 1;
        3'b000: begin
            ale_neg <= 1;
            oe_neg <= 0;
            ack <= 0;
        end
    endcase; end
endmodule
