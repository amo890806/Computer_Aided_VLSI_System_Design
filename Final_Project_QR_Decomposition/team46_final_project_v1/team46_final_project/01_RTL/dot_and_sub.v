module dot_and_sub
#(
    parameter i_int = 4, // bits of integer part of input
    parameter i_wide = 22,
    parameter o_int = 4, // bits of integer part of output
    parameter o_wide = 22,
    parameter o_dot_wide = 24
)
(
    input i_clk,
    input i_rst,
    input i_only_dot,
    input [(i_wide << 2) - 1:0] i_real1, // {R0,R1,R2,R3}
    input [(i_wide << 2) - 1:0] i_imag1, // {I0,I1,I2,I3}
    input [(i_wide << 2) - 1:0] i_real2,
    input [(i_wide << 2) - 1:0] i_imag2,
    input i_valid,
    output [(o_wide << 2) - 1:0] o_H_real,
    output [(o_wide << 2) - 1:0] o_H_imag,
    output [o_dot_wide - 1:0] o_dot_real, // dot or Rij
    output [o_dot_wide - 1:0] o_dot_imag,
    output o_valid
);
// perform dot operation and subtraction
// input: 2 vectors of 4 complex numbers , vector 1: q, vector 2: h
// output: 1 complex number result
//
integer i,j;
// parameter
parameter s_IDLE = 0;
parameter s_MUL = 1;
parameter s_EXPAND_Q = 2;
parameter s_SUB = 3;
parameter s_OUT = 4;
parameter pipe_delay = 2 + 1; // 

// input buffer 
reg [(i_wide << 2) - 1:0] i_real1_r,i_imag1_r,i_real1_w,i_imag1_w;
reg [(i_wide << 2) - 1:0] i_real2_r,i_imag2_r,i_real2_w,i_imag2_w;

// Q expansion buffer
// reg signed [i_wide - 1:0] Q_expand_real_r [0:3];
// reg signed [i_wide - 1:0] Q_expand_real_w [0:3];
// reg signed [i_wide - 1:0] Q_expand_imag_r [0:3];
// reg signed [i_wide - 1:0] Q_expand_imag_w [0:3];

// reg and wire
reg i_only_dot_r,i_only_dot_w;
reg [3:0] cnt_r,cnt_w;
reg [2:0] state_r,state_w;
wire [i_wide - 1:0] e0_real,e0_imag,e1_real,e1_imag;
wire signed [i_wide - 1:0] vec1_real [0:3]; ////////////////// modified
wire signed [i_wide - 1:0] vec1_imag [0:3];
wire signed [i_wide - 1:0] vec2_real [0:3];
wire signed [i_wide - 1:0] vec2_imag [0:3];
wire signed [i_wide + 1:0] mul_real,mul_imag;
reg  signed [o_dot_wide - 1:0] add_real_r,add_real_w,add_imag_r,add_imag_w;
wire signed [i_wide - 1:0] sub_real [0:3];
wire signed [i_wide - 1:0] sub_imag [0:3];

///// wire assignment
// vectorize input buffer

genvar k;
generate
for (k = 0; k < 4; k = k + 1) begin: vectorize_input_buffer
    assign vec1_real[k] = i_real1_r[((i_wide << 2) - 1 - k * i_wide) -: i_wide]; // {R0,R1,R2,R3}
    assign vec1_imag[k] = i_imag1_r[((i_wide << 2) - 1 - k * i_wide) -: i_wide]; // {I0,I1,I2,I3}
    assign vec2_real[k] = i_real2_r[((i_wide << 2) - 1 - k * i_wide) -: i_wide];
    assign vec2_imag[k] = i_imag2_r[((i_wide << 2) - 1 - k * i_wide) -: i_wide];
end
endgenerate
// multiplexer input
assign e0_real = vec1_real[cnt_r[1:0]]; // always Q vector
assign e0_imag = vec1_imag[cnt_r[1:0]];
assign e1_real = (state_r == s_MUL) ? vec2_real[cnt_r[1:0]] : add_real_r[i_wide - 1:0]; // R vector or dot * Q
assign e1_imag = (state_r == s_MUL) ? vec2_imag[cnt_r[1:0]] : add_imag_r[i_wide - 1:0];
// subtraction 
//wire overflow_sub[0:3];
generate
for (k = 0; k < 4; k = k + 1) begin: subtraction
    assign sub_real[k] = vec2_real[k] - vec1_real[k]; // H - expand(Q)
    assign sub_imag[k] = vec2_imag[k] - vec1_imag[k];
    //assign overflow_sub[k] = (vec2_real[k][i_wide - 1] != Q_expand_real_r[k][i_wide - 1]) && (sub_real[k][i_wide - 1] != vec2_real[k][i_wide - 1]);
end
endgenerate
// output
assign o_valid = (state_r == s_OUT);
assign o_H_real = i_real2_r;
assign o_H_imag = i_imag2_r;
assign o_dot_real = add_real_r;
assign o_dot_imag = add_imag_r;

// module
complex_mul_pipe2_fast
#(
    .i_int(i_int),
    .i_wide(i_wide),
    .o_int(i_int + 2), // 2 bit integer extension ////////////////// modified
    .o_wide(i_wide + 2)
)
c0
(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_valid(i_valid),
    .i_R0(e0_real),
    .i_I0(e0_imag),
    .i_R1(e1_real),
    .i_I1(e1_imag),
    .i_conjugate(state_r == s_MUL),
    .o_Rout(mul_real),
    .o_Iout(mul_imag)
);

// reg overflow_mul [0:1];

// wire gclk_flag = i_valid | o_valid;
// wire gclk = i_clk & gclk_flag;

// combinational logic
always @(*) begin
    state_w = state_r;
    cnt_w = cnt_r;
    add_real_w = add_real_r;
    add_imag_w = add_imag_r;
    i_real1_w = i_real1_r;
    i_imag1_w = i_imag1_r;
    i_real2_w = i_real2_r;
    i_imag2_w = i_imag2_r;
    i_only_dot_w = i_only_dot_r;
    // for (i = 0; i < 4; i = i + 1) begin
    //     Q_expand_real_w[i] = Q_expand_real_r[i];
    //     Q_expand_imag_w[i] = Q_expand_imag_r[i];
    // end

    case (state_r) // synopsys parallel_case
        s_IDLE: begin
            if (i_valid) begin
                i_real1_w = i_real1;
                i_imag1_w = i_imag1;
                i_real2_w = i_real2;
                i_imag2_w = i_imag2;
                i_only_dot_w = i_only_dot;
                state_w = s_MUL;
                cnt_w = 0;
            end
        end
        s_MUL: begin
            // dot adder
            if (cnt_r >= pipe_delay && cnt_r <= (3 + pipe_delay)) begin
                add_real_w = add_real_r + mul_real;
                add_imag_w = add_imag_r + mul_imag;
            end
            // check overflow
            // overflow_mul[0] = (mul_real[i_wide + 1] == add_real_r[i_wide + 1]) && (add_real_w[i_wide + 1] != mul_real[i_wide + 1]);
            // overflow_mul[1] = (mul_imag[i_wide + 1] == add_imag_r[i_wide + 1]) && (add_imag_w[i_wide + 1] != mul_imag[i_wide + 1]);

            if (cnt_r < (3 + pipe_delay)) begin
                cnt_w = cnt_r + 1;
                state_w = s_MUL;
            end
            else begin
                cnt_w = 0;
                state_w = (i_only_dot_r) ? s_OUT : s_EXPAND_Q;
            end
        end
        s_EXPAND_Q: begin
            // update Q expansion buffer
            if (cnt_r >= pipe_delay && cnt_r <= (3 + pipe_delay)) begin
                // Q_expand_real_w[cnt_r - pipe_delay] = mul_real;
                i_real1_w[((i_wide << 2) - 1 - (cnt_r-pipe_delay) * i_wide) -: i_wide] = mul_real;
                // Q_expand_imag_w[cnt_r - pipe_delay] = mul_imag;
                i_imag1_w[((i_wide << 2) - 1 - (cnt_r-pipe_delay) * i_wide) -: i_wide] = mul_imag;
            end

            if (cnt_r < (3 + pipe_delay)) begin
                cnt_w = cnt_r + 1;
                state_w = s_EXPAND_Q;
            end
            else begin
                cnt_w = 0;
                state_w = s_SUB;
            end
        end
        s_SUB: begin
            // update vector 2 buffer (H buffer)
            i_real2_w = {sub_real[0],sub_real[1],sub_real[2],sub_real[3]};
            i_imag2_w = {sub_imag[0],sub_imag[1],sub_imag[2],sub_imag[3]};
            state_w = s_OUT;
        end
        s_OUT: begin
            state_w = s_IDLE;
            add_imag_w = 0;
            add_real_w = 0;
        end
        default: begin
            state_w = s_IDLE;
            add_imag_w = 0;
            add_real_w = 0;
        end
    endcase
end

// sequential logic
always @(posedge i_clk) begin
    i_real1_r <= i_real1_w;
    i_imag1_r <= i_imag1_w;
    i_real2_r <= i_real2_w;
    i_imag2_r <= i_imag2_w;
    i_only_dot_r <= i_only_dot_w;
    // for (i = 0; i < 4; i = i + 1) begin
    //     Q_expand_real_r[i] <= Q_expand_real_w[i];
    //     Q_expand_imag_r[i] <= Q_expand_imag_w[i];
    // end
end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        add_real_r <= 0;
        add_imag_r <= 0;
        // i_real1_r <= 0;
        // i_imag1_r <= 0;
        // i_real2_r <= 0;
        // i_imag2_r <= 0;
        // i_only_dot_r <= 0;
        // for (i = 0; i < 4; i = i + 1) begin
        //     Q_expand_real_r[i] <= 0;
        //     Q_expand_imag_r[i] <= 0;
        // end
    end
    else begin
        add_real_r <= add_real_w;
        add_imag_r <= add_imag_w;
        // i_real1_r <= i_real1_w;
        // i_imag1_r <= i_imag1_w;
        // i_real2_r <= i_real2_w;
        // i_imag2_r <= i_imag2_w;
        // i_only_dot_r <= i_only_dot_w;
        // for (i = 0; i < 4; i = i + 1) begin
        //     Q_expand_real_r[i] <= Q_expand_real_w[i];
        //     Q_expand_imag_r[i] <= Q_expand_imag_w[i];
        // end
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r <= 0;
        cnt_r <= 0;
        // add_real_r <= 0;
        // add_imag_r <= 0;
        // i_real1_r <= 0;
        // i_imag1_r <= 0;
        // i_real2_r <= 0;
        // i_imag2_r <= 0;
        // i_only_dot_r <= 0;
        // for (i = 0; i < 4; i = i + 1) begin
        //     Q_expand_real_r[i] <= 0;
        //     Q_expand_imag_r[i] <= 0;
        // end
    end
    else begin
        state_r <= state_w;
        cnt_r <= cnt_w;
        // add_real_r <= add_real_w;
        // add_imag_r <= add_imag_w;
        // i_real1_r <= i_real1_w;
        // i_imag1_r <= i_imag1_w;
        // i_real2_r <= i_real2_w;
        // i_imag2_r <= i_imag2_w;
        // i_only_dot_r <= i_only_dot_w;
        // for (i = 0; i < 4; i = i + 1) begin
        //     Q_expand_real_r[i] <= Q_expand_real_w[i];
        //     Q_expand_imag_r[i] <= Q_expand_imag_w[i];
        // end
    end
end
endmodule