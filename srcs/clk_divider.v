// clk_divider.v
// Generates clk_1hz (1 Hz) and clk_1khz (1 kHz) from 100 MHz system clock

module clk_divider (
    input  wire clk,
    input  wire rst,
    output reg  clk_1hz,
    output reg  clk_1khz
);

    localparam CNT_1HZ  = 49_999_999;
    localparam CNT_1KHZ = 49_999;

    reg [25:0] cnt_1hz  = 0;
    reg [15:0] cnt_1khz = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1hz  <= 0;
            clk_1hz  <= 0;
            cnt_1khz <= 0;
            clk_1khz <= 0;
        end else begin
            if (cnt_1hz == CNT_1HZ) begin
                cnt_1hz <= 0;
                clk_1hz <= ~clk_1hz;
            end else
                cnt_1hz <= cnt_1hz + 1;

            if (cnt_1khz == CNT_1KHZ) begin
                cnt_1khz <= 0;
                clk_1khz <= ~clk_1khz;
            end else
                cnt_1khz <= cnt_1khz + 1;
        end
    end

endmodule