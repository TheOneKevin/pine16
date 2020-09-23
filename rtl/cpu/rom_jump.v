module ROM_JUMP (
    input clk,
    //input [data_width-1:0] din,
    input [addr_width-1:0] adr_n,
    //input write_en,
    output reg [data_width-1:0] dout_p
); // 512x8
    parameter addr_width = 8;
    parameter data_width = 8;
    reg [data_width-1:0] mem [(1<<addr_width)-1:0];
    always @(posedge clk) begin
        //if (write_en) mem[(addr)] <= din;
        dout_p = mem[adr_n];
    end
    initial begin
`ifdef SIMULATION
        $readmemh("../cpu/rom_jump.mem", mem);
`else
        $readmemh("./cpu/rom_jump.mem", mem);
`endif
    end
endmodule