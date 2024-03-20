`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

reg [7:0] iot_data_r [0:15];
reg [7:0] iot_data_w [0:15];
reg [2:0] fn_sel_r;
reg [127:0] iot_out_w, iot_out_r;
reg valid_w, valid_r;

reg [4:0] state, n_state;
reg [6:0] dly_cnt_r, dly_cnt_w;
wire [63:0] plaintext_w, mainkey_w, perm_plaintext_w, ciphertext_w;
wire [31:0] plaintext_left_w, plaintext_right_w;
reg [55:0] cipherkey_r, cipherkey_w;
wire [55:0] cipherkey_tmp_w;
wire [27:0] cipherkey_left_w, cipherkey_right_w;
wire [27:0] cipherkey_left_clsh1_w, cipherkey_right_clsh1_w, cipherkey_left_clsh2_w, cipherkey_right_clsh2_w;
wire [27:0] cipherkey_left_crsh1_w, cipherkey_right_crsh1_w, cipherkey_left_crsh2_w, cipherkey_right_crsh2_w;
reg [47:0] key_r, key_w;
wire [47:0] key_tmp_w;
wire [47:0] expand_plaintext_w;
wire [5:0] S1_in_w, S2_in_w, S3_in_w, S4_in_w, S5_in_w, S6_in_w, S7_in_w, S8_in_w;
wire [3:0] S1_out_w, S2_out_w, S3_out_w, S4_out_w, S5_out_w, S6_out_w, S7_out_w, S8_out_w;
wire [31:0] S_out_w, F_in_w, F_out_w;
wire [31:0] F_XOR_L_w;
wire [127:0] iot_in_w, extand_iot_in_w;
wire extand_iot_msb_in_w;
wire [127:0] bin2gray_w;
reg [127:0] gray2bin_w;
reg [3:0] crc3_din_w, crc3_din_r;
reg [2:0] crc3_w, crc3_r;

wire dly_cnt_flag, iot_data_flag, key_flag, cipherkey_flag, iot_out_flag;
wire crc3_din_flag, crc3_flag, fn_sel_flag;

integer i, j;

assign valid = valid_r;
assign iot_out = iot_out_r;
assign busy = !(state == 0 || state == 13);
assign plaintext_w = {iot_data_r[7], iot_data_r[6], iot_data_r[5], iot_data_r[4], iot_data_r[3], iot_data_r[2], iot_data_r[1], iot_data_r[0]};
assign mainkey_w = {iot_data_r[15], iot_data_r[14], iot_data_r[13], iot_data_r[12], iot_data_r[11], iot_data_r[10], iot_data_r[9], iot_data_r[8]};
assign cipherkey_left_w = cipherkey_r[55:28];
assign cipherkey_right_w = cipherkey_r[27:0];
assign cipherkey_left_clsh1_w = {cipherkey_left_w[26:0], cipherkey_left_w[27]};
assign cipherkey_right_clsh1_w = {cipherkey_right_w[26:0], cipherkey_right_w[27]};
assign cipherkey_left_clsh2_w = {cipherkey_left_w[25:0], cipherkey_left_w[27:26]};
assign cipherkey_right_clsh2_w = {cipherkey_right_w[25:0], cipherkey_right_w[27:26]};
assign cipherkey_left_crsh1_w = {cipherkey_left_w[0], cipherkey_left_w[27:1]};
assign cipherkey_right_crsh1_w = {cipherkey_right_w[0], cipherkey_right_w[27:1]};
assign cipherkey_left_crsh2_w = {cipherkey_left_w[1:0], cipherkey_left_w[27:2]};
assign cipherkey_right_crsh2_w = {cipherkey_right_w[1:0], cipherkey_right_w[27:2]};
assign plaintext_left_w = plaintext_w[63:32];
assign plaintext_right_w = plaintext_w[31:0];
assign S8_in_w = key_r[5:0];
assign S7_in_w = key_r[11:6];
assign S6_in_w = key_r[17:12];
assign S5_in_w = key_r[23:18];
assign S4_in_w = key_r[29:24];
assign S3_in_w = key_r[35:30];
assign S2_in_w = key_r[41:36];
assign S1_in_w = key_r[47:42];
assign S_out_w = {S1_out_w, S2_out_w, S3_out_w, S4_out_w, S5_out_w, S6_out_w, S7_out_w, S8_out_w};
assign F_in_w = key_r[31:0];
assign F_XOR_L_w = key_r[31:0] ^ plaintext_left_w;
assign iot_in_w = {iot_data_r[15], iot_data_r[14], iot_data_r[13], iot_data_r[12], iot_data_r[11], iot_data_r[10], iot_data_r[9], iot_data_r[8], iot_data_r[7], iot_data_r[6], iot_data_r[5], iot_data_r[4], iot_data_r[3], iot_data_r[2], iot_data_r[1], iot_data_r[0]};
assign extand_iot_in_w = {extand_iot_msb_in_w, iot_in_w[127:1]};
assign extand_iot_msb_in_w = (iot_in_w[127]) ? !iot_in_w[127] : iot_in_w[127];
assign bin2gray_w = iot_in_w ^ extand_iot_in_w;

assign dly_cnt_flag = (state == 0 || state == 13 || state == 8 || state == 9 || state == 16 || state == 17 | state == 18);
assign iot_data_flag = (in_en || state == 3 || state == 8 || state == 9 || state == 10);
assign key_flag = (state == 4 || state == 12 || state == 5 || state == 6 || state == 7);
assign cipherkey_flag = (state == 3 || state == 4 || state == 12);
assign iot_out_flag = (state == 11 || state == 14 || state == 15 || state == 20);
assign crc3_din_flag = (state == 16 || state == 17 || state == 18);
assign crc3_flag = (state == 17 || state == 18 || state == 19);
assign fn_sel_flag = (state == 1);


PERM_LUT perm_lut_0(.din(plaintext_w), .dout(perm_plaintext_w));
INV_PERM_LUT inv_p_lut_0(.din(plaintext_w), .dout(ciphertext_w));

PC1_LUT pc1_lut_0(.din(mainkey_w), .dout(cipherkey_tmp_w));
PC2_LUT pc2_lut_0(.din(cipherkey_w), .dout(key_tmp_w));

EXPAND_LUT expand_lut_0(.din(plaintext_right_w), .dout(expand_plaintext_w));
S1_BOX S1_0(.din(S1_in_w), .dout(S1_out_w));
S2_BOX S2_0(.din(S2_in_w), .dout(S2_out_w));
S3_BOX S3_0(.din(S3_in_w), .dout(S3_out_w));
S4_BOX S4_0(.din(S4_in_w), .dout(S4_out_w));
S5_BOX S5_0(.din(S5_in_w), .dout(S5_out_w));
S6_BOX S6_0(.din(S6_in_w), .dout(S6_out_w));
S7_BOX S7_0(.din(S7_in_w), .dout(S7_out_w));
S8_BOX S8_0(.din(S8_in_w), .dout(S8_out_w));
P_LUT p_lut_0(.din(F_in_w),.dout(F_out_w));

always @(*) begin
    crc3_din_w = crc3_din_r;
    if(state == 16)begin
        crc3_din_w = iot_in_w[127:124];
    end
    else if(state == 17)begin
        crc3_din_w = {crc3_w, iot_in_w[dly_cnt_r]};
    end
    else if(state == 18)begin
        crc3_din_w = {crc3_w, 1'b0};
    end
end

always @(*) begin
    crc3_w = crc3_r;
    if(state == 17 || state == 18 || state == 19)begin
        crc3_w[2] = crc3_din_r[2];
        crc3_w[1] = crc3_din_r[1] ^ crc3_din_r[3];
        crc3_w[0] = crc3_din_r[0] ^ crc3_din_r[3];
    end
end

always @(*) begin
    for(j=0; j<128; j=j+1)begin
        gray2bin_w[j] = ^(iot_in_w >> j);
    end
end

always @(*) begin
    valid_w = 0;
    if(state == 11 || state == 14 || state == 15 || state == 20)begin
        valid_w = 1;
    end
end

always @(*) begin
    iot_out_w = iot_out_r;
    if(state == 11)begin
        iot_out_w = {mainkey_w, plaintext_w};
    end
    else if(state == 14)begin
        iot_out_w = bin2gray_w;
    end
    else if(state == 15)begin
        iot_out_w = gray2bin_w;
    end
    else if(state == 20)begin
        iot_out_w = {125'b0, crc3_r};
    end
end

always @(*) begin
    cipherkey_w = cipherkey_r;
    if(state == 3)begin
        cipherkey_w = cipherkey_tmp_w;
    end
    else if(state == 4)begin
        if(dly_cnt_r == 0 || dly_cnt_r == 1 || dly_cnt_r == 8 || dly_cnt_r == 15)begin
            cipherkey_w = {cipherkey_left_clsh1_w, cipherkey_right_clsh1_w};
        end
        else begin
            cipherkey_w = {cipherkey_left_clsh2_w, cipherkey_right_clsh2_w};
        end
    end
    else if(state == 12)begin
        if(dly_cnt_r == 1 || dly_cnt_r == 8 || dly_cnt_r == 15)begin
            cipherkey_w = {cipherkey_left_crsh1_w, cipherkey_right_crsh1_w};
        end
        else if(dly_cnt_r == 0)begin
            cipherkey_w = {cipherkey_left_w, cipherkey_right_w};
        end
        else begin
            cipherkey_w = {cipherkey_left_crsh2_w, cipherkey_right_crsh2_w};
        end
    end
end

always @(*) begin
    key_w = key_r;
    if(state == 4 || state == 12)begin
        key_w = key_tmp_w;
    end
    else if(state == 5)begin
        key_w = key_r ^ expand_plaintext_w;
    end
    else if(state == 6)begin
        key_w = {key_r[47:32], S_out_w};
    end
    else if(state == 7)begin
        key_w = {key_r[47:32], F_out_w};
    end
end

always @(*) begin
    case (state)
        0: begin
            n_state = (dly_cnt_r == 15) ? 1 : 0;
        end 
        1: begin    //wait fetch
            n_state = 2;
        end
        2: begin    //function select
            case (fn_sel_r) 
                1: n_state = 3;
                2: n_state = 3;
                3: n_state = 16;
                4: n_state = 14;
                5: n_state = 15;
                default: n_state = 5'dx;
            endcase
        end
        3: begin    //Initial Permutate Plaintext, Compute cipherkey with PC1 mainkey
            n_state = (fn_sel_r[1]) ? 12 : 4;
        end
        4: begin    //Shift Left and Compute K with PC2 Table
            n_state = 5;
        end
        5: begin    //F Function I: Expand plaintext from 32 to 48-bit and XOR with key 
            n_state = 6;
        end
        6: begin    //F Function II: S_box, use key_r[31:0] as output of S_box
            n_state = 7;
        end
        7: begin    //compute F_out with P, use key_r[31:0] as output of F function
            n_state = (dly_cnt_r == 15) ? 9 : 8;
        end
        8: begin    //XOR F_out_w and Exchange L, R
            n_state = (fn_sel_r[1]) ? 12 : 4;
        end
        9: begin    //XOR F_out_w and does not exchange
            n_state = 10;
        end
        10: begin   //Final Permutate Plaintext
            n_state = 11;
        end
        11: begin   //Aggr Output
            n_state = 13;
        end
        12: begin   //Shift Right and Compute K with PC2 Table
            n_state = 5;
        end
        13: begin
            n_state = 0;
        end
        14: begin   //Aggr Output
            n_state = 13;
        end
        15: begin   //Aggr Output
            n_state = 13;
        end
        16: begin   //load iot_in_w[127:124]
            n_state = 17;
        end
        17: begin
            n_state = (dly_cnt_r == 0) ? 18 : 17;
        end
        18: begin
            n_state = (dly_cnt_r == 2) ? 19 : 18;
        end
        19: begin
            n_state = 20;
        end
        20: begin   //Aggr Output
            n_state = 13;
        end
	default: begin
	    n_state = 5'dx;
	end
    endcase
end

always @(*) begin
    dly_cnt_w = dly_cnt_r;
    if(state == 0 || state == 13)begin
        dly_cnt_w = (dly_cnt_r == 15) ? 0 : dly_cnt_r+1;
    end
    else if(state == 8 || state == 9)begin
        dly_cnt_w = (dly_cnt_r == 15) ? 0 : dly_cnt_r+1;
    end
    else if(state == 16)begin
        dly_cnt_w = 123;
    end
    else if(state == 17)begin
        dly_cnt_w = (dly_cnt_r == 0) ? dly_cnt_r : dly_cnt_r-1;
    end
    else if(state == 18)begin
        dly_cnt_w = (dly_cnt_r == 2) ? 0 : dly_cnt_r+1;
    end
end

always @(*) begin
    iot_data_w[0] = iot_data_r[0];
    iot_data_w[1] = iot_data_r[1];
    iot_data_w[2] = iot_data_r[2];
    iot_data_w[3] = iot_data_r[3];
    iot_data_w[4] = iot_data_r[4];
    iot_data_w[5] = iot_data_r[5];
    iot_data_w[6] = iot_data_r[6];
    iot_data_w[7] = iot_data_r[7];
    iot_data_w[8] = iot_data_r[8];
    iot_data_w[9] = iot_data_r[9];
    iot_data_w[10] = iot_data_r[10];
    iot_data_w[11] = iot_data_r[11];
    iot_data_w[12] = iot_data_r[12];
    iot_data_w[13] = iot_data_r[13];
    iot_data_w[14] = iot_data_r[14];
    iot_data_w[15] = iot_data_r[15];
    if(in_en)begin
        iot_data_w[0] = iot_in;
        iot_data_w[1] = iot_data_r[0];
        iot_data_w[2] = iot_data_r[1];
        iot_data_w[3] = iot_data_r[2];
        iot_data_w[4] = iot_data_r[3];
        iot_data_w[5] = iot_data_r[4];
        iot_data_w[6] = iot_data_r[5];
        iot_data_w[7] = iot_data_r[6];
        iot_data_w[8] = iot_data_r[7];
        iot_data_w[9] = iot_data_r[8];
        iot_data_w[10] = iot_data_r[9];
        iot_data_w[11] = iot_data_r[10];
        iot_data_w[12] = iot_data_r[11];
        iot_data_w[13] = iot_data_r[12];
        iot_data_w[14] = iot_data_r[13];
        iot_data_w[15] = iot_data_r[14];
    end
    else if(state == 3)begin
        iot_data_w[0] = perm_plaintext_w[7:0];
        iot_data_w[1] = perm_plaintext_w[15:8];
        iot_data_w[2] = perm_plaintext_w[23:16];
        iot_data_w[3] = perm_plaintext_w[31:24];
        iot_data_w[4] = perm_plaintext_w[39:32];
        iot_data_w[5] = perm_plaintext_w[47:40];
        iot_data_w[6] = perm_plaintext_w[55:48];
        iot_data_w[7] = perm_plaintext_w[63:56];
    end
    else if(state == 8)begin
        iot_data_w[0] = F_XOR_L_w[7:0];
        iot_data_w[1] = F_XOR_L_w[15:8];
        iot_data_w[2] = F_XOR_L_w[23:16];
        iot_data_w[3] = F_XOR_L_w[31:24];
        iot_data_w[4] = plaintext_right_w[7:0];
        iot_data_w[5] = plaintext_right_w[15:8];
        iot_data_w[6] = plaintext_right_w[23:16];
        iot_data_w[7] = plaintext_right_w[31:24];
    end
    else if(state == 9)begin
        iot_data_w[0] = plaintext_right_w[7:0];
        iot_data_w[1] = plaintext_right_w[15:8];
        iot_data_w[2] = plaintext_right_w[23:16];
        iot_data_w[3] = plaintext_right_w[31:24];
        iot_data_w[4] = F_XOR_L_w[7:0];
        iot_data_w[5] = F_XOR_L_w[15:8];
        iot_data_w[6] = F_XOR_L_w[23:16];
        iot_data_w[7] = F_XOR_L_w[31:24];
    end
    else if(state == 10)begin
        iot_data_w[0] = ciphertext_w[7:0];
        iot_data_w[1] = ciphertext_w[15:8];
        iot_data_w[2] = ciphertext_w[23:16];
        iot_data_w[3] = ciphertext_w[31:24];
        iot_data_w[4] = ciphertext_w[39:32];
        iot_data_w[5] = ciphertext_w[47:40];
        iot_data_w[6] = ciphertext_w[55:48];
        iot_data_w[7] = ciphertext_w[63:56];
    end
end

always @(posedge clk) begin
    if(fn_sel_flag)begin
        fn_sel_r <= fn_sel;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        state <= 0;
        valid_r <= 0;
    end
    else begin
        state <= n_state;
        valid_r <= valid_w;
    end
end

always @(posedge clk) begin
    if(crc3_din_flag)begin
        crc3_din_r <= crc3_din_w;
    end
end

always @(posedge clk) begin
    if(iot_data_flag)begin
        iot_data_r[0] <= iot_data_w[0];
        iot_data_r[1] <= iot_data_w[1];
        iot_data_r[2] <= iot_data_w[2];
        iot_data_r[3] <= iot_data_w[3];
        iot_data_r[4] <= iot_data_w[4];
        iot_data_r[5] <= iot_data_w[5];
        iot_data_r[6] <= iot_data_w[6];
        iot_data_r[7] <= iot_data_w[7];
        iot_data_r[8] <= iot_data_w[8];
        iot_data_r[9] <= iot_data_w[9];
        iot_data_r[10] <= iot_data_w[10];
        iot_data_r[11] <= iot_data_w[11];
        iot_data_r[12] <= iot_data_w[12];
        iot_data_r[13] <= iot_data_w[13];
        iot_data_r[14] <= iot_data_w[14];
        iot_data_r[15] <= iot_data_w[15];
    end
end

always @(posedge clk) begin
    if(cipherkey_flag)begin
        cipherkey_r <= cipherkey_w;
    end
end

always @(posedge clk) begin
    if(iot_out_flag)begin
        iot_out_r <= iot_out_w;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        dly_cnt_r <= 0;
    end
    else if(dly_cnt_flag)begin
        dly_cnt_r <= dly_cnt_w;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        key_r <= 0;
    end
    else if(key_flag)begin
        key_r <= key_w;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        crc3_r <= 0;
    end
    else if(crc3_flag)begin
        crc3_r <= crc3_w;
    end
end

endmodule
