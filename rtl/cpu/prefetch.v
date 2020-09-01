/*
    Timing diagram for data clocking and such
               | NOP | Active -->|
         ┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
    clk: └──┘  └──┘  └──┘  └──┘  └─ ...
            | T0  | T1  | T2  |...
            ^ din ^ dlo ^ dhi
    Top row indicates decoder active period
    while bottom row indicates the data
    byte (hi/lo) currently being decoded.
*/

module PREFETCH(
    input   wire clk,

    // IO Synchronization Interface
    output  reg  req = 1,
    input   wire ack,
    input   wire[15:0] dtr,
    output  reg [19:0] adr,

    // XU Interface
    input   wire reqi,
    output  reg  acki,
    output  reg [31:0] instr,

    // Flush
    input   wire sigflush,
    input   wire[20:0] fadr
);
    parameter BW=8;
    parameter LG=3;

    // FIFO Logic (ZipCPU example)
    reg [(BW-1):0] fmm0[0:(1<<LG)-1];
    reg [(BW-1):0] fmm1[0:(1<<LG)-1];
    reg [(BW-1):0] fmm2[0:(1<<LG)-1];
    reg [(BW-1):0] fmm3[0:(1<<LG)-1];
    reg [LG:0] wp = 0, rp = 0, fill;
    reg full, empty;

    always @(*)
        fill = wp - rp;
    always @(*)
        full = fill == { 1'b1, {(LG) {1'b0}} };
    always @(*)
        empty = fill == 0;
    always @(*)
        instr = {
            fmm0[rp[LG-1:0]], 
            fmm1[rp[LG-1:0]],
            fmm2[rp[LG-1:0]],
            fmm3[rp[LG-1:0]]
        };
    
    always @(posedge clk) begin
        acki <= reqi && !empty && !sigflush;
        if(reqi && !empty && !sigflush) begin    
            rp <= rp + 1;
        end else if(sigflush) begin
            rp <= 0;
        end
    end

    // Combinatorial Logic
    reg [15:0] data_r;
    reg [7:0] cur;

    // Decoder/Opcode boundary fsm
    // State determines which byte we are on
    reg [1:0] fsm1;
    reg [1:0] fsm1_next;
    reg active;

    // Decode logic
    wire u, t;
    reg szw;
    assign u = cur[6];
    assign t = cur[7];
    integer i; // For reset
    always @(negedge clk) begin if(flush) begin
        wp <= 0;
        fsm1_next <= 0;
        for (i = 0; i < (1 << LG); i++) begin
            fmm0[i] <= 0;
            fmm1[i] <= 0;
            fmm2[i] <= 0;
            fmm3[i] <= 0;
        end
    end else if(active) case(fsm1)
        2'b00: begin
            wp = wp + 1'b1;
            fmm0[wp[LG-1:0]] <= cur; // Store sync'd to rp
            fsm1_next <= { 1'b0, u || t };
        end
        2'b01: begin
            fmm1[wp[LG-1:0]] <= cur;
            szw <= t;   // test b
            fsm1_next <= { u, 1'b0 }; // v and !v
        end
        2'b10: begin
            fmm2[wp[LG-1:0]] <= cur;
            fsm1_next <= { szw, szw };
        end
        2'b11: begin
            fmm3[wp[LG-1:0]] <= cur;
            fsm1_next <= 2'b00;
        end
    endcase; end

    // Flush occurs rising edge
    reg flush, ignoreAck;
    reg[20:0] new_addr;

    // Memory interface fsm
    reg [1:0] fsm2;
    reg [1:0] fsm2_next;
    always @(posedge clk) begin if(sigflush) begin
        flush <= sigflush;      // Reset
        adr <= fadr[20:1];
        fsm2 <= 0;
        fsm2_next <= { fadr[0], 1'b1 };
        fsm1 <= 0;
        if(req) begin
            req <= 0;
            ignoreAck <= 1;
        end
    end else case(fsm2)         // If not resetting...
    2'b00: begin                // Start first case
        active <= 0;
        data_r <= dtr;
        // Check if next hypothetical write will fill queue
        // We don't want the queue to fill mid-cycle
        req <= fill < ((1 << LG)-2);
        if(ack && !ignoreAck && fill < ((1 << LG)-2)) begin
            fsm2 <= fsm2_next;
        end else if(ack && ignoreAck) begin
            ignoreAck <= 0;
        end
        if(flush) begin
            flush <= 0;
        end
    end
    2'b01: begin                // Lo byte (active cycle)
        active  <= !full;
        cur     <= dtr[7:0];
        fsm1    <= fsm1_next;
        fsm2    <= 2'b11;
    end
    2'b11: begin                // Hi byte (active cycle)
        active  <= !full;
        cur     <= data_r[15:8];
        fsm2_next <= 2'b01;     // Reset the next FSM2 state
        fsm1    <= fsm1_next;
        adr     <= adr + 1;
        fsm2    <= 2'b00;
    end endcase; end
endmodule

/*
    Notes:
     - The amount of NOP/T0 cycles is dictated by memory speed
     - T0 is synchronized to LL, they happen at the T0 state of the FSM
    Pipeline:
    T0 = Request, FF = Fetch, LL = Latch, T1/T2 = Decode hi/lo byte
    [T0][FF][FF][LL][T1][T2]
                [T0][FF][FF][LL][T1][T2]
                            [T0][FF][FF][LL][T1][T2]
                                        [T0][...
    Time +--------->
    If the pipeline is stalled, i.e., a T0 request was denied:
    [T0][..][..][xx][xx][LL]
                        [T0][..][..][xx][LL]
    We only know on the next T0/LL cycle (as ack will be low). In this case,
    we stay in the T0 state until ack is raised again; here, another req will be sent
    and the pipeline continues.
*/
