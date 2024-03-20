
module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
integer i;

reg [3:0] i_op_mode_r, i_op_mode_w;
wire [7:0] i_in_data_w;
reg i_in_valid_r;
wire i_in_valid_w;
reg o_in_ready_r;
wire o_in_ready_w;
wire o_op_ready_w;
reg [13:0] o_out_data_r, o_out_data_w;
reg o_out_valid_r, o_out_valid_w;

reg [5:0] state, n_state;
reg [2:0] x_cnt_r, x_cnt_w;
reg [2:0] y_cnt_r, y_cnt_w;
reg [4:0] d_cnt_r, d_cnt_w;
reg [1:0] ch_enc_r, ch_enc_w;
reg [4:0] ch_dec_w;
reg [4:0] dly_cnt_r, dly_cnt_w;

reg [10:0] addr_w, addr_r, addr_dly_r;
reg [7:0] A0_w, A1_w, A2_w, A3_w, A4_w, A5_w, A6_w, A7_w;
reg WEN0_w, WEN1_w, WEN2_w, WEN3_w, WEN4_w, WEN5_w, WEN6_w, WEN7_w;
wire [7:0] Q0_w, Q1_w, Q2_w, Q3_w, Q4_w, Q5_w, Q6_w, Q7_w;
reg [7:0] Q0_r, Q1_r, Q2_r, Q3_r, Q4_r, Q5_r, Q6_r, Q7_r;
wire [2:0] x_cnt_m1_w, x_cnt_p1_w, x_cnt_p2_w, y_cnt_m1_w, y_cnt_p1_w, y_cnt_p2_w;
wire [2:0] x_ref, y_ref, y_ref_inv;

reg [7:0] kernel_r [0:15];
reg [7:0] kernel_w [0:15];
reg [7:0] kernel_tmp_w [0:7];
reg [7:0] kernel_zp_w [0:7];
wire x_left_bnd, x_right_bnd, y_up_bnd, y_down_bnd;

reg [7:0] in_0_0_w, in_1_0_w, in_2_0_w, in_3_0_w, in_4_0_w, in_5_0_w, in_6_0_w, in_7_0_w, in_8_0_w;
reg [7:0] in_0_1_w, in_1_1_w, in_2_1_w, in_3_1_w, in_4_1_w, in_5_1_w, in_6_1_w, in_7_1_w, in_8_1_w;
reg [7:0] in_0_r [0:8];
reg [7:0] in_1_r [0:8];

// reg [7:0] add_0_0_w, add_1_0_w, add_2_0_w, add_3_0_w, add_4_0_w, add_5_0_w, add_6_0_w, add_7_0_w, add_8_0_w; 
// reg [7:0] add_0_1_w, add_1_1_w, add_2_1_w, add_3_1_w, add_4_1_w, add_5_1_w, add_6_1_w, add_7_1_w, add_8_1_w; 
wire [9:0] add_0123_0_w, add_4567_0_w;
wire [9:0] add_0123_1_w, add_4567_1_w;

reg [9:0] add_0123_0_r, add_4567_0_r;
reg [9:0] add_0123_1_r, add_4567_1_r;
wire [7:0] add_sh2_0_w, add_sh2_1_w;
reg [7:0] add_sh2_0_r, add_sh2_1_r;
wire [9:0] add_sh4_0_w, add_sh4_1_w;
reg [9:0] add_sh4_0_r, add_sh4_1_r;
wire [9:0] add_sh3_0_w, add_sh3_1_w;
reg [9:0] add_sh3_0_r, add_sh3_1_r;
wire [11:0] add_result_0_w, add_result_1_w;
reg [11:0] add_result_0_r, add_result_1_r;
reg [16:0] conv_result_0_w, conv_result_1_w, conv_result_2_w, conv_result_3_w;
reg [16:0] conv_result_0_r, conv_result_1_r, conv_result_2_r, conv_result_3_r;
reg acc_flag_r;
wire acc_flag_w;
wire [13:0] conv_rnd_result_0_w, conv_rnd_result_1_w, conv_rnd_result_2_w, conv_rnd_result_3_w;

reg fetch_flag_w, fetch_flag_r;

wire signed [10:0] neg_sobel_0_w, pos_sobel_0_w, neg_sobel_1_w, pos_sobel_1_w;
// reg signed [9:0] neg_sobel_0_r, pos_sobel_0_r, neg_sobel_1_r, pos_sobel_1_r;
wire [11:0] gradient_0_w, gradient_1_w;
reg [11:0] gradient_0_r, gradient_1_r;
reg signed [11:0] gx_0_r, gx_1_r, gx_2_r, gx_3_r;	// 1 bit is for signed bit
reg signed [11:0] gx_0_w, gx_1_w, gx_2_w, gx_3_w;
reg signed [11:0] gy_0_r, gy_1_r, gy_2_r, gy_3_r;
reg signed [11:0] gy_0_w, gy_1_w, gy_2_w, gy_3_w;
wire [11:0] abs_gx_0_w, abs_gx_1_w, abs_gx_2_w, abs_gx_3_w;
wire [11:0] abs_gy_0_w, abs_gy_1_w, abs_gy_2_w, abs_gy_3_w;
reg gx_flag_r, gy_flag_r;
wire gx_flag_w, gy_flag_w;
reg [11:0] g0_r, g1_r, g2_r, g3_r;
reg [11:0] g0_w, g1_w, g2_w, g3_w;

reg signed [11:0] curr_gx_w, curr_gy_w, curr_gx_r, curr_gy_r; 
wire signed [11:0] curr_gx_rsh2_w, curr_gx_rsh3_w, curr_gx_rsh5_w, curr_gx_rsh7_w;
wire signed [12:0] curr_gx_lsh1_w;
wire signed [13:0] gx_tan22p5_w;
reg signed [13:0] gx_tan22p5_r;
wire signed [14:0] gx_tan67p5_w;
reg signed [14:0] gx_tan67p5_r;
wire signed [13:0] neg_gx_tan22p5_w;
reg signed [13:0] neg_gx_tan22p5_r;
wire signed [14:0] neg_gx_tan67p5_w;
reg signed [14:0] neg_gx_tan67p5_r;

reg [11:0] cpr0_grad_w, cpr45_grad_w, cpr90_grad_w, cpr135_grad_w;
reg nms_mask_r, nms_mask_w;
wire cpr0_flag_w, cpr45_flag_w, cpr90_flag_w, cpr135_flag_w;
reg cpr0_flag_r, cpr45_flag_r, cpr90_flag_r, cpr135_flag_r;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign i_in_valid_w = i_in_valid;
assign i_op_mode_w = (i_op_valid) ? i_op_mode : i_op_mode_r;
assign i_in_data_w = i_in_data;
assign o_op_ready_w = (state == 1);
assign o_in_ready_w = (state == 4);
assign o_in_ready = o_in_ready_r;
assign o_op_ready = o_op_ready_w;
assign o_out_data = o_out_data_r;
assign o_out_valid = o_out_valid_r;

assign x_cnt_m1_w = x_cnt_r - 1;
assign x_cnt_p1_w = x_cnt_r + 1;
assign x_cnt_p2_w = x_cnt_r + 2;
assign y_cnt_m1_w = y_cnt_r - 1;
assign y_cnt_p1_w = y_cnt_r + 1;
assign y_cnt_p2_w = y_cnt_r + 2;

assign x_ref = x_cnt_m1_w;
assign y_ref = (state == 17) ? y_cnt_p1_w : y_cnt_m1_w;
assign y_ref_inv = (state == 32) ? y_cnt_p1_w : y_cnt_m1_w;

assign x_left_bnd = x_cnt_r == 0;
assign x_right_bnd = x_cnt_r == 6;
assign y_up_bnd = y_cnt_r == 0;
assign y_down_bnd = y_cnt_r == 6;

// assign add_0123_0_w = add_0_0_w + add_1_0_w + add_2_0_w + add_3_0_w;
// assign add_4567_0_w = add_4_0_w + add_5_0_w + add_6_0_w + add_7_0_w;
wire [9:0] add_x_0123_0_w, add_x_4567_0_w, add_x_0123_1_w, add_x_4567_1_w;
wire [9:0] add_y_0123_0_w, add_y_4567_0_w, add_y_0123_1_w, add_y_4567_1_w;
assign add_0123_0_w = (state == 19) ? add_y_0123_0_w : add_x_0123_0_w;
assign add_4567_0_w = (state == 19) ? add_y_4567_0_w : add_x_4567_0_w;
assign add_sh4_0_w = in_0_r[0] + in_0_r[2] + in_0_r[6] + in_0_r[8];
assign add_sh3_0_w = in_0_r[1] + in_0_r[3] + in_0_r[5] + in_0_r[7];
assign add_sh2_0_w = in_0_r[4];
assign add_result_0_w = add_sh4_0_r + {add_sh3_0_r, 1'b0} + {add_sh2_0_r, 2'b0};

// assign add_0123_1_w = add_0_1_w + add_1_1_w + add_2_1_w + add_3_1_w;
// assign add_4567_1_w = add_4_1_w + add_5_1_w + add_6_1_w + add_7_1_w;
assign add_0123_1_w = (state == 19) ? add_y_0123_1_w : add_x_0123_1_w;
assign add_4567_1_w = (state == 19) ? add_y_4567_1_w : add_x_4567_1_w;
assign add_sh4_1_w = in_1_r[0] + in_1_r[2] + in_1_r[6] + in_1_r[8];
assign add_sh3_1_w = in_1_r[1] + in_1_r[3] + in_1_r[5] + in_1_r[7];
assign add_sh2_1_w = in_1_r[4];
assign add_result_1_w = add_sh4_1_r + {add_sh3_1_r, 1'b0} + {add_sh2_1_r, 2'b0};

assign acc_flag_w = state == 12 && dly_cnt_r == 1;

assign conv_rnd_result_0_w = conv_result_0_r[16:4] + conv_result_0_r[3];
assign conv_rnd_result_1_w = conv_result_1_r[16:4] + conv_result_1_r[3];
assign conv_rnd_result_2_w = conv_result_2_r[16:4] + conv_result_2_r[3];
assign conv_rnd_result_3_w = conv_result_3_r[16:4] + conv_result_3_r[3];

assign add_x_0123_0_w = in_0_r[0] + {in_0_r[3], 1'b0} + in_0_r[6];
assign add_x_4567_0_w = in_0_r[2] + {in_0_r[5], 1'b0} + in_0_r[8];
assign add_y_0123_0_w = in_0_r[0] + {in_0_r[1], 1'b0} + in_0_r[2];
assign add_y_4567_0_w = in_0_r[6] + {in_0_r[7], 1'b0} + in_0_r[8];
assign add_x_0123_1_w = in_1_r[0] + {in_1_r[3], 1'b0} + in_1_r[6];
assign add_x_4567_1_w = in_1_r[2] + {in_1_r[5], 1'b0} + in_1_r[8];
assign add_y_0123_1_w = in_1_r[0] + {in_1_r[1], 1'b0} + in_1_r[2];
assign add_y_4567_1_w = in_1_r[6] + {in_1_r[7], 1'b0} + in_1_r[8];

assign neg_sobel_0_w = add_0123_0_r;
assign pos_sobel_0_w = add_4567_0_r;
assign neg_sobel_1_w = add_0123_1_r;
assign pos_sobel_1_w = add_4567_1_r;
assign gradient_0_w = pos_sobel_0_w - neg_sobel_0_w;
assign gradient_1_w = pos_sobel_1_w - neg_sobel_1_w;

assign gx_flag_w = state == 18 && dly_cnt_r == 1;
assign gy_flag_w = state == 19 && dly_cnt_r == 1;

assign abs_gx_0_w = (gx_0_r < 0) ? ~(gx_0_r)+1 : gx_0_r;
assign abs_gx_1_w = (gx_1_r < 0) ? ~(gx_1_r)+1 : gx_1_r;
assign abs_gx_2_w = (gx_2_r < 0) ? ~(gx_2_r)+1 : gx_2_r;
assign abs_gx_3_w = (gx_3_r < 0) ? ~(gx_3_r)+1 : gx_3_r;
assign abs_gy_0_w = (gy_0_r < 0) ? ~(gy_0_r)+1 : gy_0_r;
assign abs_gy_1_w = (gy_1_r < 0) ? ~(gy_1_r)+1 : gy_1_r;
assign abs_gy_2_w = (gy_2_r < 0) ? ~(gy_2_r)+1 : gy_2_r;
assign abs_gy_3_w = (gy_3_r < 0) ? ~(gy_3_r)+1 : gy_3_r;

assign curr_gx_lsh1_w = curr_gx_r <<< 1;
assign curr_gx_rsh2_w = curr_gx_r >>> 2;
assign curr_gx_rsh3_w = curr_gx_r >>> 3;
assign curr_gx_rsh5_w = curr_gx_r >>> 5;
assign curr_gx_rsh7_w = curr_gx_r >>> 7;
assign gx_tan22p5_w = curr_gx_rsh2_w + curr_gx_rsh3_w + curr_gx_rsh5_w + curr_gx_rsh7_w;
assign gx_tan67p5_w = gx_tan22p5_w + curr_gx_lsh1_w;
assign neg_gx_tan22p5_w = ~(gx_tan22p5_r)+1;
assign neg_gx_tan67p5_w = ~(gx_tan67p5_r)+1;

// assign cpr0_flag_w = (curr_gx_w < 0) ? (neg_gx_tan22p5_w>=curr_gy_w && curr_gy_w>gx_tan22p5_w) : (neg_gx_tan22p5_w<=curr_gy_w && curr_gy_w<gx_tan22p5_w);
// assign cpr45_flag_w = (curr_gx_w < 0) ? (gx_tan22p5_w>=curr_gy_w && curr_gy_w>gx_tan67p5_w) : (gx_tan22p5_w<=curr_gy_w && curr_gy_w<gx_tan67p5_w);
// assign cpr90_flag_w = (curr_gx_w < 0) ? (gx_tan67p5_w>=curr_gy_w || curr_gy_w>neg_gx_tan67p5_w) : (gx_tan67p5_w<=curr_gy_w || curr_gy_w<neg_gx_tan67p5_w);
// assign cpr135_flag_w = (curr_gx_w < 0) ? (neg_gx_tan67p5_w>=curr_gy_w && curr_gy_w>neg_gx_tan22p5_w) : (neg_gx_tan67p5_w<=curr_gy_w && curr_gy_w<neg_gx_tan22p5_w);
assign cpr0_flag_w = (curr_gx_r < 0) ? (neg_gx_tan22p5_r>=curr_gy_r && curr_gy_r>gx_tan22p5_r) : (neg_gx_tan22p5_r<=curr_gy_r && curr_gy_r<gx_tan22p5_r);
assign cpr45_flag_w = (curr_gx_r < 0) ? (gx_tan22p5_r>=curr_gy_r && curr_gy_r>gx_tan67p5_r) : (gx_tan22p5_r<=curr_gy_r && curr_gy_r<gx_tan67p5_r);
assign cpr90_flag_w = (curr_gx_r < 0) ? (gx_tan67p5_r>=curr_gy_r || curr_gy_r>neg_gx_tan67p5_r) : (gx_tan67p5_r<=curr_gy_r || curr_gy_r<neg_gx_tan67p5_r);
assign cpr135_flag_w = (curr_gx_r < 0) ? (neg_gx_tan67p5_r>=curr_gy_r && curr_gy_r>neg_gx_tan22p5_r) : (neg_gx_tan67p5_r<=curr_gy_r && curr_gy_r<neg_gx_tan22p5_r);
// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always @(*) begin
	nms_mask_w = nms_mask_r;
	if(state == 20)begin	//nms_mask_w[0] logic
		if(cpr0_flag_r)begin
			nms_mask_w = g0_r < cpr0_grad_w;
		end
		else if(cpr45_flag_r)begin
			nms_mask_w = g0_r < cpr45_grad_w;
		end
		else if(cpr90_flag_r)begin
			nms_mask_w = g0_r < cpr90_grad_w;
		end
		else begin
			nms_mask_w = 0;
		end
	end
	else if(state == 23)begin	//nms_mask_w[1] logic
		if(cpr0_flag_r)begin
			nms_mask_w = g1_r < cpr0_grad_w;
		end
		else if(cpr90_flag_r)begin
			nms_mask_w = g1_r < cpr90_grad_w;
		end
		else if(cpr135_flag_r)begin
			nms_mask_w = g1_r < cpr135_grad_w;
		end
		else begin
			nms_mask_w = 0;
		end
	end
	else if(state == 24)begin
		if(cpr0_flag_r)begin
			nms_mask_w = g2_r < cpr0_grad_w;
		end
		else if(cpr90_flag_r)begin
			nms_mask_w = g2_r < cpr90_grad_w;
		end
		else if(cpr135_flag_r)begin
			nms_mask_w = g2_r < cpr135_grad_w;
		end
		else begin
			nms_mask_w = 0;
		end
	end
	else if(state == 25)begin
		if(cpr0_flag_r)begin
			nms_mask_w = g3_r < cpr0_grad_w;
		end
		else if(cpr45_flag_r)begin
			nms_mask_w = g3_r < cpr45_grad_w;
		end
		else if(cpr90_flag_r)begin
			nms_mask_w = g3_r < cpr90_grad_w;
		end
		else begin
			nms_mask_w = 0;
		end
	end
	else if(state == 7)begin
		nms_mask_w = 0;
	end
end

always @(*) begin
	curr_gx_w = curr_gx_r;
	if(state == 20)begin
		curr_gx_w = gx_0_r;
	end
	else if(state == 23)begin
		curr_gx_w = gx_1_r;
	end
	else if(state == 24)begin
		curr_gx_w = gx_2_r;
	end
	else if(state == 25)begin
		curr_gx_w = gx_3_r;
	end
end

always @(*) begin
	curr_gy_w = curr_gy_r;
	if(state == 20)begin
		curr_gy_w = gy_0_r;
	end
	else if(state == 23)begin
		curr_gy_w = gy_1_r;
	end
	else if(state == 24)begin
		curr_gy_w = gy_2_r;
	end
	else if(state == 25)begin
		curr_gy_w = gy_3_r;
	end
end

always @(*) begin
	cpr0_grad_w = g1_r;
	cpr45_grad_w = g3_r;
	cpr90_grad_w = g2_r;
	cpr135_grad_w = g0_r;
	if(state == 23)begin
		cpr0_grad_w = g0_r;
		cpr45_grad_w = g1_r;
		cpr90_grad_w = g3_r;
		cpr135_grad_w = g2_r;
	end
	else if(state == 24)begin
		cpr0_grad_w = g3_r;
		cpr45_grad_w = g2_r;
		cpr90_grad_w = g0_r;
		cpr135_grad_w = g1_r;
	end
	else if(state == 25)begin
		cpr0_grad_w = g2_r;
		cpr45_grad_w = g0_r;
		cpr90_grad_w = g1_r;
		cpr135_grad_w = g3_r;
	end
end

always @(*) begin
	g0_w = g0_r;
	g1_w = g1_r;
	g2_w = g2_r;
	g3_w = g3_r;
	if(state == 33)begin
		g0_w = abs_gx_0_w + abs_gy_0_w;
		g1_w = abs_gx_1_w + abs_gy_1_w;
		g2_w = abs_gx_2_w + abs_gy_2_w;
		g3_w = abs_gx_3_w + abs_gy_3_w;
	end
end

always @(*) begin
	gx_0_w = gx_0_r;
	gx_1_w = gx_1_r;
	gx_2_w = gx_2_r;
	gx_3_w = gx_3_r;
	if(gx_flag_r)begin
		if(fetch_flag_r)begin
			gx_2_w = gradient_0_r;
			gx_3_w = gradient_1_r;
		end
		else begin
			gx_0_w = gradient_0_r;
			gx_1_w = gradient_1_r;
		end
	end
end

always @(*) begin
	gy_0_w = gy_0_r;
	gy_1_w = gy_1_r;
	gy_2_w = gy_2_r;
	gy_3_w = gy_3_r;
	if(gy_flag_r)begin
		if(fetch_flag_r)begin
			gy_2_w = gradient_0_r;
			gy_3_w = gradient_1_r;
		end
		else begin
			gy_0_w = gradient_0_r;
			gy_1_w = gradient_1_r;
		end
	end
end

// always @(*) begin
// 	add_0_0_w = in_0_r[0];
// 	add_1_0_w = in_0_r[3];
// 	add_2_0_w = in_0_r[3];
// 	add_3_0_w = in_0_r[6];
// 	add_4_0_w = in_0_r[2];
// 	add_5_0_w = in_0_r[5];
// 	add_6_0_w = in_0_r[5];
// 	add_7_0_w = in_0_r[8];
// 	add_8_0_w = in_0_r[4];
// 	if(state == 19)begin
// 		add_0_0_w = in_0_r[0];
// 		add_1_0_w = in_0_r[1];
// 		add_2_0_w = in_0_r[1];
// 		add_3_0_w = in_0_r[2];
// 		add_4_0_w = in_0_r[6];
// 		add_5_0_w = in_0_r[7];
// 		add_6_0_w = in_0_r[7];
// 		add_7_0_w = in_0_r[8];
// 		add_8_0_w = in_0_r[4];
// 	end
// end

// always @(*) begin
// 	add_0_1_w = in_1_r[0];
// 	add_1_1_w = in_1_r[3];
// 	add_2_1_w = in_1_r[3];
// 	add_3_1_w = in_1_r[6];
// 	add_4_1_w = in_1_r[2];
// 	add_5_1_w = in_1_r[5];
// 	add_6_1_w = in_1_r[5];
// 	add_7_1_w = in_1_r[8];
// 	add_8_1_w = in_1_r[4];
// 	if(state == 19)begin
// 		add_0_1_w = in_1_r[0];
// 		add_1_1_w = in_1_r[1];
// 		add_2_1_w = in_1_r[1];
// 		add_3_1_w = in_1_r[2];
// 		add_4_1_w = in_1_r[6];
// 		add_5_1_w = in_1_r[7];
// 		add_6_1_w = in_1_r[7];
// 		add_7_1_w = in_1_r[8];
// 		add_8_1_w = in_1_r[4];
// 	end
// end

always @(*) begin
	fetch_flag_w = fetch_flag_r;
	if(state == 9)begin
		fetch_flag_w = 0;
	end
	else if(state == 13)begin
		fetch_flag_w = 1;
	end
end

always @(*) begin
	in_0_0_w = in_0_r[0];
	in_1_0_w = in_0_r[1];
	in_2_0_w = in_0_r[2];
	in_3_0_w = in_0_r[3];
	in_4_0_w = in_0_r[4];
	in_5_0_w = in_0_r[5];
	in_6_0_w = in_0_r[6];
	in_7_0_w = in_0_r[7];
	in_8_0_w = in_0_r[8];
	if(state == 9)begin
		in_0_0_w = kernel_r[0];
		in_1_0_w = kernel_r[1];
		in_2_0_w = kernel_r[2];
		in_3_0_w = kernel_r[4];
		in_4_0_w = kernel_r[5];
		in_5_0_w = kernel_r[6];
		in_6_0_w = kernel_r[8];
		in_7_0_w = kernel_r[9];
		in_8_0_w = kernel_r[10];
	end
	else if(state == 13)begin
		in_0_0_w = kernel_r[4];
		in_1_0_w = kernel_r[5];
		in_2_0_w = kernel_r[6];
		in_3_0_w = kernel_r[8];
		in_4_0_w = kernel_r[9];
		in_5_0_w = kernel_r[10];
		in_6_0_w = kernel_r[12];
		in_7_0_w = kernel_r[13];
		in_8_0_w = kernel_r[14];
	end
	else if(state == 14)begin
		case (dly_cnt_r)
			0: begin
				if(in_0_r[0] < in_0_r[1] && in_0_r[0] < in_0_r[2])begin
					if(in_0_r[1] < in_0_r[2])begin
						in_0_0_w = in_0_r[0];
						in_1_0_w = in_0_r[1];
						in_2_0_w = in_0_r[2];
					end
					else begin
						in_0_0_w = in_0_r[0];
						in_1_0_w = in_0_r[2];
						in_2_0_w = in_0_r[1];
					end
				end
				else if(in_0_r[1] < in_0_r[0] && in_0_r[1] < in_0_r[2])begin
					if(in_0_r[0] < in_0_r[2])begin
						in_0_0_w = in_0_r[1];
						in_1_0_w = in_0_r[0];
						in_2_0_w = in_0_r[2];
					end
					else begin
						in_0_0_w = in_0_r[1];
						in_1_0_w = in_0_r[2];
						in_2_0_w = in_0_r[0];
					end
				end
				else begin
					if(in_0_r[0] < in_0_r[1])begin
						in_0_0_w = in_0_r[2];
						in_1_0_w = in_0_r[0];
						in_2_0_w = in_0_r[1];
					end
					else begin
						in_0_0_w = in_0_r[2];
						in_1_0_w = in_0_r[1];
						in_2_0_w = in_0_r[0];
					end
				end

				if(in_0_r[3] < in_0_r[4] && in_0_r[3] < in_0_r[5])begin
					if(in_0_r[4] < in_0_r[5])begin
						in_3_0_w = in_0_r[3];
						in_4_0_w = in_0_r[4];
						in_5_0_w = in_0_r[5];
					end
					else begin
						in_3_0_w = in_0_r[3];
						in_4_0_w = in_0_r[5];
						in_5_0_w = in_0_r[4];
					end
				end
				else if(in_0_r[4] < in_0_r[3] && in_0_r[4] < in_0_r[5])begin
					if(in_0_r[3] < in_0_r[5])begin
						in_3_0_w = in_0_r[4];
						in_4_0_w = in_0_r[3];
						in_5_0_w = in_0_r[5];
					end
					else begin
						in_3_0_w = in_0_r[4];
						in_4_0_w = in_0_r[5];
						in_5_0_w = in_0_r[3];
					end
				end
				else begin
					if(in_0_r[3] < in_0_r[4])begin
						in_3_0_w = in_0_r[5];
						in_4_0_w = in_0_r[3];
						in_5_0_w = in_0_r[4];
					end
					else begin
						in_3_0_w = in_0_r[5];
						in_4_0_w = in_0_r[4];
						in_5_0_w = in_0_r[3];
					end
				end

				if(in_0_r[6] < in_0_r[7] && in_0_r[6] < in_0_r[8])begin
					if(in_0_r[7] < in_0_r[8])begin
						in_6_0_w = in_0_r[6];
						in_7_0_w = in_0_r[7];
						in_8_0_w = in_0_r[8];
					end
					else begin
						in_6_0_w = in_0_r[6];
						in_7_0_w = in_0_r[8];
						in_8_0_w = in_0_r[7];
					end
				end
				else if(in_0_r[7] < in_0_r[6] && in_0_r[7] < in_0_r[8])begin
					if(in_0_r[6] < in_0_r[8])begin
						in_6_0_w = in_0_r[7];
						in_7_0_w = in_0_r[6];
						in_8_0_w = in_0_r[8];
					end
					else begin
						in_6_0_w = in_0_r[7];
						in_7_0_w = in_0_r[8];
						in_8_0_w = in_0_r[6];
					end
				end
				else begin
					if(in_0_r[6] < in_0_r[7])begin
						in_6_0_w = in_0_r[8];
						in_7_0_w = in_0_r[6];
						in_8_0_w = in_0_r[7];
					end
					else begin
						in_6_0_w = in_0_r[8];
						in_7_0_w = in_0_r[7];
						in_8_0_w = in_0_r[6];
					end
				end
			end
			1: begin
				if(in_0_r[0] < in_0_r[3] && in_0_r[0] < in_0_r[6])begin
					if(in_0_r[3] < in_0_r[6])begin
						in_0_0_w = in_0_r[0];
						in_3_0_w = in_0_r[3];
						in_6_0_w = in_0_r[6];
					end
					else begin
						in_0_0_w = in_0_r[0];
						in_3_0_w = in_0_r[6];
						in_6_0_w = in_0_r[3];
					end
				end
				else if(in_0_r[3] < in_0_r[0] && in_0_r[3] < in_0_r[6])begin
					if(in_0_r[0] < in_0_r[6])begin
						in_0_0_w = in_0_r[3];
						in_3_0_w = in_0_r[0];
						in_6_0_w = in_0_r[6];
					end
					else begin
						in_0_0_w = in_0_r[3];
						in_3_0_w = in_0_r[6];
						in_6_0_w = in_0_r[0];
					end
				end
				else begin
					if(in_0_r[0] < in_0_r[3])begin
						in_0_0_w = in_0_r[6];
						in_3_0_w = in_0_r[0];
						in_6_0_w = in_0_r[3];
					end
					else begin
						in_0_0_w = in_0_r[6];
						in_3_0_w = in_0_r[3];
						in_6_0_w = in_0_r[0];
					end
				end

				if(in_0_r[1] < in_0_r[4] && in_0_r[1] < in_0_r[7])begin
					if(in_0_r[4] < in_0_r[7])begin
						in_1_0_w = in_0_r[1];
						in_4_0_w = in_0_r[4];
						in_7_0_w = in_0_r[7];
					end
					else begin
						in_1_0_w = in_0_r[1];
						in_4_0_w = in_0_r[7];
						in_7_0_w = in_0_r[4];
					end
				end
				else if(in_0_r[4] < in_0_r[1] && in_0_r[4] < in_0_r[7])begin
					if(in_0_r[1] < in_0_r[7])begin
						in_1_0_w = in_0_r[4];
						in_4_0_w = in_0_r[1];
						in_7_0_w = in_0_r[7];
					end
					else begin
						in_1_0_w = in_0_r[4];
						in_4_0_w = in_0_r[7];
						in_7_0_w = in_0_r[1];
					end
				end
				else begin
					if(in_0_r[1] < in_0_r[4])begin
						in_1_0_w = in_0_r[7];
						in_4_0_w = in_0_r[1];
						in_7_0_w = in_0_r[4];
					end
					else begin
						in_1_0_w = in_0_r[7];
						in_4_0_w = in_0_r[4];
						in_7_0_w = in_0_r[1];
					end
				end

				if(in_0_r[2] < in_0_r[5] && in_0_r[2] < in_0_r[8])begin
					if(in_0_r[5] < in_0_r[8])begin
						in_2_0_w = in_0_r[2];
						in_5_0_w = in_0_r[5];
						in_8_0_w = in_0_r[8];
					end
					else begin
						in_2_0_w = in_0_r[2];
						in_5_0_w = in_0_r[8];
						in_8_0_w = in_0_r[5];
					end
				end
				else if(in_0_r[5] < in_0_r[2] && in_0_r[5] < in_0_r[8])begin
					if(in_0_r[2] < in_0_r[8])begin
						in_2_0_w = in_0_r[5];
						in_5_0_w = in_0_r[2];
						in_8_0_w = in_0_r[8];
					end
					else begin
						in_2_0_w = in_0_r[5];
						in_5_0_w = in_0_r[8];
						in_8_0_w = in_0_r[2];
					end
				end
				else begin
					if(in_0_r[2] < in_0_r[5])begin
						in_2_0_w = in_0_r[8];
						in_5_0_w = in_0_r[2];
						in_8_0_w = in_0_r[5];
					end
					else begin
						in_2_0_w = in_0_r[8];
						in_5_0_w = in_0_r[5];
						in_8_0_w = in_0_r[2];
					end
				end
			end
			2: begin
				if(in_0_r[2] < in_0_r[4] && in_0_r[2] < in_0_r[6])begin
					if(in_0_r[4] < in_0_r[6])begin
						in_2_0_w = in_0_r[2];
						in_4_0_w = in_0_r[4];
						in_6_0_w = in_0_r[6];
					end
					else begin
						in_2_0_w = in_0_r[2];
						in_4_0_w = in_0_r[6];
						in_6_0_w = in_0_r[4];
					end
				end
				else if(in_0_r[4] < in_0_r[2] && in_0_r[4] < in_0_r[6])begin
					if(in_0_r[2] < in_0_r[6])begin
						in_2_0_w = in_0_r[4];
						in_4_0_w = in_0_r[2];
						in_6_0_w = in_0_r[6];
					end
					else begin
						in_2_0_w = in_0_r[4];
						in_4_0_w = in_0_r[6];
						in_6_0_w = in_0_r[2];
					end
				end
				else begin
					if(in_0_r[2] < in_0_r[4])begin
						in_2_0_w = in_0_r[6];
						in_4_0_w = in_0_r[2];
						in_6_0_w = in_0_r[4];
					end
					else begin
						in_2_0_w = in_0_r[6];
						in_4_0_w = in_0_r[4];
						in_6_0_w = in_0_r[2];
					end
				end
			end
		endcase
	end
end

always @(*) begin
	in_0_1_w = in_1_r[0];
	in_1_1_w = in_1_r[1];
	in_2_1_w = in_1_r[2];
	in_3_1_w = in_1_r[3];
	in_4_1_w = in_1_r[4];
	in_5_1_w = in_1_r[5];
	in_6_1_w = in_1_r[6];
	in_7_1_w = in_1_r[7];
	in_8_1_w = in_1_r[8];
	if(state == 9)begin
		in_0_1_w = kernel_r[1];
		in_1_1_w = kernel_r[2];
		in_2_1_w = kernel_r[3];
		in_3_1_w = kernel_r[5];
		in_4_1_w = kernel_r[6];
		in_5_1_w = kernel_r[7];
		in_6_1_w = kernel_r[9];
		in_7_1_w = kernel_r[10];
		in_8_1_w = kernel_r[11];
	end
	else if(state == 13)begin
		in_0_1_w = kernel_r[5];
		in_1_1_w = kernel_r[6];
		in_2_1_w = kernel_r[7];
		in_3_1_w = kernel_r[9];
		in_4_1_w = kernel_r[10];
		in_5_1_w = kernel_r[11];
		in_6_1_w = kernel_r[13];
		in_7_1_w = kernel_r[14];
		in_8_1_w = kernel_r[15];
	end
	else if(state == 14)begin
		case (dly_cnt_r)
			0: begin
				if(in_1_r[0] < in_1_r[1] && in_1_r[0] < in_1_r[2])begin
					if(in_1_r[1] < in_1_r[2])begin
						in_0_1_w = in_1_r[0];
						in_1_1_w = in_1_r[1];
						in_2_1_w = in_1_r[2];
					end
					else begin
						in_0_1_w = in_1_r[0];
						in_1_1_w = in_1_r[2];
						in_2_1_w = in_1_r[1];
					end
				end
				else if(in_1_r[1] < in_1_r[0] && in_1_r[1] < in_1_r[2])begin
					if(in_1_r[0] < in_1_r[2])begin
						in_0_1_w = in_1_r[1];
						in_1_1_w = in_1_r[0];
						in_2_1_w = in_1_r[2];
					end
					else begin
						in_0_1_w = in_1_r[1];
						in_1_1_w = in_1_r[2];
						in_2_1_w = in_1_r[0];
					end
				end
				else begin
					if(in_1_r[0] < in_1_r[1])begin
						in_0_1_w = in_1_r[2];
						in_1_1_w = in_1_r[0];
						in_2_1_w = in_1_r[1];
					end
					else begin
						in_0_1_w = in_1_r[2];
						in_1_1_w = in_1_r[1];
						in_2_1_w = in_1_r[0];
					end
				end

				if(in_1_r[3] < in_1_r[4] && in_1_r[3] < in_1_r[5])begin
					if(in_1_r[4] < in_1_r[5])begin
						in_3_1_w = in_1_r[3];
						in_4_1_w = in_1_r[4];
						in_5_1_w = in_1_r[5];
					end
					else begin
						in_3_1_w = in_1_r[3];
						in_4_1_w = in_1_r[5];
						in_5_1_w = in_1_r[4];
					end
				end
				else if(in_1_r[4] < in_1_r[3] && in_1_r[4] < in_1_r[5])begin
					if(in_1_r[3] < in_1_r[5])begin
						in_3_1_w = in_1_r[4];
						in_4_1_w = in_1_r[3];
						in_5_1_w = in_1_r[5];
					end
					else begin
						in_3_1_w = in_1_r[4];
						in_4_1_w = in_1_r[5];
						in_5_1_w = in_1_r[3];
					end
				end
				else begin
					if(in_1_r[3] < in_1_r[4])begin
						in_3_1_w = in_1_r[5];
						in_4_1_w = in_1_r[3];
						in_5_1_w = in_1_r[4];
					end
					else begin
						in_3_1_w = in_1_r[5];
						in_4_1_w = in_1_r[4];
						in_5_1_w = in_1_r[3];
					end
				end

				if(in_1_r[6] < in_1_r[7] && in_1_r[6] < in_1_r[8])begin
					if(in_1_r[7] < in_1_r[8])begin
						in_6_1_w = in_1_r[6];
						in_7_1_w = in_1_r[7];
						in_8_1_w = in_1_r[8];
					end
					else begin
						in_6_1_w = in_1_r[6];
						in_7_1_w = in_1_r[8];
						in_8_1_w = in_1_r[7];
					end
				end
				else if(in_1_r[7] < in_1_r[6] && in_1_r[7] < in_1_r[8])begin
					if(in_1_r[6] < in_1_r[8])begin
						in_6_1_w = in_1_r[7];
						in_7_1_w = in_1_r[6];
						in_8_1_w = in_1_r[8];
					end
					else begin
						in_6_1_w = in_1_r[7];
						in_7_1_w = in_1_r[8];
						in_8_1_w = in_1_r[6];
					end
				end
				else begin
					if(in_1_r[6] < in_1_r[7])begin
						in_6_1_w = in_1_r[8];
						in_7_1_w = in_1_r[6];
						in_8_1_w = in_1_r[7];
					end
					else begin
						in_6_1_w = in_1_r[8];
						in_7_1_w = in_1_r[7];
						in_8_1_w = in_1_r[6];
					end
				end
			end
			1: begin
				if(in_1_r[0] < in_1_r[3] && in_1_r[0] < in_1_r[6])begin
					if(in_1_r[3] < in_1_r[6])begin
						in_0_1_w = in_1_r[0];
						in_3_1_w = in_1_r[3];
						in_6_1_w = in_1_r[6];
					end
					else begin
						in_0_1_w = in_1_r[0];
						in_3_1_w = in_1_r[6];
						in_6_1_w = in_1_r[3];
					end
				end
				else if(in_1_r[3] < in_1_r[0] && in_1_r[3] < in_1_r[6])begin
					if(in_1_r[0] < in_1_r[6])begin
						in_0_1_w = in_1_r[3];
						in_3_1_w = in_1_r[0];
						in_6_1_w = in_1_r[6];
					end
					else begin
						in_0_1_w = in_1_r[3];
						in_3_1_w = in_1_r[6];
						in_6_1_w = in_1_r[0];
					end
				end
				else begin
					if(in_1_r[0] < in_1_r[3])begin
						in_0_1_w = in_1_r[6];
						in_3_1_w = in_1_r[0];
						in_6_1_w = in_1_r[3];
					end
					else begin
						in_0_1_w = in_1_r[6];
						in_3_1_w = in_1_r[3];
						in_6_1_w = in_1_r[0];
					end
				end

				if(in_1_r[1] < in_1_r[4] && in_1_r[1] < in_1_r[7])begin
					if(in_1_r[4] < in_1_r[7])begin
						in_1_1_w = in_1_r[1];
						in_4_1_w = in_1_r[4];
						in_7_1_w = in_1_r[7];
					end
					else begin
						in_1_1_w = in_1_r[1];
						in_4_1_w = in_1_r[7];
						in_7_1_w = in_1_r[4];
					end
				end
				else if(in_1_r[4] < in_1_r[1] && in_1_r[4] < in_1_r[7])begin
					if(in_1_r[1] < in_1_r[7])begin
						in_1_1_w = in_1_r[4];
						in_4_1_w = in_1_r[1];
						in_7_1_w = in_1_r[7];
					end
					else begin
						in_1_1_w = in_1_r[4];
						in_4_1_w = in_1_r[7];
						in_7_1_w = in_1_r[1];
					end
				end
				else begin
					if(in_1_r[1] < in_1_r[4])begin
						in_1_1_w = in_1_r[7];
						in_4_1_w = in_1_r[1];
						in_7_1_w = in_1_r[4];
					end
					else begin
						in_1_1_w = in_1_r[7];
						in_4_1_w = in_1_r[4];
						in_7_1_w = in_1_r[1];
					end
				end

				if(in_1_r[2] < in_1_r[5] && in_1_r[2] < in_1_r[8])begin
					if(in_1_r[5] < in_1_r[8])begin
						in_2_1_w = in_1_r[2];
						in_5_1_w = in_1_r[5];
						in_8_1_w = in_1_r[8];
					end
					else begin
						in_2_1_w = in_1_r[2];
						in_5_1_w = in_1_r[8];
						in_8_1_w = in_1_r[5];
					end
				end
				else if(in_1_r[5] < in_1_r[2] && in_1_r[5] < in_1_r[8])begin
					if(in_1_r[2] < in_1_r[8])begin
						in_2_1_w = in_1_r[5];
						in_5_1_w = in_1_r[2];
						in_8_1_w = in_1_r[8];
					end
					else begin
						in_2_1_w = in_1_r[5];
						in_5_1_w = in_1_r[8];
						in_8_1_w = in_1_r[2];
					end
				end
				else begin
					if(in_1_r[2] < in_1_r[5])begin
						in_2_1_w = in_1_r[8];
						in_5_1_w = in_1_r[2];
						in_8_1_w = in_1_r[5];
					end
					else begin
						in_2_1_w = in_1_r[8];
						in_5_1_w = in_1_r[5];
						in_8_1_w = in_1_r[2];
					end
				end
			end
			2: begin
				if(in_1_r[2] < in_1_r[4] && in_1_r[2] < in_1_r[6])begin
					if(in_1_r[4] < in_1_r[6])begin
						in_2_1_w = in_1_r[2];
						in_4_1_w = in_1_r[4];
						in_6_1_w = in_1_r[6];
					end
					else begin
						in_2_1_w = in_1_r[2];
						in_4_1_w = in_1_r[6];
						in_6_1_w = in_1_r[4];
					end
				end
				else if(in_1_r[4] < in_1_r[2] && in_1_r[4] < in_1_r[6])begin
					if(in_1_r[2] < in_1_r[6])begin
						in_2_1_w = in_1_r[4];
						in_4_1_w = in_1_r[2];
						in_6_1_w = in_1_r[6];
					end
					else begin
						in_2_1_w = in_1_r[4];
						in_4_1_w = in_1_r[6];
						in_6_1_w = in_1_r[2];
					end
				end
				else begin
					if(in_1_r[2] < in_1_r[4])begin
						in_2_1_w = in_1_r[6];
						in_4_1_w = in_1_r[2];
						in_6_1_w = in_1_r[4];
					end
					else begin
						in_2_1_w = in_1_r[6];
						in_4_1_w = in_1_r[4];
						in_6_1_w = in_1_r[2];
					end
				end
			end
		endcase
	end
end

always @(*) begin
	conv_result_0_w = conv_result_0_r;
	conv_result_1_w = conv_result_1_r;
	if(acc_flag_w)begin
		conv_result_0_w = conv_result_0_r + add_result_0_r;
		conv_result_1_w = conv_result_1_r + add_result_1_r;
	end
	else if(state == 1)begin
		conv_result_0_w = 0;
		conv_result_1_w = 0;
	end
end

always @(*) begin
	conv_result_2_w = conv_result_2_r;
	conv_result_3_w = conv_result_3_r;
	if(acc_flag_r)begin
		conv_result_2_w = conv_result_2_r + add_result_0_r;
		conv_result_3_w = conv_result_3_r + add_result_1_r;
	end
	else if(state == 1)begin
		conv_result_2_w = 0;
		conv_result_3_w = 0;
	end
end

always @(*) begin
	case (state)
		0: begin
			n_state = 1;
		end
		1: begin	//o_op_ready
			n_state = 2;
		end
		2: begin	//i_op_valid
			n_state = (i_op_valid) ? 3 : 2;
		end
		3: begin
			n_state = 1;	//left, right, up, down shift
			if(i_op_mode_r == 0)begin	//load input feature
				n_state = 4;
			end
			else if(i_op_mode_r == 7)begin	//display
				n_state = 30;
			end
			else if(i_op_mode_r == 8)begin	//conv
				n_state = 7;
			end
			else if(i_op_mode_r == 9)begin	//median
				n_state = 7;
			end
			else if(i_op_mode_r == 10)begin	//Sobel
				n_state = 7;
			end
		end
		4: begin	//load input feature
			n_state = ((x_cnt_r == 7) && (y_cnt_r == 7) && (d_cnt_r == 31)) ? 1 : 4;
		end
		11: begin	//display start
			n_state = 5;
		end
		5: begin	//display
			n_state = ((dly_cnt_r == 3) && (d_cnt_r == ch_dec_w)) ? 6 : 5;
		end
		6: begin	//display wait
			n_state = (dly_cnt_r == 1) ? 29 : 6;
		end
		7: begin	//load in kernel
			n_state = 31;
		end
		17: begin	//load in kernel wait 0
			n_state = 8;
		end
		8: begin	//load in kernel wait 1
			n_state = 32;
		end
		32: begin
			n_state = 9;
		end
		9: begin	//fetch 00 to in_0, 01 to in_1
			n_state = 13;
			if(i_op_mode_r == 9)begin
				n_state = 14;
			end
			else if(i_op_mode_r == 10)begin
				n_state = 18;
			end
		end
		13: begin	//fetch 10 to in_0, 11 to in_1
			n_state = 12;
			if(i_op_mode_r == 9)begin
				n_state = 14;
			end
			else if(i_op_mode_r == 10)begin
				n_state = 18;
			end
		end
		12: begin	//conv
			n_state = (dly_cnt_r == 1) ? ((d_cnt_r == ch_dec_w) ? 10 : 7) : 12;
		end
		10: begin	//conv wait output
			n_state = (dly_cnt_r == 3) ? 29 : 10;
		end
		14: begin	//median
			n_state = (dly_cnt_r == 2) ? ((fetch_flag_r)?16:15) : 14;
		end
		15: begin	//median wait output 00, 01
			n_state = (dly_cnt_r == 1) ? 13 : 15;
		end
		16: begin	//median wait output 10, 11
			n_state = (dly_cnt_r == 1) ? ((d_cnt_r == 3) ? 29 : 7) : 16;
		end
		18: begin	//Sobel gx
			n_state = (dly_cnt_r == 1) ? 19 : 18;
		end
		19: begin	//Sobel gy
			n_state = (dly_cnt_r == 1) ? ((fetch_flag_r)?22:13) : 19;
		end
		22: begin	//Cal gradient
			n_state = 33;
		end
		33: begin
			n_state = 20;
		end
		20: begin	//NMS g0
			n_state = (dly_cnt_r == 4) ? 21 : 20;
		end
		21: begin
			n_state = 23;
		end
		23: begin	//NMS g1
			n_state = (dly_cnt_r == 4) ? 26 : 23;
		end
		26: begin
			n_state = 24;
		end
		24: begin	//NMS g2
			n_state = (dly_cnt_r == 4) ? 27 : 24;
		end
		27: begin
			n_state = 25;
		end
		25: begin	//NMS g3
			n_state = (dly_cnt_r == 4) ? 28 : 25;
		end
		28: begin	
			n_state = (d_cnt_r == 3) ? 29 : 7;
		end
		// 21: begin	//Sobel+NMS wait output
		// 	n_state = (dly_cnt_r == 3) ? ((d_cnt_r == 3) ? 1 : 7) : 21;
		// end
		29: begin
			n_state = 1;
		end
		30: begin
			n_state = 11;
		end
		31: begin
			n_state = 17;
		end
		default: n_state = 6'dx;
	endcase
end

always @(*) begin
	x_cnt_w = x_cnt_r;
	if(state == 3) begin
		if(i_op_mode_r == 1)begin	//right shift
			x_cnt_w = (x_cnt_r == 6) ? x_cnt_r : x_cnt_r + 1;
		end
		else if(i_op_mode_r == 2)begin	//left shift
			x_cnt_w = (x_cnt_r == 0) ? x_cnt_r : x_cnt_r - 1;
		end
	end
	else if(state == 4)begin
		x_cnt_w = x_cnt_r + 1;
	end
end

always @(*) begin
	y_cnt_w = y_cnt_r;
	if(state == 3) begin
		if(i_op_mode_r == 3)begin	//up shift
			y_cnt_w = (y_cnt_r == 0) ? y_cnt_r : y_cnt_r - 1;
		end
		else if(i_op_mode_r == 4)begin	//down shift
			y_cnt_w = (y_cnt_r == 6) ? y_cnt_r : y_cnt_r + 1;
		end
	end
	else if(state == 4)begin
		if(x_cnt_r == 7) begin
			y_cnt_w = y_cnt_r + 1;
		end
	end
end

always @(*) begin
	d_cnt_w = d_cnt_r;
	if(state == 4)begin
		if(x_cnt_r == 7 && y_cnt_r == 7)begin
			d_cnt_w = d_cnt_r + 1;
		end
	end
	else if(state == 5 || state == 11)begin
		if(dly_cnt_r == 3)begin
			d_cnt_w = (d_cnt_r == ch_dec_w) ? 0 : d_cnt_r + 1;
		end
	end
	else if(state == 12)begin
		if(dly_cnt_r == 1)begin
			d_cnt_w = (d_cnt_r == ch_dec_w) ? 0 : d_cnt_r + 1;
		end
	end
	else if(state == 16)begin
		if(dly_cnt_r == 1)begin
			d_cnt_w = (d_cnt_r == 3) ? 0 : d_cnt_r + 1;
		end
	end
	// else if(state == 21)begin
	// 	if(dly_cnt_r == 3)begin
	// 		d_cnt_w = (d_cnt_r == 3) ? 0 : d_cnt_r + 1;
	// 	end
	// end
	else if(state == 28)begin
		// if(dly_cnt_r == 3)begin
			d_cnt_w = (d_cnt_r == 3) ? 0 : d_cnt_r + 1;
		// end
	end
end

always @(*) begin
	ch_enc_w = ch_enc_r;
	if(state == 3)begin
		if(i_op_mode_r == 5)begin	//scale down
			ch_enc_w = (ch_enc_r == 2) ? ch_enc_r : ch_enc_r + 1;
		end
		else if(i_op_mode_r == 6)begin	//scale up
			ch_enc_w = (ch_enc_r == 0) ? ch_enc_r : ch_enc_r - 1;
		end
	end
end

always @(*) begin
	case (ch_enc_r)
		0:  ch_dec_w = 31;
		1:  ch_dec_w = 15;
		2:  ch_dec_w = 7;
		default: ch_dec_w = 5'bx;
	endcase
end

always @(*) begin
	addr_w = {d_cnt_r, y_cnt_r, x_cnt_r};
	if(state == 5 || state == 11)begin
		case (dly_cnt_r)
			0: addr_w = {d_cnt_r, y_cnt_r, x_cnt_r};
			1: addr_w = {d_cnt_r, y_cnt_r, x_cnt_p1_w};
			2: addr_w = {d_cnt_r, y_cnt_p1_w, x_cnt_r};
			3: addr_w = {d_cnt_r, y_cnt_p1_w, x_cnt_p1_w};
		endcase
	end
end

reg [1:0] tmp_0123, tmp_4567;
reg tmp_04, tmp_15, tmp_26, tmp_37;

always @(*) begin
	case (x_ref[1:0])
		0: begin
			tmp_04 = x_ref[2];
			tmp_15 = x_ref[2];
			tmp_26 = x_ref[2];
			tmp_37 = x_ref[2];
		end
		1: begin
			tmp_04 = !x_ref[2];
			tmp_15 = x_ref[2];
			tmp_26 = x_ref[2];
			tmp_37 = x_ref[2];
		end
		2: begin
			tmp_04 = !x_ref[2];
			tmp_15 = !x_ref[2];
			tmp_26 = x_ref[2];
			tmp_37 = x_ref[2];
		end
		3: begin
			tmp_04 = !x_ref[2];
			tmp_15 = !x_ref[2];
			tmp_26 = !x_ref[2];
			tmp_37 = x_ref[2];
		end
	endcase
end

always @(*) begin
	case (y_ref[0])
		0: begin
			tmp_0123 = y_ref[2:1];
			tmp_4567 = y_ref[2:1];
		end
		1: begin
			tmp_0123 = y_ref[2:1] + 1;
			tmp_4567 = y_ref[2:1];
		end
	endcase
end

always @(*) begin
	A0_w = {addr_w[10:4], addr_w[2]};
	A1_w = {addr_w[10:4], addr_w[2]};
	A2_w = {addr_w[10:4], addr_w[2]};
	A3_w = {addr_w[10:4], addr_w[2]};
	A4_w = {addr_w[10:4], addr_w[2]};
	A5_w = {addr_w[10:4], addr_w[2]};
	A6_w = {addr_w[10:4], addr_w[2]};
	A7_w = {addr_w[10:4], addr_w[2]};
	if(state == 7 || state == 17 || state == 31) begin
		A0_w = {d_cnt_r, tmp_0123, tmp_04};
		A1_w = {d_cnt_r, tmp_0123, tmp_15};
		A2_w = {d_cnt_r, tmp_0123, tmp_26};
		A3_w = {d_cnt_r, tmp_0123, tmp_37};
		A4_w = {d_cnt_r, tmp_4567, tmp_04};
		A5_w = {d_cnt_r, tmp_4567, tmp_15};
		A6_w = {d_cnt_r, tmp_4567, tmp_26};
		A7_w = {d_cnt_r, tmp_4567, tmp_37};
	end
end

always @(*) begin
	WEN0_w = 1;
	WEN1_w = 1;
	WEN2_w = 1;
	WEN3_w = 1;
	WEN4_w = 1;
	WEN5_w = 1;
	WEN6_w = 1;
	WEN7_w = 1;
	if(state == 4)begin
		case ({addr_w[3], addr_w[1:0]})
			0: WEN0_w = 0;
			1: WEN1_w = 0;
			2: WEN2_w = 0;
			3: WEN3_w = 0;
			4: WEN4_w = 0;
			5: WEN5_w = 0;
			6: WEN6_w = 0;
			7: WEN7_w = 0;
		endcase
	end
end

always @(*) begin
	dly_cnt_w = dly_cnt_r;
	if(state == 5 || state == 11 || state == 30)begin
		dly_cnt_w = (dly_cnt_r == 3) ? 0 : dly_cnt_r+1;
	end
	else if(state == 6)begin
		dly_cnt_w = (dly_cnt_r == 1) ? 0 : dly_cnt_r+1;
	end
	else if(state == 12)begin
		dly_cnt_w = (dly_cnt_r == 1) ? 0 : dly_cnt_r+1;
	end
	else if(state == 10)begin
		dly_cnt_w = (dly_cnt_r == 3) ? 0 : dly_cnt_r+1;
	end
	else if(state == 14)begin
		dly_cnt_w = (dly_cnt_r == 2) ? 0 : dly_cnt_r+1;
	end
	else if(state == 15)begin
		dly_cnt_w = (dly_cnt_r == 1) ? 0 : dly_cnt_r+1;
	end
	else if(state == 16)begin
		dly_cnt_w = (dly_cnt_r == 1) ? 0 : dly_cnt_r+1;
	end
	else if(state == 18)begin
		dly_cnt_w = (dly_cnt_r == 1) ? 0 : dly_cnt_r+1;
	end
	else if(state == 19)begin
		dly_cnt_w = (dly_cnt_r == 1) ? 0 : dly_cnt_r+1;
	end
	// else if(state == 21)begin
	// 	dly_cnt_w = (dly_cnt_r == 3) ? 0 : dly_cnt_r+1;
	// end
	else if(state == 20 || state == 23 || state == 24 || state == 25)begin
		dly_cnt_w = (dly_cnt_r == 4) ? 0 : dly_cnt_r+1;
	end
end

always @(*) begin
	o_out_valid_w = 0;
	if(state == 5 || state == 6)begin
		o_out_valid_w = 1;
	end
	else if(state == 10)begin
		o_out_valid_w = 1;
	end
	else if(state == 15)begin
		o_out_valid_w = 1;
	end
	else if(state == 16)begin
		o_out_valid_w = 1;
	end
	// else if(state == 21)begin
	// 	o_out_valid_w = 1;
	// end
	else if(state == 21 || state == 26 || state == 27 || state == 28)begin
		o_out_valid_w = 1;
	end
end

always @(*) begin
	o_out_data_w = o_out_data_r;
	if(state == 5 || state == 6)begin
		// case ({addr_r[3], addr_r[1:0]})
		case ({addr_dly_r[3], addr_dly_r[1:0]})
			0: o_out_data_w = Q0_r;
			1: o_out_data_w = Q1_r;
			2: o_out_data_w = Q2_r;
			3: o_out_data_w = Q3_r;
			4: o_out_data_w = Q4_r;
			5: o_out_data_w = Q5_r;
			6: o_out_data_w = Q6_r;
			7: o_out_data_w = Q7_r;
		endcase
	end
	else if(state == 10)begin
		case (dly_cnt_r)
			0: o_out_data_w = conv_rnd_result_0_w;
			1: o_out_data_w = conv_rnd_result_1_w;
			2: o_out_data_w = conv_rnd_result_2_w;
			3: o_out_data_w = conv_rnd_result_3_w;
		endcase
	end
	else if(state == 15)begin
		case (dly_cnt_r[0])
			0: o_out_data_w = in_0_r[4]; 
			1: o_out_data_w = in_1_r[4]; 
		endcase
	end
	else if(state == 16)begin
		case (dly_cnt_r[0])
			0: o_out_data_w = in_0_r[4]; 
			1: o_out_data_w = in_1_r[4]; 
		endcase
	end
	// else if(state == 21)begin
	// 	case (dly_cnt_r)
	// 		0: o_out_data_w = (nms_mask_r[0]) ? 0 : g0_r;
	// 		1: o_out_data_w = (nms_mask_r[1]) ? 0 : g1_r;
	// 		2: o_out_data_w = (nms_mask_r[2]) ? 0 : g2_r;
	// 		3: o_out_data_w = (nms_mask_r[3]) ? 0 : g3_r;
	// 		// 0: o_out_data_w = g0_r;
	// 		// 1: o_out_data_w = g1_r;
	// 		// 2: o_out_data_w = g2_r;
	// 		// 3: o_out_data_w = g3_r;
	// 	endcase
	// end
	else if(state == 21)begin
		o_out_data_w = (nms_mask_r) ? 0 : g0_r;
	end
	else if(state == 26)begin
		o_out_data_w = (nms_mask_r) ? 0 : g1_r;
	end
	else if(state == 27)begin
		o_out_data_w = (nms_mask_r) ? 0 : g2_r;
	end
	else if(state == 28)begin
		o_out_data_w = (nms_mask_r) ? 0 : g3_r;
	end
end

always @(*) begin
	case ({y_ref_inv[0],  x_cnt_m1_w[1:0]})
		0: kernel_tmp_w[0] = Q0_r;
		1: kernel_tmp_w[0] = Q1_r;
		2: kernel_tmp_w[0] = Q2_r;
		3: kernel_tmp_w[0] = Q3_r;
		4: kernel_tmp_w[0] = Q4_r;
		5: kernel_tmp_w[0] = Q5_r;
		6: kernel_tmp_w[0] = Q6_r;
		7: kernel_tmp_w[0] = Q7_r;
	endcase
end

always @(*) begin
	case ({y_ref_inv[0],  x_cnt_r[1:0]})
		0: kernel_tmp_w[1] = Q0_r;
		1: kernel_tmp_w[1] = Q1_r;
		2: kernel_tmp_w[1] = Q2_r;
		3: kernel_tmp_w[1] = Q3_r;
		4: kernel_tmp_w[1] = Q4_r;
		5: kernel_tmp_w[1] = Q5_r;
		6: kernel_tmp_w[1] = Q6_r;
		7: kernel_tmp_w[1] = Q7_r;
	endcase
end

always @(*) begin
	case ({y_ref_inv[0],  x_cnt_p1_w[1:0]})
		0: kernel_tmp_w[2] = Q0_r;
		1: kernel_tmp_w[2] = Q1_r;
		2: kernel_tmp_w[2] = Q2_r;
		3: kernel_tmp_w[2] = Q3_r;
		4: kernel_tmp_w[2] = Q4_r;
		5: kernel_tmp_w[2] = Q5_r;
		6: kernel_tmp_w[2] = Q6_r;
		7: kernel_tmp_w[2] = Q7_r;
	endcase
end

always @(*) begin
	case ({y_ref_inv[0],  x_cnt_p2_w[1:0]})
		0: kernel_tmp_w[3] = Q0_r;
		1: kernel_tmp_w[3] = Q1_r;
		2: kernel_tmp_w[3] = Q2_r;
		3: kernel_tmp_w[3] = Q3_r;
		4: kernel_tmp_w[3] = Q4_r;
		5: kernel_tmp_w[3] = Q5_r;
		6: kernel_tmp_w[3] = Q6_r;
		7: kernel_tmp_w[3] = Q7_r;
	endcase
end

always @(*) begin
	case ({!y_ref_inv[0],  x_cnt_m1_w[1:0]})
		0: kernel_tmp_w[4] = Q0_r;
		1: kernel_tmp_w[4] = Q1_r;
		2: kernel_tmp_w[4] = Q2_r;
		3: kernel_tmp_w[4] = Q3_r;
		4: kernel_tmp_w[4] = Q4_r;
		5: kernel_tmp_w[4] = Q5_r;
		6: kernel_tmp_w[4] = Q6_r;
		7: kernel_tmp_w[4] = Q7_r;
	endcase
end

always @(*) begin
	case ({!y_ref_inv[0],  x_cnt_r[1:0]})
		0: kernel_tmp_w[5] = Q0_r;
		1: kernel_tmp_w[5] = Q1_r;
		2: kernel_tmp_w[5] = Q2_r;
		3: kernel_tmp_w[5] = Q3_r;
		4: kernel_tmp_w[5] = Q4_r;
		5: kernel_tmp_w[5] = Q5_r;
		6: kernel_tmp_w[5] = Q6_r;
		7: kernel_tmp_w[5] = Q7_r;
	endcase
end

always @(*) begin
	case ({!y_ref_inv[0],  x_cnt_p1_w[1:0]})
		0: kernel_tmp_w[6] = Q0_r;
		1: kernel_tmp_w[6] = Q1_r;
		2: kernel_tmp_w[6] = Q2_r;
		3: kernel_tmp_w[6] = Q3_r;
		4: kernel_tmp_w[6] = Q4_r;
		5: kernel_tmp_w[6] = Q5_r;
		6: kernel_tmp_w[6] = Q6_r;
		7: kernel_tmp_w[6] = Q7_r;
	endcase
end

always @(*) begin
	case ({!y_ref_inv[0],  x_cnt_p2_w[1:0]})
		0: kernel_tmp_w[7] = Q0_r;
		1: kernel_tmp_w[7] = Q1_r;
		2: kernel_tmp_w[7] = Q2_r;
		3: kernel_tmp_w[7] = Q3_r;
		4: kernel_tmp_w[7] = Q4_r;
		5: kernel_tmp_w[7] = Q5_r;
		6: kernel_tmp_w[7] = Q6_r;
		7: kernel_tmp_w[7] = Q7_r;
	endcase
end

always @(*) begin
	// kernel_zp_w[0] = kernel_tmp_w[0];
	// kernel_zp_w[1] = kernel_tmp_w[1];
	// kernel_zp_w[2] = kernel_tmp_w[2];
	// kernel_zp_w[3] = kernel_tmp_w[3];
	// kernel_zp_w[4] = kernel_tmp_w[4];
	// kernel_zp_w[5] = kernel_tmp_w[5];
	// kernel_zp_w[6] = kernel_tmp_w[6];
	// kernel_zp_w[7] = kernel_tmp_w[7];
	// if(state == 17)begin
	kernel_zp_w[0] = (x_left_bnd || y_up_bnd) ? 0 : kernel_tmp_w[0];
	kernel_zp_w[1] = (y_up_bnd) ? 0 : kernel_tmp_w[1];
	kernel_zp_w[2] = (y_up_bnd) ? 0 : kernel_tmp_w[2];
	kernel_zp_w[3] = (x_right_bnd || y_up_bnd) ? 0 : kernel_tmp_w[3];
	kernel_zp_w[4] = (x_left_bnd) ? 0 : kernel_tmp_w[4];
	kernel_zp_w[5] = kernel_tmp_w[5];
	kernel_zp_w[6] = kernel_tmp_w[6];
	kernel_zp_w[7] = (x_right_bnd) ? 0 : kernel_tmp_w[7];
	// end
	if(state == 32) begin
		kernel_zp_w[0] = (x_left_bnd) ? 0 : kernel_tmp_w[0];
		kernel_zp_w[1] = kernel_tmp_w[1];
		kernel_zp_w[2] = kernel_tmp_w[2];
		kernel_zp_w[3] = (x_right_bnd) ? 0 : kernel_tmp_w[3];
		kernel_zp_w[4] = (x_left_bnd || y_down_bnd) ? 0 : kernel_tmp_w[4];
		kernel_zp_w[5] = (y_down_bnd) ? 0 : kernel_tmp_w[5];
		kernel_zp_w[6] = (y_down_bnd) ? 0 : kernel_tmp_w[6];
		kernel_zp_w[7] = (x_right_bnd || y_down_bnd) ? 0 : kernel_tmp_w[7];
	end
end

always @(*) begin
	kernel_w[0] = kernel_r[0];
	kernel_w[1] = kernel_r[1];
	kernel_w[2] = kernel_r[2];
	kernel_w[3] = kernel_r[3];
	kernel_w[4] = kernel_r[4];
	kernel_w[5] = kernel_r[5];
	kernel_w[6] = kernel_r[6];
	kernel_w[7] = kernel_r[7];
	kernel_w[8] = kernel_r[8];
	kernel_w[9] = kernel_r[9];
	kernel_w[10] = kernel_r[10];
	kernel_w[11] = kernel_r[11];
	kernel_w[12] = kernel_r[12];
	kernel_w[13] = kernel_r[13];
	kernel_w[14] = kernel_r[14];
	kernel_w[15] = kernel_r[15];
	if(state == 17)begin
		kernel_w[0] = kernel_zp_w[0];
		kernel_w[1] = kernel_zp_w[1];
		kernel_w[2] = kernel_zp_w[2];
		kernel_w[3] = kernel_zp_w[3];
		kernel_w[4] = kernel_zp_w[4];
		kernel_w[5] = kernel_zp_w[5];
		kernel_w[6] = kernel_zp_w[6];
		kernel_w[7] = kernel_zp_w[7];
	end
	else if(state == 32)begin
		kernel_w[8] = kernel_zp_w[0];
		kernel_w[9] = kernel_zp_w[1];
		kernel_w[10] = kernel_zp_w[2];
		kernel_w[11] = kernel_zp_w[3];
		kernel_w[12] = kernel_zp_w[4];
		kernel_w[13] = kernel_zp_w[5];
		kernel_w[14] = kernel_zp_w[6];
		kernel_w[15] = kernel_zp_w[7];
	end
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk) begin
	Q0_r <= Q0_w;
	Q1_r <= Q1_w;
	Q2_r <= Q2_w;
	Q3_r <= Q3_w;
	Q4_r <= Q4_w;
	Q5_r <= Q5_w;
	Q6_r <= Q6_w;
	Q7_r <= Q7_w;
	add_sh4_0_r <= add_sh4_0_w;
	add_sh4_1_r <= add_sh4_1_w;
	add_sh3_0_r <= add_sh3_0_w;
	add_sh3_1_r <= add_sh3_1_w;
	addr_dly_r <= addr_r;
	o_out_data_r <= o_out_data_w;
	kernel_r[0] <= kernel_w[0];
	kernel_r[1] <= kernel_w[1];
	kernel_r[2] <= kernel_w[2];
	kernel_r[3] <= kernel_w[3];
	kernel_r[4] <= kernel_w[4];
	kernel_r[5] <= kernel_w[5];
	kernel_r[6] <= kernel_w[6];
	kernel_r[7] <= kernel_w[7];
	kernel_r[8] <= kernel_w[8];
	kernel_r[9] <= kernel_w[9];
	kernel_r[10] <= kernel_w[10];
	kernel_r[11] <= kernel_w[11];
	kernel_r[12] <= kernel_w[12];
	kernel_r[13] <= kernel_w[13];
	kernel_r[14] <= kernel_w[14];
	kernel_r[15] <= kernel_w[15];
	in_0_r[0] <= in_0_0_w;
	in_0_r[1] <= in_1_0_w;
	in_0_r[2] <= in_2_0_w;
	in_0_r[3] <= in_3_0_w;
	in_0_r[4] <= in_4_0_w;
	in_0_r[5] <= in_5_0_w;
	in_0_r[6] <= in_6_0_w;
	in_0_r[7] <= in_7_0_w;
	in_0_r[8] <= in_8_0_w;
	in_1_r[0] <= in_0_1_w;
	in_1_r[1] <= in_1_1_w;
	in_1_r[2] <= in_2_1_w;
	in_1_r[3] <= in_3_1_w;
	in_1_r[4] <= in_4_1_w;
	in_1_r[5] <= in_5_1_w;
	in_1_r[6] <= in_6_1_w;
	in_1_r[7] <= in_7_1_w;
	in_1_r[8] <= in_8_1_w;
	add_0123_0_r <= add_0123_0_w;
	add_4567_0_r <= add_4567_0_w;
	add_0123_1_r <= add_0123_1_w;
	add_4567_1_r <= add_4567_1_w;
	add_sh2_0_r <= add_sh2_0_w;
	add_sh2_1_r <= add_sh2_1_w;
	add_result_0_r <= add_result_0_w;
	add_result_1_r <= add_result_1_w;
	conv_result_0_r <= conv_result_0_w;
	conv_result_1_r <= conv_result_1_w;
	conv_result_2_r <= conv_result_2_w;
	conv_result_3_r <= conv_result_3_w;
	gx_0_r <= gx_0_w;
	gx_1_r <= gx_1_w; 
	gx_2_r <= gx_2_w; 
	gx_3_r <= gx_3_w;
	gy_0_r <= gy_0_w;
	gy_1_r <= gy_1_w; 
	gy_2_r <= gy_2_w; 
	gy_3_r <= gy_3_w;
	g0_r <= g0_w;
	g1_r <= g1_w;
	g2_r <= g2_w;
	g3_r <= g3_w;
	gx_flag_r <= gx_flag_w;
	gy_flag_r <= gy_flag_w;
	gradient_0_r <= gradient_0_w;
	gradient_1_r <= gradient_1_w;
	curr_gx_r <= curr_gx_w;
	curr_gy_r <= curr_gy_w;
	gx_tan22p5_r <= gx_tan22p5_w;
	gx_tan67p5_r <= gx_tan67p5_w;
	cpr0_flag_r <= cpr0_flag_w;
	cpr45_flag_r <= cpr45_flag_w;
	cpr90_flag_r <= cpr90_flag_w;
	cpr135_flag_r <= cpr135_flag_w;
	neg_gx_tan22p5_r <= neg_gx_tan22p5_w;
	neg_gx_tan67p5_r <= neg_gx_tan67p5_w;
end

always @(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		state <= 0;
		i_in_valid_r <= 0;
		i_op_mode_r <= 0;
		o_in_ready_r <= 0;
		o_out_valid_r <= 0;
		x_cnt_r <= 0;
		y_cnt_r <= 0;
		d_cnt_r <= 0;
		ch_enc_r <= 0;
		dly_cnt_r <= 0;
		addr_r <= 0;
		acc_flag_r <= 0;
		fetch_flag_r <= 0;
		nms_mask_r <= 0;
	end
	else begin
		state <= n_state;
		i_in_valid_r <= i_in_valid_w;
		i_op_mode_r <= i_op_mode_w;
		o_in_ready_r <= o_in_ready_w;
		o_out_valid_r <= o_out_valid_w;
		x_cnt_r <= x_cnt_w;
		y_cnt_r <= y_cnt_w;
		d_cnt_r <= d_cnt_w;
		ch_enc_r <= ch_enc_w;
		dly_cnt_r <= dly_cnt_w;
		addr_r <= addr_w;
		acc_flag_r <= acc_flag_w;
		fetch_flag_r <= fetch_flag_w;
		nms_mask_r <= nms_mask_w;
	end
end




sram_256x8 sram_256x8_0(
   .Q(Q0_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN0_w),
   .A(A0_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_1(
   .Q(Q1_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN1_w),
   .A(A1_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_2(
   .Q(Q2_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN2_w),
   .A(A2_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_3(
   .Q(Q3_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN3_w),
   .A(A3_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_4(
   .Q(Q4_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN4_w),
   .A(A4_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_5(
   .Q(Q5_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN5_w),
   .A(A5_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_6(
   .Q(Q6_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN6_w),
   .A(A6_w),
   .D(i_in_data_w)
);

sram_256x8 sram_256x8_7(
   .Q(Q7_w),
   .CLK(i_clk),
   .CEN(1'b0),
   .WEN(WEN7_w),
   .A(A7_w),
   .D(i_in_data_w)
);

endmodule
