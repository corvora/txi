module ram #(
    parameter BITS = 8, parameter SIZE = 16384, parameter ADDRBITS = 16
) (
    input clk,
    input ena,
    input enw,
    input [BITS-1:0] din,
    output reg [BITS-1:0] dout,
    input [ADDRBITS-1:0] addr
);
    (* ram_style = "block" *) reg [BITS-1:0] ram [0:SIZE-1];
    always @(posedge clk) begin
        if (ena && enw) begin
            ram[addr] <= din;
        end
    end
    always @(posedge clk) begin
        if (ena && (~enw)) begin
            dout <= ram[addr];
        end
    end
endmodule
