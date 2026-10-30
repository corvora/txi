module divmod #(
    parameter BITS = 16
)(
    input clk,
    input [BITS-1:0] A,
    input [BITS-1:0] B,
    output reg [BITS-1:0] C,
    output reg [BITS-1:0] D,
    output reg E,
    input F
);
    reg [BITS-1:0] G;
    reg H;
    initial E = 0;
    initial H = 1;
    initial C = 0;
    initial D = 0;
    always @(posedge clk) begin
        if (E && H) begin
            G <= A;
            H <= 0;
            C <= 0;
            D <= 0;
            if (A == 0 || B == 0) begin
                E <= 0;
                H <= 1;
            end
        end else if (E) begin
            if (G == A && A == B) begin
                D <= 0;
                C <= 1;
                E <= ~E;
                H <= 1;
            end else if (G < B) begin
                D <= G;
                E <= ~E;
                H <= 1;
            end else begin
                C <= C + 1;
                G <= G - B;
            end
        end else begin
            E <= F;
        end
    end
endmodule