module alu #(
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter INST_W = 4,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                     i_clk,
    input                     i_rst_n,
    input signed [DATA_W-1:0] i_data_a,
    input signed [DATA_W-1:0] i_data_b,
    input        [INST_W-1:0] i_inst,
    output                    o_valid,
    output                    o_busy,
    output       [DATA_W-1:0] o_data
);

integer i;

reg [3:0] cnt;
reg [1:0] state, n_state;
reg o_valid_w, o_valid_r;
wire [INST_W-1:0] i_inst_w;
reg [INST_W-1:0] i_inst_r;
wire signed [DATA_W-1:0] i_data_a_w, i_data_b_w;
reg signed [DATA_W-1:0] i_data_a_r, i_data_b_r;
reg signed [DATA_W-1:0] o_data_w;
reg signed [DATA_W-1:0] o_data_r;
reg o_busy_r;

wire signed [DATA_W:0] add, sub;
wire signed [2*DATA_W-1:0] mul;
wire signed [21:0] mul_trunc_temp;
wire signed [DATA_W-1:0] mul_rnd;
wire signed [DATA_W:0] mac;
wire [4:0] mask;

wire signed [DATA_W-1:0] gelu_stg1_rnd;
wire signed [2*DATA_W-1:0] rhs1_1;
wire signed [40:0] rhs1_2;
wire signed [41:0] rhs1;
wire signed [25:0] lhs1;
wire signed [67:0] gelu_stg1;
wire signed [28:0] gelu_stg1_trunc_temp;
assign rhs1_1 = i_data_a_r * i_data_a_r;
assign rhs1_2 = rhs1_1 * 23;
assign rhs1 = rhs1_2 + 536870912;
assign lhs1 = i_data_a_r * 817;
assign gelu_stg1 = lhs1 * rhs1;
assign gelu_stg1_trunc_temp = gelu_stg1[67:39]+gelu_stg1[38];
assign gelu_stg1_rnd = (gelu_stg1[67]) ? ((gelu_stg1_trunc_temp < 16'sh8000)?16'h8000:{gelu_stg1_trunc_temp[28], gelu_stg1_trunc_temp[14:0]}) : ((gelu_stg1_trunc_temp > 16'sh7FFF)?16'h7FFF:{gelu_stg1_trunc_temp[28], gelu_stg1_trunc_temp[14:0]});

wire signed [DATA_W:0] gelu_stg2;
wire [DATA_W-1:0] abs_gelu_stg1_rnd;
wire signed [DATA_W-1:0] gelu_stg2_rnd;
wire signed [25:0] gelu_stg2_1;
wire signed [26:0] gelu_stg2_2;
wire signed [DATA_W:0] gelu_stg2_trunc_temp;
assign abs_gelu_stg1_rnd = (gelu_stg1_rnd[DATA_W-1]) ? ~(gelu_stg1_rnd)+1 : gelu_stg1_rnd;
assign gelu_stg2_1 = gelu_stg1_rnd * 512;
assign gelu_stg2_2 = (gelu_stg2_1[25]) ? gelu_stg2_1 - 262144 : gelu_stg2_1 + 262144;
assign gelu_stg2_trunc_temp = gelu_stg2_2[26:10]+gelu_stg2_2[9];
assign gelu_stg2 = (abs_gelu_stg1_rnd < 1536) ? ((abs_gelu_stg1_rnd < 512)?{gelu_stg1_rnd[DATA_W-1], gelu_stg1_rnd}:gelu_stg2_trunc_temp) : ((gelu_stg1_rnd[DATA_W-1]) ? -1024 : 1024);
assign gelu_stg2_rnd = (gelu_stg1_rnd[DATA_W-1]) ? ((gelu_stg2_trunc_temp < 16'sh8000)?16'h8000:{gelu_stg2[DATA_W], gelu_stg2[14:0]}) : ((gelu_stg2_trunc_temp > 16'sh7FFF)?16'h7FFF:{gelu_stg2[DATA_W], gelu_stg2[14:0]});

wire signed [DATA_W-1:0] gelu_stg3_rnd;
wire signed [DATA_W:0] rhs3;
wire signed [25:0] lhs3;
wire signed [42:0] gelu_stg3;
wire signed [22:0] gelu_stg3_trunc_temp;
assign rhs3 = 1024 + gelu_stg2_rnd;
assign lhs3 = 512 * i_data_a_r;
assign gelu_stg3 = lhs3*rhs3;
assign gelu_stg3_trunc_temp = gelu_stg3[42:20]+gelu_stg3[19];
assign gelu_stg3_rnd = (gelu_stg3[42]) ? ((gelu_stg3_trunc_temp < 16'sh8000)?16'h8000:{gelu_stg3_trunc_temp[22], gelu_stg3_trunc_temp[14:0]}) : ((gelu_stg3_trunc_temp > 16'sh7FFF)?16'h7FFF:{gelu_stg3_trunc_temp[22], gelu_stg3_trunc_temp[14:0]});

//FP16 ADDER / SUBTRACTER
wire SIGN_A, SIGN_B;
wire [4:0] EXPO_A, EXPO_B;
wire [10:0] MANT_A, MANT_B; //11bits = 10bits + implicit 1
wire [5:0] abs_expo_diff;
wire [18:0] extend_mant_A, extend_mant_B;
wire [18:0] sh_mant_A, sh_mant_B;
wire [19:0] mant_S_temp;

reg sign_S_r;
wire sign_S_w;
reg [5:0] expo_S_w, expo_S_r;
reg [19:0] mant_S_w, mant_S_r;
wire carry, borrow;
wire guard, round, sticky, bias;
wire SIGN_S;
wire [4:0] EXPO_S;
wire [10:0] MANT_S;

assign SIGN_A = i_data_a_r[DATA_W-1];
assign EXPO_A = i_data_a_r[14:10];
assign MANT_A = {1'b1, i_data_a_r[9:0]};
assign SIGN_B = (i_inst_r == 9) ? !i_data_b_r[DATA_W-1] : i_data_b_r[DATA_W-1];
assign EXPO_B = i_data_b_r[14:10];
assign MANT_B = {1'b1, i_data_b_r[9:0]};
assign abs_expo_diff = (EXPO_A > EXPO_B) ? EXPO_A-EXPO_B : EXPO_B-EXPO_A;
assign extend_mant_A = {MANT_A, 8'b0};
assign extend_mant_B = {MANT_B, 8'b0};
assign sh_mant_A = (EXPO_A > EXPO_B) ? extend_mant_A : extend_mant_A>>abs_expo_diff;    //expo小的右移
assign sh_mant_B = (EXPO_A > EXPO_B) ? extend_mant_B>>abs_expo_diff : extend_mant_B;
assign mant_S_temp = (SIGN_A^SIGN_B) ? ((SIGN_A)?sh_mant_B-sh_mant_A:sh_mant_A-sh_mant_B) : sh_mant_A+sh_mant_B;


assign sign_S_w = borrow || (SIGN_A & SIGN_B);
assign carry = mant_S_r[19] & !(SIGN_A^SIGN_B);
assign borrow = mant_S_temp[19] & (SIGN_A^SIGN_B);
assign guard = mant_S_w[8];
assign round = mant_S_w[7];
assign sticky = |mant_S_w[6:0];
assign bias = (round && sticky) || (guard && round && !sticky);
assign SIGN_S = sign_S_w; 
assign EXPO_S = (MANT_S[10]) ? expo_S_w+1 : expo_S_w;
assign MANT_S = mant_S_w[17:8]+bias;

assign add = i_data_a_r + i_data_b_r;
assign sub = i_data_a_r - i_data_b_r;
assign mul = i_data_a_r * i_data_b_r;
assign mul_trunc_temp = mul[31:10]+mul[9];
assign mul_rnd = (mul[2*DATA_W-1]) ? ((mul_trunc_temp < 16'sh8000)?16'h8000:{mul_trunc_temp[21], mul_trunc_temp[14:0]}) : ((mul_trunc_temp > 16'sh7FFF)?16'h7FFF:{mul_trunc_temp[21], mul_trunc_temp[14:0]});
assign mac = o_data_r + mul_rnd;

assign mask = i_data_a_r[0]+i_data_a_r[1]+i_data_a_r[2]+i_data_a_r[3]+
            i_data_a_r[4]+i_data_a_r[5]+i_data_a_r[6]+i_data_a_r[7]+
            i_data_a_r[8]+i_data_a_r[9]+i_data_a_r[10]+i_data_a_r[11]+
            i_data_a_r[12]+i_data_a_r[13]+i_data_a_r[14]+i_data_a_r[15];
assign i_inst_w = (state == 2) ? i_inst : i_inst_r;
assign i_data_a_w = (state == 2) ? i_data_a : i_data_a_r;
assign i_data_b_w = (state == 2) ? i_data_b : i_data_b_r;
assign o_busy = o_busy_r;
assign o_data = o_data_r;
assign o_valid = o_valid_r;

//comb
always @(*) begin
    expo_S_w = 0;
    if(cnt == 0)begin //state == 3
        expo_S_w = (EXPO_A > EXPO_B) ? {1'b0, EXPO_A} : {1'b0, EXPO_B};
    end
    else begin
        expo_S_w = (carry) ? expo_S_r+1 : ((mant_S_r[18])?expo_S_r:expo_S_r-1);
    end
end

always @(*) begin
    mant_S_w = 0;
    if(cnt == 0)begin
        mant_S_w = (borrow) ? ~(mant_S_temp)+1 : mant_S_temp;
    end
    else begin
        mant_S_w = (carry) ? mant_S_r>>1 : ((mant_S_r[18])?mant_S_r:mant_S_r<<1);
    end
end

always @(*) begin
    case (state)
        0: n_state = 1;
        1: n_state = 2;
        2: n_state = 3;
        3: n_state = (o_valid_w) ? 1 : 3;
    endcase
end

always @(*) begin
    if(state == 1)begin
        o_busy_r = 0;
    end
    else begin
        o_busy_r = 1;
    end
end

always @(*) begin
    if(state == 3)
        case (i_inst_r)
            0: o_valid_w = 1;
            1: o_valid_w = 1;
            2: o_valid_w = 1;
            3: o_valid_w = 1;
            4: o_valid_w = 1;
            5: o_valid_w = (i_data_a_r[15-cnt] == 1);
            6: o_valid_w = (cnt == mask-1);
            7: o_valid_w = (cnt == i_data_b_r-1);
            8,9: o_valid_w = (cnt != 0 && mant_S_r[18]);
            default: o_valid_w = 0;
        endcase
    else begin
        o_valid_w = 0; 
    end
end

always @(*) begin
    if(state == 3)begin
        case (i_inst_r)
            0: begin
                o_data_w = (add[DATA_W]) ? ((add < 16'sh8000)?16'h8000:{add[DATA_W], add[14:0]}) : ((add > 16'sh7FFF)?16'h7FFF:{add[DATA_W], add[14:0]});
            end
            1: begin
                o_data_w = (sub[DATA_W]) ? ((sub < 16'sh8000)?16'h8000:{sub[DATA_W], sub[14:0]}) : ((sub > 16'sh7FFF)?16'h7FFF:{sub[DATA_W], sub[14:0]});
            end
            2: begin
                o_data_w = mul_rnd;
            end
            3: begin
                o_data_w = (mac[DATA_W]) ? ((mac < 16'sh8000)?16'h8000:{mac[DATA_W], mac[14:0]}) : ((mac > 16'sh7FFF)?16'h7FFF:{mac[DATA_W], mac[14:0]});
            end
            4: begin
                o_data_w = gelu_stg3_rnd;
            end
            5: begin
                o_data_w = {12'b0, cnt};
            end
            6: begin
                o_data_w[0] = (cnt == 0) ? ~i_data_b_r[15] : ~o_data_r[15];
                for(i=0; i<DATA_W-1; i=i+1)begin
                    o_data_w[i+1] = (cnt == 0) ?  i_data_b_r[i] : o_data_r[i];
                end
            end
            7: begin
                o_data_w[0] = (cnt == 0) ? (((i_data_a_r[15]^i_data_a_r[13])^i_data_a_r[12])^i_data_a_r[10]) : (((o_data_r[15]^o_data_r[13])^o_data_r[12])^o_data_r[10]);
                for(i=0; i<DATA_W-1; i=i+1)begin
                    o_data_w[i+1] = (cnt == 0) ?  i_data_a_r[i] : o_data_r[i];
                end
            end 
            8,9: begin
                o_data_w = {SIGN_S, EXPO_S, MANT_S[9:0]};
            end
            default: o_data_w = 0;
        endcase
    end
    else begin
        o_data_w = o_data_r;
    end
end

//seq
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        cnt <= 0;
    end
    else begin
        if(state == 3)begin
            case (i_inst)
                5: cnt <= (i_data_a_r[15-cnt] == 1) ? 0 : cnt+1;
                6: cnt <= (cnt == mask-1) ? 0 : cnt+1;
                7: cnt <= (cnt == i_data_b_r-1) ? 0 : cnt+1;
                8,9: cnt <= (cnt != 0 && mant_S_r[18]) ? 0 : cnt+1;
            endcase
        end
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        state <= 0;
        sign_S_r <= 0;
        expo_S_r <= 0;
        mant_S_r <= 0;
        i_inst_r <= 0;
        i_data_a_r <= 0;
        i_data_b_r <= 0;
        o_valid_r <= 0;
        o_data_r <= 0;
    end
    else begin
        state <= n_state;
        sign_S_r <= sign_S_w;
        expo_S_r <= expo_S_w;
        mant_S_r <= mant_S_w;
        i_inst_r <= i_inst_w;
        i_data_a_r <= i_data_a_w;
        i_data_b_r <= i_data_b_w;
        o_valid_r <= o_valid_w;
        o_data_r <= o_data_w;
    end
end
    

endmodule
