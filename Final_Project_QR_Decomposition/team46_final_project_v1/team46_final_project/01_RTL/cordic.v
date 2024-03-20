module cordic#(
    parameter i_int = 4, // bits of integer part of input -> must be 4
    parameter i_wide = 18 // bits of input
)
(
    input i_clk,
    input i_rst,
    input i_en,                 //module enable
    input i_mode,               //0: div, 1: sqrt
    input signed [i_wide - 1:0] i1,
    input signed [i_wide - 1:0] i2,
    input i_valid,
    output [i_wide - 1:0] o_out,
    output o_valid
);
// i1,i2 : real number
// result : i2 / i1
// (length,fraction) (16,2)

///////////////////
wire [i_wide - 1:0] K;
assign K = (22'b0000100110101000111101) >> (18 - (i_wide - i_int)); // 0.60374807 (22,18)
///////////////////

parameter iter_sqrt = 13; // max: i_wide - i_int
parameter iter_div = 13; // max: i_wide - i_int
reg signed [i_wide - 1:0] x_r,y_r,x_w,y_w;
reg signed [i_wide - 1:0] z_r,z_w;
reg i_mode_r,i_mode_w;
reg [4:0] cnt_r,cnt_w;
wire di;
wire signed [i_wide -1:0] one;
reg [i_wide - 1:0] out_r,out_w;
reg [(i_wide << 1) - 1 : 0] mul_result;
wire [5:0] iteration;
reg special_delay_r,special_delay_w;

assign iteration = (i_mode_r) ? iter_sqrt : iter_div;
assign one = 1 << (i_wide - i_int);
assign di = (y_r[i_wide - 1]); // sign of -y -> 0: -, 1: +
assign o_out = out_r;
assign o_valid = (cnt_r == iteration + 2) ? 1 : 0;

// wire gclk_flag = i_valid | o_valid;
// wire gclk = i_clk & gclk_flag;

// combinational logic
always @(*) begin
    x_w = x_r;
    y_w = y_r;
    z_w = z_r;
    cnt_w = cnt_r;
    i_mode_w = i_mode_r;
    out_w = out_r;
    special_delay_w = special_delay_r;
    if (cnt_r == 0) begin
        if (i_valid) begin
            x_w = (i_mode) ? i1 + one : {i1,2'b0}                ; // x + 1 ; x * 4
            y_w = (i_mode) ? i1 - one : i2  ; // x - 1 ; sign extension
            cnt_w = 1;
            i_mode_w = i_mode;
        end else begin
            x_w = 0;
            y_w = 0;
            cnt_w = 0;
        end
    end else if (cnt_r <= iteration + 1) begin // cnt:  1 ~ iteration
        if (!i_mode_r) begin
            x_w = x_r;
        end else begin
            x_w = (di) ? (x_r + $signed(y_r >>> cnt_r)) : (x_r - $signed(y_r >>> cnt_r));
        end
        y_w = (di) ? (y_r + $signed(x_r >>> cnt_r)) : (y_r - $signed(x_r >>> cnt_r));
        z_w = (di) ? (z_r - $signed(one >>  cnt_r)) : (z_r + $signed(one >>  cnt_r));

        if (cnt_r == 4 || cnt_r == 13) begin
            if (i_mode_r && !special_delay_r) begin
                special_delay_w = 1;
                cnt_w = cnt_r;
            end else begin
                special_delay_w = 0;
                cnt_w = cnt_r + 1;
            end
        end else begin
            cnt_w = cnt_r + 1;
        end

    end else begin // reset
        x_w = 0;
        y_w = 0;
        z_w = 0;
        cnt_w = 0;
        special_delay_w = 0;
    end

    mul_result = x_r * K; // (18,14) * (18,14) = (36,28)
    out_w = (i_mode_r) ? mul_result[((i_wide << 1) - 1 - i_int) -: i_wide] : (z_r << 2); // (18,14)

end

// sequential
always @(posedge i_clk) begin
    x_r <= x_w;
    y_r <= y_w;
    z_r <= z_w;
    out_r <= out_w;
end

// always @(posedge gclk or posedge i_rst) begin
//     if (i_rst) begin
//         // x_r <= 0;
//         // y_r <= 0;
//         // z_r <= 0;
//         // out_r <= 0;
//     end else begin
//         // x_r <= x_w;
//         // y_r <= y_w;
//         // z_r <= z_w;
//         // out_r <= out_w;
//     end
// end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        // x_r <= 0;
        // y_r <= 0;
        // z_r <= 0;
        cnt_r <= 0;
        // out_r <= 0;
        i_mode_r <= 0;
        special_delay_r <= 0;
    end else begin
        // x_r <= x_w;
        // y_r <= y_w;
        // z_r <= z_w;
        cnt_r <= cnt_w;
        // out_r <= out_w;
        i_mode_r <= i_mode_w;
        special_delay_r <= special_delay_w;
    end
end


endmodule