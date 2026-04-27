// buzzer_ctrl.v
// Generates repeating beep-beep pattern for 5 or 7 seconds total
// Beep pattern: 200ms ON, 200ms OFF, repeating
// buzz_duration: 0 = 5s total, 1 = 7s total

module buzzer_ctrl (
    input  wire clk,
    input  wire rst,
    input  wire clk_1hz,
    input  wire buzz_trigger,
    input  wire buzz_duration,
    output reg  buzzer_out
);

    // We need a 5Hz clock (200ms period) for beep toggling
    // 100MHz / (5Hz * 2) = 10,000,000 counts per half period
    localparam CNT_5HZ = 9_999_999;

    reg [23:0] cnt_5hz   = 0;
    reg        clk_5hz   = 0;

    // 5Hz clock generator
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_5hz <= 0;
            clk_5hz <= 0;
        end else begin
            if (cnt_5hz == CNT_5HZ) begin
                cnt_5hz <= 0;
                clk_5hz <= ~clk_5hz;
            end else
                cnt_5hz <= cnt_5hz + 1;
        end
    end

    // Rising edge detection on clk_1hz and clk_5hz
    reg prev_1hz = 0;
    reg prev_5hz = 0;
    wire tick_1hz = clk_1hz && !prev_1hz;
    wire tick_5hz = clk_5hz && !prev_5hz;

    reg [3:0] sec_cnt  = 0;   // counts seconds elapsed
    reg [3:0] target   = 0;   // 5 or 7 seconds
    reg       active   = 0;
    reg [3:0] beep_tog = 0;   // toggles buzzer at 5Hz when active

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_1hz   <= 0;
            prev_5hz   <= 0;
            sec_cnt    <= 0;
            target     <= 0;
            active     <= 0;
            buzzer_out <= 0;
            beep_tog   <= 0;
        end else begin
            prev_1hz <= clk_1hz;
            prev_5hz <= clk_5hz;

            if (buzz_trigger) begin
                active     <= 1;
                sec_cnt    <= 0;
                beep_tog   <= 0;
                target     <= buzz_duration ? 4'd7 : 4'd5;
                buzzer_out <= 1;  // start with beep ON
            end else if (active) begin
                // Toggle buzzer at 5Hz to create beep-beep
                if (tick_5hz) begin
                    buzzer_out <= ~buzzer_out;
                end

                // Count total seconds and stop after target
                if (tick_1hz) begin
                    if (sec_cnt + 1 >= target) begin
                        active     <= 0;
                        buzzer_out <= 0;
                        sec_cnt    <= 0;
                    end else
                        sec_cnt <= sec_cnt + 1;
                end
            end
        end
    end

endmodule