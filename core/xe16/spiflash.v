module spiflash(
    input clk,
    input flashMiso, output reg flashMosi,
    output reg flashCs, output reg flashClk,
    input [23:0] addr, output reg [7:0] data,
    input ena, output reg done
);

    wire [31:0] comm;
    assign comm = (8'h03 << 24) | addr;
    reg [31:0] idx;
    reg [3:0] state;
    localparam STATE_WAIT = 0;
    localparam STATE_WARMUP = 1;
    localparam STATE_SENDCOMMAND = 2;
    localparam STATE_RECEIVE = 3;
    localparam STATE_END = 4;
    reg dwi;
    initial begin
        done = 0;
        dwi = 0;
        flashMosi = 0;
        flashCs = 1; 
        flashClk = 0;
        data = 0;
        state = STATE_WAIT;
        idx = 0;
    end
    always @(posedge clk) begin
        case (state)
            STATE_WAIT: begin
                if (ena && flashCs) begin
                    idx <= 0;
                    state <= STATE_WARMUP;
                    dwi <= 0;
                    done <= 0;
                end
            end
            STATE_WARMUP: begin
                if (idx != 32'hff) begin
                    idx <= idx + 1;
                end else begin
                    idx <= 0;
                    state <= STATE_SENDCOMMAND;
                    data <= 0;
                    flashCs <= 0;
                    flashClk <= 0;
                end
            end
            STATE_SENDCOMMAND: begin
                flashCs <= 0;
                if (idx != 32) begin
                    if (~dwi) begin 
                        flashClk <= 0;
                        flashMosi <= comm[31 - idx]; 
                    end else begin
                        flashClk <= 1;
                        idx <= idx + 1;
                    end
                    dwi <= ~dwi; 
                end else begin
                    state <= STATE_RECEIVE;
                    idx <= 0;
                    dwi <= 0;
                    flashClk <= 0;
                end
            end
            STATE_RECEIVE: begin
                flashCs <= 0;
                if (idx != 8) begin
                    if (~dwi) begin
                        data[7 - idx] <= flashMiso;
                        flashClk <= 1;
                    end else begin
                        flashClk <= 0;
                        idx <= idx + 1;
                    end
                    dwi <= ~dwi; 
                end else begin
                    state <= STATE_END;
                    idx <= 0;
                    dwi <= 0;
                end
            end
            STATE_END: begin
                flashCs <= 1;
                if (~ena) state <= STATE_WAIT;
                flashClk <= 1;
                done <= 1;
            end
        endcase
    end
endmodule
