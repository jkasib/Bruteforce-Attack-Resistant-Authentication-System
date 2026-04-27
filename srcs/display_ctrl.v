module display_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire        clk_1khz,
    input  wire        clk_1hz,
    input  wire [2:0]  mode,
    input  wire [3:0]  value,
    input  wire [5:0]  countdown,
    output reg  [3:0]  an,
    output reg  [6:0]  seg,
    output wire        dp
);

    assign dp = 1'b1;

    localparam MODE_BINARY    = 3'd0;
    localparam MODE_COUNTDOWN = 3'd1;
    localparam MODE_MATCHED   = 3'd2;
    localparam MODE_PERM_LOCK = 3'd3;
    localparam MODE_BLANK     = 3'd4;

    // Active LOW: {ca,cb,cc,cd,ce,cf,cg}
    localparam SEG_0     = 7'b0000001;
    localparam SEG_1     = 7'b1001111;
    localparam SEG_DASH  = 7'b1111110;
    localparam SEG_BLANK = 7'b1111111;

    reg [1:0] digit_sel = 0;
    always @(posedge clk_1khz or posedge rst) begin
        if (rst) digit_sel <= 0;
        else     digit_sel <= digit_sel + 1;
    end

    reg toggle = 0;
    always @(posedge clk_1hz or posedge rst) begin
        if (rst) toggle <= 0;
        else     toggle <= ~toggle;
    end

    wire [3:0] cnt_tens  = countdown / 10;
    wire [3:0] cnt_units = countdown % 10;

    function [6:0] dec_seg;
        input [3:0] d;
        case (d)
            4'd0: dec_seg = 7'b0000001;
            4'd1: dec_seg = 7'b1001111;
            4'd2: dec_seg = 7'b0010010;
            4'd3: dec_seg = 7'b0000110;
            4'd4: dec_seg = 7'b1001100;
            4'd5: dec_seg = 7'b0100100;
            4'd6: dec_seg = 7'b0100000;
            4'd7: dec_seg = 7'b0001111;
            4'd8: dec_seg = 7'b0000000;
            4'd9: dec_seg = 7'b0000100;
            default: dec_seg = 7'b1111111;
        endcase
    endfunction

    always @(*) begin
        an  = 4'b1111;
        seg = SEG_BLANK;

        case (mode)
            MODE_BINARY: begin
                case (digit_sel)
                    2'd3: begin an = 4'b0111; seg = value[3] ? SEG_1 : SEG_0; end
                    2'd2: begin an = 4'b1011; seg = value[2] ? SEG_1 : SEG_0; end
                    2'd1: begin an = 4'b1101; seg = value[1] ? SEG_1 : SEG_0; end
                    2'd0: begin an = 4'b1110; seg = value[0] ? SEG_1 : SEG_0; end
                endcase
            end

            MODE_COUNTDOWN: begin
                case (digit_sel)
                    2'd3: begin an = 4'b0111; seg = dec_seg(cnt_tens);  end
                    2'd2: begin an = 4'b1011; seg = dec_seg(cnt_units); end
                    2'd1: begin an = 4'b1101; seg = SEG_BLANK;           end
                    2'd0: begin an = 4'b1110; seg = SEG_BLANK;           end
                endcase
            end

            MODE_MATCHED: begin
                case (digit_sel)
                    2'd3: begin an = 4'b0111; seg = toggle ? SEG_1 : SEG_DASH; end
                    2'd2: begin an = 4'b1011; seg = toggle ? SEG_1 : SEG_DASH; end
                    2'd1: begin an = 4'b1101; seg = toggle ? SEG_1 : SEG_DASH; end
                    2'd0: begin an = 4'b1110; seg = toggle ? SEG_1 : SEG_DASH; end
                endcase
            end

            MODE_PERM_LOCK: begin
                case (digit_sel)
                    2'd3: begin an = 4'b0111; seg = toggle ? SEG_0 : SEG_DASH; end
                    2'd2: begin an = 4'b1011; seg = toggle ? SEG_0 : SEG_DASH; end
                    2'd1: begin an = 4'b1101; seg = toggle ? SEG_0 : SEG_DASH; end
                    2'd0: begin an = 4'b1110; seg = toggle ? SEG_0 : SEG_DASH; end
                endcase
            end

            default: begin
                an  = 4'b1111;
                seg = SEG_BLANK;
            end
        endcase
    end

endmodule