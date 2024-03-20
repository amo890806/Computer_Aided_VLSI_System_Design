module normalizer
#(
    parameter i_int = 2, // bits of integer part of input
    parameter i_wide = 20,
    parameter i_length_int = 4,
    parameter i_length_wide = 22,
    parameter o_int = 2, // bits of integer part of output
    parameter o_wide = 20
)
(
    input i_clk,
    input i_rst,
    input [i_length_wide - 1:0] i_length,
    input [(i_wide << 2) - 1:0] i_real,
    input [(i_wide << 2) - 1:0] i_imag,
    input i_valid,
    output [(o_wide << 2) - 1:0] o_real,
    output [(o_wide << 2) - 1:0] o_imag,
    output [19 : 0] o_Rii,
    output o_valid
);

// (length,fraction)
parameter acc_frac_comp = 16 - (i_wide - i_int);
integer i,j;
// parameter
parameter s_IDLE = 0;
parameter s_SQRT = 1;
parameter s_DIV = 2;
parameter s_OUT = 3;
parameter pipe_sqrt = 18;
parameter pipe_div = 18;

// input buffer 
reg [(i_wide << 2) - 1:0] i_real_r,i_imag_r,i_real_w,i_imag_w;
reg [i_length_wide - 1:0] i_length_r,i_length_w;
reg [i_length_wide - 1:0] length_sqrt_r,length_sqrt_w;
reg [o_wide - 1: 0] div_result_real_r [0:3];
reg [o_wide - 1: 0] div_result_imag_r [0:3];
reg [o_wide - 1: 0] div_result_real_w [0:3];
reg [o_wide - 1: 0] div_result_imag_w [0:3];

// reg and wire
reg [5:0] cnt_r,cnt_w;
reg [1:0] state_r,state_w;

/*
wire [5:0] cnt_out;
assign cnt_out = cnt_r - (pipe_div - 1);
*/

// vectorize input buffer
wire [i_wide - 1:0] vec_real [0:3];
wire [i_wide - 1:0] vec_imag [0:3];

genvar k;
generate
for (k = 0; k < 4; k = k + 1) begin: gen_vec
    assign vec_real[k] = i_real_r[((i_wide << 2) - 1 - k * i_wide) -: i_wide]; // {R0,R1,R2,R3}
    assign vec_imag[k] = i_imag_r[((i_wide << 2) - 1 - k * i_wide) -: i_wide]; // {I0,I1,I2,I3}
end
endgenerate
// assign output
assign o_real = {div_result_real_r[0],div_result_real_r[1],div_result_real_r[2],div_result_real_r[3]};
assign o_imag = {div_result_imag_r[0],div_result_imag_r[1],div_result_imag_r[2],div_result_imag_r[3]};
assign o_Rii = {length_sqrt_r[i_length_wide - 1 -(i_length_int - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}}; // unsigned
assign o_valid = (state_r == s_OUT);

// module sqrt
/*
wire [((i_length_wide + 1) >> 1) - 1 :0] sqrt_real; // unsigned
DW_sqrt_pipe_inst 
#(
    .inst_width  (i_length_wide),
    .inst_tc_mode  (1),
    .inst_num_stages  (pipe_sqrt),
    .inst_stall_mode  (0), // 
    .inst_rst_mode  (1),
    .inst_op_iso_mode  (0)
) 
sqrt_inst
(
    .inst_clk(i_clk),
    .inst_rst_n(!i_rst), //negedge reset
    .inst_en(1'b1), 
    .inst_a(i_length_r), // (22,18)
    .root_inst(sqrt_real) // (11,9)
);
*/
reg cord_start;
wire [i_wide - 1: 0] div_input;
wire [i_length_wide - 1 : 0]  cord_input1,cord_input2;
wire [i_length_wide - 1 : 0]  cord_result; 
wire cord_finish;
assign cord_input1 = (state_r == s_SQRT) ? i_length_r : length_sqrt_r;
assign div_input = (!cnt_r[0]) ? {vec_real[cnt_r[2:1]]} : {vec_imag[cnt_r[2:1]]}; // (20,18)
assign cord_input2 = {{{2{div_input[i_wide-1]}},div_input}}; // sign extension
cordic #(
    .i_int (i_length_int),
    .i_wide (i_length_wide)
) c0
(
    .i_clk (i_clk),
    .i_rst (i_rst),
    .i_en (1'b1),
    .i_mode (state_r == s_SQRT),
    .i1 (cord_input1), //(22,18)
    .i2 (cord_input2), //(22,18)
    .i_valid (cord_start),
    .o_out (cord_result), //(22,18)
    .o_valid (cord_finish)
);

// module div

/*
wire [i_wide - 1 :0] div_result; //(20,9)
wire [i_wide - 1 :0] div_input;
wire [10 :0] div_remainder;
wire divide_by_0;
assign div_input = (!cnt_r[0]) ? {vec_real[cnt_r[2:1]]} : {vec_imag[cnt_r[2:1]]}; // (20,18)
DW_div_pipe_inst
#(
    .inst_a_width (i_wide),
    .inst_b_width (((i_length_wide + 1) >> 1)), //(11,9)
    .inst_tc_mode (1), // 2's complement
    .inst_rem_mode (1),
    .inst_num_stages (pipe_div),
    .inst_stall_mode (1),
    .inst_rst_mode (1),
    .inst_op_iso_mode (0)
)
div_inst
(
    .inst_clk(i_clk),
    .inst_rst_n(!i_rst),
    .inst_en(state_r == s_DIV),
    .inst_a(div_input),
    .inst_b(length_sqrt_r),
    .quotient_inst(div_result),
    .remainder_inst(div_remainder), //not used
    .divide_by_0_inst(divide_by_0) //not used
);
*/
wire sticky_bit;
assign sticky_bit = (cord_result[3] || cord_result[2] || cord_result[1] || cord_result[0]);

wire gclk = i_clk & i_valid;

// combinatorial logic
always @(*) begin
    state_w = state_r;
    i_real_w = i_real_r;
    i_imag_w = i_imag_r;
    i_length_w = i_length_r;
    length_sqrt_w = length_sqrt_r;
    cnt_w = cnt_r;
    cord_start = 0;
    for (i = 0; i < 4; i = i + 1) begin
        div_result_real_w[i] = div_result_real_r[i];
        div_result_imag_w[i] = div_result_imag_r[i];
    end
    case (state_r)
        s_IDLE: begin
            cnt_w = 0;
            if (i_valid) begin
                i_real_w = i_real;
                i_imag_w = i_imag;
                i_length_w = i_length;
                state_w = s_SQRT;
            end
        end
        s_SQRT: begin
            if (cord_finish) begin
                length_sqrt_w = cord_result; 
                state_w = s_DIV;
            end else begin
                cord_start = 1;
                state_w = s_SQRT;
            end
        end
        s_DIV: begin

            if (cord_finish) begin
                if (!cnt_r[0])
                    div_result_real_w[cnt_r[2:1]] = cord_result[i_length_wide - 1 - (i_length_int - o_int) -: o_wide];
                else 
                    div_result_imag_w[cnt_r[2:1]] = cord_result[i_length_wide - 1 - (i_length_int - o_int) -: o_wide];
                
                if (cnt_r == 7) begin
                    cnt_w = 0;
                    state_w = s_OUT;
                end else begin
                    cnt_w = cnt_r + 1;
                    state_w = s_DIV;
                end
            end else begin
                cord_start = 1; 
                state_w = s_DIV;
            end
            
        end
        s_OUT: begin
            state_w = s_IDLE;
            cnt_w = 0;

        end
        default: begin
            cnt_w = 0;
            state_w = state_r;
        end
    endcase
end

// sequential logic
always @(posedge i_clk) begin
    i_real_r <= i_real_w;
    i_imag_r <= i_imag_w;
    i_length_r <= i_length_w;
    length_sqrt_r <= length_sqrt_w;
    for (i = 0; i < 4; i = i + 1) begin
        div_result_real_r[i] <= div_result_real_w[i];
        div_result_imag_r[i] <= div_result_imag_w[i];
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        cnt_r <= 0;
        state_r <= s_IDLE;
        // i_real_r <= 0;
        // i_imag_r <= 0;
        // i_length_r <= 0;
        // length_sqrt_r <= 0;
        // for (i = 0; i < 4; i = i + 1) begin
        //     div_result_real_r[i] <= 0;
        //     div_result_imag_r[i] <= 0;
        // end
    end
    else begin
        cnt_r <= cnt_w;
        state_r <= state_w;
        // i_real_r <= i_real_w;
        // i_imag_r <= i_imag_w;
        // i_length_r <= i_length_w;
        // length_sqrt_r <= length_sqrt_w;
        // for (i = 0; i < 4; i = i + 1) begin
        //     div_result_real_r[i] <= div_result_real_w[i];
        //     div_result_imag_r[i] <= div_result_imag_w[i];
        // end
    end
end

endmodule

// module DW_sqrt_pipe_inst
// #(parameter inst_width = 22,
//   parameter inst_tc_mode = 0,
//   parameter inst_num_stages = 5,
//   parameter inst_stall_mode = 0, // don't need to pause
//   parameter inst_rst_mode = 1,
//   parameter inst_op_iso_mode = 0
// )
// ( inst_clk, inst_rst_n, inst_en, inst_a, root_inst );
  
//   input inst_clk;
//   input inst_rst_n;
//   input inst_en;
//   input [inst_width-1 : 0] inst_a;
//   output [(inst_width+1)/2-1 : 0] root_inst;

//   // Instance of DW_sqrt_pipe
//   DW_sqrt_pipe #(inst_width, inst_tc_mode, inst_num_stages, 
//                  inst_stall_mode, inst_rst_mode, inst_op_iso_mode) 
//     U1 (.clk(inst_clk),   .rst_n(inst_rst_n),
//         .en(inst_en),   .a(inst_a),   .root(root_inst) );
// endmodule

// module DW_div_pipe_inst
// #(parameter inst_a_width = 20,
//   parameter inst_b_width = 20,
//   parameter inst_tc_mode = 0,
//   parameter inst_rem_mode = 1,
//   parameter inst_num_stages = 5,
//   parameter inst_stall_mode = 0,
//   parameter inst_rst_mode = 1,
//   parameter inst_op_iso_mode = 0
// )
// (inst_clk, inst_rst_n, inst_en, inst_a, inst_b, quotient_inst, remainder_inst, divide_by_0_inst );
//   input inst_clk;
//   input inst_rst_n;
//   input inst_en;
//   input [inst_a_width-1 : 0] inst_a;
//   input [inst_b_width-1 : 0] inst_b;
//   output [inst_a_width-1 : 0] quotient_inst;
//   output [inst_b_width-1 : 0] remainder_inst;
//   output divide_by_0_inst;

//   // Instance of DW_div_pipe
//   DW_div_pipe #(inst_a_width,   inst_b_width,   inst_tc_mode,  inst_rem_mode,
//                 inst_num_stages,   inst_stall_mode,   inst_rst_mode,   inst_op_iso_mode) 
//     U1 (.clk(inst_clk),   .rst_n(inst_rst_n),   .en(inst_en),
//         .a(inst_a),   .b(inst_b),   .quotient(quotient_inst),
//         .remainder(remainder_inst),   .divide_by_0(divide_by_0_inst) );
// endmodule