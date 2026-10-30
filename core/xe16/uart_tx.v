module uart_tx #(
    parameter FRAME_LENGTH = 234
) (
    input clk,
    output tx,
    input ena,
    input [7:0] cdata,
    output reg ens
);
    // Clock-dependent
    localparam START = 1'b0;
    localparam IDLE = 1'b1;
    localparam ST_WAIT = 3'b001;
    localparam ST_START = 3'b010;
    localparam ST_SEND = 3'b011;
    localparam ST_END = 3'b100;
    reg tx_rg;
    reg [15:0] counter;
    reg [7:0] bitdx;
    reg [7:0] data;
    initial data = 0;
    reg [2:0] state;
    initial tx_rg = IDLE;
    initial state = ST_WAIT;
    initial counter = 0;
    initial bitdx = 0;
    assign tx = tx_rg;
    initial ens = 0;
    always @(posedge clk) begin
        case (state)
            ST_WAIT: begin
                tx_rg <= IDLE;
                if ((counter + 1) == FRAME_LENGTH) begin
                    if (ena) begin
                        counter <= 0;
                        state <= ST_START;
                        bitdx <= 0;
                        data <= cdata;
                        ens <= 1;
                    end
                end else counter <= counter + 1;
            end
            ST_START: begin
                tx_rg <= START;
                if ((counter + 1) == FRAME_LENGTH) begin
                    bitdx <= 0;
                    state <= ST_SEND; 
                    counter <= 0;
                end else counter <= counter + 1;
            end
            ST_SEND: begin
                tx_rg <= data[bitdx]; 
                if ((counter + 1) == FRAME_LENGTH) begin
                    if (bitdx == 7) begin
                        bitdx <= 0;
                        state <= ST_END;
                    end else begin
                        bitdx <= bitdx + 1;
                    end
                    counter <= 0;
                end else counter <= counter + 1;
            end
            ST_END: begin
                tx_rg <= IDLE;
                state <= ST_WAIT;
                ens <= 0;
            end
        endcase
    end
endmodule