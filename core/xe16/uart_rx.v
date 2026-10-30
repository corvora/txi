module uart_rx #(
    parameter FRAME_LENGTH = 234
) (
    input clk, input rx, output reg [7:0] data, output reg done, input ena, output reg idle
);
    localparam STATE_ENA = 0;
    localparam STATE_WAIT_FULL_FRAME = 1;
    localparam STATE_RECV_BITS = 2;
    localparam STATE_STOP_BIT = 3;
    localparam STATE_DONE = 4;
    reg [7:0] state;
    reg [7:0] bstate;
    reg [7:0] bitcounter;
    reg [15:0] counter;
    initial bitcounter = 0;
    initial counter = 0;
    initial bstate = 0;
    initial done = 0;
    initial idle = 0;
    initial data = 0;
    initial state = STATE_ENA;
    always @(posedge clk) begin
        case (state)
            STATE_ENA: begin
                if (rx == 0 && ena) begin
                    state <= STATE_WAIT_FULL_FRAME;
                    bstate <= STATE_RECV_BITS;
                    counter <= 0;
                    done <= 0;
                    idle <= 1;
                    bitcounter <= 0;
                    data <= 0;
                end
            end
            STATE_WAIT_FULL_FRAME: begin
                counter <= counter + 1;
                if ((counter + 1) == FRAME_LENGTH) begin
                    state <= bstate;
                    counter <= 0;
                end
            end
            STATE_RECV_BITS: begin
                idle <= 0;
                data[bitcounter] <= rx;
                if (bitcounter == 7) begin
                    state <= STATE_WAIT_FULL_FRAME;
                    bstate <= STATE_STOP_BIT;
                end else begin
                    bitcounter <= bitcounter + 1;
                    bstate <= STATE_RECV_BITS;
                    state <= STATE_WAIT_FULL_FRAME;
                end
            end
            STATE_STOP_BIT: begin
                bitcounter <= 0;
                if (rx == 1) begin
                    state <= STATE_DONE;
                end
            end
            STATE_DONE: begin
                state <= STATE_WAIT_FULL_FRAME;
                bstate <= STATE_ENA;
                bitcounter <= 0;
                done <= 1;
            end
        endcase
    end
endmodule