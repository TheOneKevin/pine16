module ALU(
    input   wire clk,
    input   wire[15:0]  a,
    input   wire[3:0]   op,
    output  reg [15:0]  r,
    output  reg [3:0]   f // nzcv flags
);
    reg sgn;
    reg [15:0] b;
    always @(negedge clk) begin
        case(op)
            4'b0001: { f[1], r } = a + b;
            4'b0010: { f[1], r } = { 1'b0, a } - { 1'b0, b };
            4'b0100: r = a & b;
            4'b0101: r = a | b;
            4'b0110: r = a ^ b;
            4'b0111: r = a >> b[3:0];
            4'b1000: { f[1], r } = {1'b0, a } << b[3:0];
            4'b1100: b = a;
            default: r = a;
        endcase
        sgn = op == 4'b0001 && a[3] == b[3] ||
              op == 4'b0010 && a[3] != b[3];
        f[0] = sgn && (a[3] != r[3]);
        f[2] = (r == 16'b0);
        f[3] = r[3];
    end
endmodule