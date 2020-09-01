module UC_ROM (
    input [data_width-1:0] din,
    input [addr_width-1:0] addr,
    input write_en,
    input clk,
    output reg [data_width-1:0] dout
); // 512x8
    parameter addr_width = 9;
    parameter data_width = 8;
    reg [data_width-1:0] mem [(1<<addr_width)-1:0];
    always @(posedge clk) begin if (write_en)
        mem[(addr)] <= din;
        dout = mem[addr];
    end
    initial begin
        $readmemh("./cpu/rom_jump.mem", mem);
    end
endmodule