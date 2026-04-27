module main_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] sw,
    input  wire       btnU_raw,
    input  wire       btnL_raw,
    input  wire       btnR_raw,
    output wire [3:0] an,
    output wire [6:0] seg,
    output wire       dp,
    output wire       buzzer_out
);

    wire clk_1hz, clk_1khz;
    clk_divider u_clkdiv (
        .clk     (clk),
        .rst     (rst),
        .clk_1hz (clk_1hz),
        .clk_1khz(clk_1khz)
    );

    wire btnU, btnL, btnR;
    btn_debounce u_dbU (.clk(clk),.rst(rst),.btn_in(btnU_raw),.btn_pulse(btnU));
    btn_debounce u_dbL (.clk(clk),.rst(rst),.btn_in(btnL_raw),.btn_pulse(btnL));
    btn_debounce u_dbR (.clk(clk),.rst(rst),.btn_in(btnR_raw),.btn_pulse(btnR));

    // Free-running counter for LFSR seeding
    reg [3:0] free_cnt = 0;
    always @(posedge clk) free_cnt <= free_cnt + 1;

    reg  lfsr_en   = 0;
    reg  lfsr_seed = 0;
    wire [3:0] rand_val;
    lfsr_rand u_lfsr (
        .clk      (clk),
        .rst      (rst),
        .en       (lfsr_en),
        .seed_load(lfsr_seed),
        .seed     (free_cnt),
        .rand_out (rand_val)
    );

    reg [3:0] seq_cnt = 0;

    reg buzz_trigger  = 0;
    reg buzz_duration = 0;
    buzzer_ctrl u_buzz (
        .clk          (clk),
        .rst          (rst),
        .clk_1hz      (clk_1hz),
        .buzz_trigger  (buzz_trigger),
        .buzz_duration (buzz_duration),
        .buzzer_out    (buzzer_out)
    );

    reg [2:0] disp_mode      = 3'd0;
    reg [3:0] disp_value     = 0;
    reg [5:0] disp_countdown = 0;
    display_ctrl u_disp (
        .clk      (clk),
        .rst      (rst),
        .clk_1khz (clk_1khz),
        .clk_1hz  (clk_1hz),
        .mode     (disp_mode),
        .value    (disp_value),
        .countdown(disp_countdown),
        .an       (an),
        .seg      (seg),
        .dp       (dp)
    );

    localparam S_IDLE      = 3'd0;
    localparam S_PASS_SET  = 3'd1;
    localparam S_GUESSING  = 3'd2;
    localparam S_TEMP_LOCK = 3'd3;
    localparam S_PERM_LOCK = 3'd4;
    localparam S_MATCHED   = 3'd5;

    localparam MODE_BINARY    = 3'd0;
    localparam MODE_COUNTDOWN = 3'd1;
    localparam MODE_MATCHED   = 3'd2;
    localparam MODE_PERM_LOCK = 3'd3;
    localparam MODE_BLANK     = 3'd4;

    reg [2:0] state        = S_IDLE;
    reg [3:0] password     = 0;
    reg [3:0] guess        = 0;
    reg [1:0] wrong_cnt    = 0;
    reg       had_temp     = 0;
    reg [5:0] lock_timer   = 0;
    reg [1:0] guess_mode   = 0;
    reg       holding      = 0;

    reg prev_1hz = 0;
    wire tick_1hz = clk_1hz && !prev_1hz;
    always @(posedge clk) prev_1hz <= clk_1hz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state          <= S_IDLE;
            password       <= 0;
            guess          <= 0;
            wrong_cnt      <= 0;
            had_temp       <= 0;
            lock_timer     <= 0;
            seq_cnt        <= 0;
            lfsr_en        <= 0;
            lfsr_seed      <= 0;
            buzz_trigger   <= 0;
            buzz_duration  <= 0;
            disp_mode      <= MODE_BINARY;
            disp_value     <= 4'b0000;
            disp_countdown <= 0;
            guess_mode     <= 0;
            holding        <= 0;
        end else begin
            buzz_trigger <= 0;
            lfsr_en      <= 0;
            lfsr_seed    <= 0;

            case (state)

                S_IDLE: begin
                    disp_mode  <= MODE_BINARY;
                    disp_value <= 4'b0000;
                    guess_mode <= 0;
                    holding    <= 0;
                    if (btnU) begin
                        password   <= sw;
                        disp_value <= sw;
                        state      <= S_PASS_SET;
                    end
                end

                S_PASS_SET: begin
                    disp_mode  <= MODE_BINARY;
                    disp_value <= password;
                    guess_mode <= 0;
                    holding    <= 0;
                    if (btnU) begin
                        password   <= sw;
                        disp_value <= sw;
                    end
                    if (btnL) begin
                        wrong_cnt  <= 0;
                        guess_mode <= 2'd1;
                        holding    <= 0;
                        lfsr_seed  <= 1;
                        state      <= S_GUESSING;
                    end
                    if (btnR) begin
                        wrong_cnt  <= 0;
                        seq_cnt    <= 0;
                        guess_mode <= 2'd2;
                        holding    <= 0;
                        state      <= S_GUESSING;
                    end
                end

                S_GUESSING: begin
                    disp_mode <= MODE_BINARY;
                    if (!holding) begin
                        if (guess_mode == 2'd1) begin
                            guess      <= rand_val;
                            lfsr_en    <= 1;
                            disp_value <= rand_val;
                        end else begin
                            guess      <= seq_cnt;
                            disp_value <= seq_cnt;
                            seq_cnt    <= seq_cnt + 1;
                        end
                        holding <= 1;
                    end else begin
                        disp_value <= guess;
                        if (tick_1hz) begin
                            holding <= 0;
                            if (guess == password) begin
                                state <= S_MATCHED;
                            end else begin
                                if (wrong_cnt == 2'd2) begin
                                    wrong_cnt <= 0;
                                    if (had_temp) begin
                                        buzz_duration <= 1;
                                        buzz_trigger  <= 1;
                                        state         <= S_PERM_LOCK;
                                    end else begin
                                        had_temp      <= 1;
                                        buzz_duration <= 0;
                                        buzz_trigger  <= 1;
                                        lock_timer    <= 30;
                                        state         <= S_TEMP_LOCK;
                                    end
                                end else begin
                                    wrong_cnt <= wrong_cnt + 1;
                                end
                            end
                        end
                    end
                end

                S_TEMP_LOCK: begin
                    disp_mode      <= MODE_COUNTDOWN;
                    disp_countdown <= lock_timer;
                    if (tick_1hz) begin
                        if (lock_timer == 0) begin
                            holding <= 0;
                            state   <= S_GUESSING;
                        end else
                            lock_timer <= lock_timer - 1;
                    end
                end

                S_PERM_LOCK: begin
                    disp_mode <= MODE_PERM_LOCK;
                end

                S_MATCHED: begin
                    disp_mode <= MODE_MATCHED;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule