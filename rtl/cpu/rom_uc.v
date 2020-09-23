module ROM_UC (
    input clk,
    //input [data_width-1:0] din_n,
    input [addr_width-1:0] adr_n,
    //input we_n,
    output reg [data_width-1:0] dout_p
);
    parameter addr_width = 8;
    parameter data_width = 16;
    reg [data_width-1:0] mem [(1<<addr_width)-1:0];
    always @(posedge clk) begin
        //if (we_n) mem[(adr_n)] <= din_n;
        dout_p = mem[adr_n];
    end
    initial begin
`ifdef SIMULATION
        $readmemh("../cpu/rom_uc.mem", mem);
`else
        $readmemh("./cpu/rom_uc.mem", mem);
`endif
    end
endmodule