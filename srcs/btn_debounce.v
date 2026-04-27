// btn_debounce.v
// Debounces a single button and produces a 1-cycle rising-edge pulse.

module btn_debounce (
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_pulse
);

    reg [19:0] cnt    = 0;
    reg        stable = 0;
    reg        prev   = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt       <= 0;
            stable    <= 0;
            prev      <= 0;
            btn_pulse <= 0;
        end else begin
            btn_pulse <= 0;
            if (btn_in != stable) begin
                cnt <= cnt + 1;
                if (cnt == 20'hFFFFF) begin
                    stable <= btn_in;
                    cnt    <= 0;
                end
            end else
                cnt <= 0;

            prev <= stable;
            if (stable && !prev)
                btn_pulse <= 1;
        end
    end

endmodule