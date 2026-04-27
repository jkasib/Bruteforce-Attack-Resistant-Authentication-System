module lfsr_rand (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    input  wire       seed_load,
    input  wire [3:0] seed,
    output reg  [3:0] rand_out
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            rand_out <= 4'b1001;
        else if (seed_load)
            rand_out <= (seed == 4'b0000) ? 4'b0001 : seed;
        else if (en)
            rand_out <= {rand_out[0] ^ rand_out[3],
                         rand_out[3:1]};
    end

endmodule