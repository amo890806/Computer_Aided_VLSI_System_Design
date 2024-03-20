module core #( // DO NOT MODIFY!!!
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (   
    input                    i_clk,
    input                    i_rst_n,
    output  [ADDR_WIDTH-1:0] o_i_addr,
    input   [INST_WIDTH-1:0] i_i_inst,
    output                   o_d_we,
    output  [ADDR_WIDTH-1:0] o_d_addr,
    output  [DATA_WIDTH-1:0] o_d_wdata,
    input   [DATA_WIDTH-1:0] i_d_rdata,
    output  [           1:0] o_status,
    output                   o_status_valid
);

integer i;

reg [2:0] state, n_state;
reg signed [ADDR_WIDTH-1:0] o_i_addr_r, o_i_addr_w;
reg [INST_WIDTH-1:0] i_i_inst_r;
wire [INST_WIDTH-1:0] i_i_inst_w;
wire o_d_we_w;
wire [ADDR_WIDTH-1:0] o_d_addr_w;
wire [DATA_WIDTH-1:0] o_d_wdata_w;
wire o_status_valid_w;
reg [1:0] o_status_w;

reg signed [31:0] reg_r [0:31];
wire signed [31:0] reg_w;
wire signed [31:0] alu_din1_w, alu_din2_w;
reg signed [32:0] alu_dout_temp;
reg signed [2*DATA_WIDTH-1:0] alu_dout_mul_temp;
reg signed [31:0] alu_dout_r, alu_dout_w;
reg alu_pc_sel;

wire [5:0] opcode;
wire [4:0] s1, s2, s3;
wire signed [15:0] im;
wire [4:0] wb_addr;
wire R_I_flag;
wire branch_flag;
wire fp_flag;
reg alu_overflow_w, pc_overflow_w, overflow_r; 
wire overflow_w;
reg eof_w, eof_r; 

//FP16 ADDER / SUBTRACTER
wire SIGN_A, SIGN_B;
wire [7:0] EXPO_A, EXPO_B;
wire [23:0] MANT_A, MANT_B; //24bits = 23bits + implicit
wire [8:0] abs_expo_diff;
wire [278:0] extend_mant_A, extend_mant_B; // 24+255=279
wire [278:0] sh_mant_A, sh_mant_B;
wire [279:0] mant_S_temp;
assign SIGN_A = alu_din1_w[DATA_WIDTH-1];
assign EXPO_A = alu_din1_w[30:23];
assign MANT_A = {1'b1, alu_din1_w[22:0]};
assign SIGN_B = (opcode == `OP_FP_SUB) ? ~alu_din2_w[DATA_WIDTH-1] : alu_din2_w[DATA_WIDTH-1];
assign EXPO_B = alu_din2_w[30:23];
assign MANT_B = {1'b1, alu_din2_w[22:0]};
assign abs_expo_diff = (EXPO_A > EXPO_B) ? EXPO_A-EXPO_B : EXPO_B-EXPO_A;
assign extend_mant_A = {MANT_A, 255'b0};
assign extend_mant_B = {MANT_B, 255'b0};
assign sh_mant_A = (EXPO_A > EXPO_B) ? extend_mant_A : extend_mant_A>>abs_expo_diff;    //expo小的右移
assign sh_mant_B = (EXPO_A > EXPO_B) ? extend_mant_B>>abs_expo_diff : extend_mant_B;
assign mant_S_temp = (SIGN_A^SIGN_B) ? ((SIGN_A)?sh_mant_B-sh_mant_A:sh_mant_A-sh_mant_B) : sh_mant_A+sh_mant_B;
reg sign_S_r;
wire sign_S_w;  
reg [8:0] expo_S_w, expo_S_r;
reg [279:0] mant_S_w, mant_S_r;
wire carry, borrow;
wire guard, round, sticky, bias;
wire SIGN_S;
wire [7:0] EXPO_S;
wire [23:0] MANT_S;
assign sign_S_w = borrow || (SIGN_A & SIGN_B);
assign carry = mant_S_r[279] & !(SIGN_A^SIGN_B);
assign borrow = mant_S_temp[279] & (SIGN_A^SIGN_B);
assign guard = mant_S_w[255];
assign round = mant_S_w[254];
assign sticky = |mant_S_w[253:0];
assign bias = (round && sticky) || (guard && round && !sticky);
assign SIGN_S = sign_S_w; 
assign EXPO_S = (MANT_S[23]) ? expo_S_w+1 : expo_S_w;
assign MANT_S = mant_S_w[277:255]+bias;

//FP Multiplier
wire fp_mult_sign_S_w;
reg [8:0] fp_mult_expo_S_w;
reg [47:0] fp_mult_mant_S_w;
reg fp_mult_sign_S_r;
reg [8:0] fp_mult_expo_S_r;
reg [47:0] fp_mult_mant_S_r;
wire fp_mult_guard, fp_mult_round, fp_mult_sticky, fp_mult_bias;
wire FP_MULT_SIGN_S;
wire [7:0] FP_MULT_EXPO_S;
wire [23:0] FP_MULT_MANT_S; 
assign fp_mult_sign_S_w = SIGN_A ^ SIGN_B;
assign fp_mult_guard = fp_mult_mant_S_w[23];
assign fp_mult_round = fp_mult_mant_S_w[22];
assign fp_mult_sticky = fp_mult_mant_S_w[21:0];
assign fp_mult_bias = (fp_mult_round && fp_mult_sticky) || (fp_mult_guard && fp_mult_round && !fp_mult_sticky);
assign FP_MULT_SIGN_S = fp_mult_sign_S_w; 
assign FP_MULT_EXPO_S = (FP_MULT_MANT_S[23]) ? fp_mult_expo_S_w+1 : fp_mult_expo_S_w;
assign FP_MULT_MANT_S = fp_mult_mant_S_w[45:23]+fp_mult_bias; 

always @(*) begin
    fp_mult_expo_S_w = 0;
    if(state == 2)begin
        fp_mult_expo_S_w = EXPO_A + EXPO_B - 127;
    end
    else if(state == 3)begin
        fp_mult_expo_S_w = (fp_mult_mant_S_r[47]) ? fp_mult_expo_S_r+1 : fp_mult_expo_S_r;
    end
end

always @(*) begin
    fp_mult_mant_S_w = 0;
    if(state == 2)begin
        fp_mult_mant_S_w = MANT_A * MANT_B;
    end
    else if(state == 3)begin
        fp_mult_mant_S_w = (fp_mult_mant_S_r[47]) ? fp_mult_mant_S_r>>1 : fp_mult_mant_S_r;
    end
end

assign opcode = i_i_inst_r[31:26];
assign s1 = i_i_inst_r[15:11];
assign s2 = i_i_inst_r[25:21];
assign s3 = i_i_inst_r[20:16];
assign im = i_i_inst_r[15:0];
assign wb_addr = (R_I_flag) ? s3 : s1;
assign R_I_flag = (opcode == `OP_ADDI || opcode == `OP_LW || opcode == `OP_SW || opcode == `OP_BEQ || opcode == `OP_BNE) ? 1 : 0;   // I_type:1  / R_type:0
assign lw_sw_flag = (opcode == `OP_LW || opcode == `OP_SW) ? 1 : 0;
assign branch_flag = (opcode == `OP_BEQ || opcode == `OP_BNE) ? 1 : 0;
assign fp_flag = (opcode == `OP_FP_ADD || opcode == `OP_FP_SUB || opcode == `OP_FP_MUL) ? 1 : 0;
assign overflow_w = alu_overflow_w || pc_overflow_w;

assign alu_din1_w = reg_r[s2];
assign alu_din2_w = (R_I_flag) ? ((branch_flag)?reg_r[s3]:im) : reg_r[s3];

assign reg_w = (state == 5) ? ((opcode == `OP_LW)?i_d_rdata:alu_dout_r) : reg_r[wb_addr];

assign i_i_inst_w = (state == 1) ? i_i_inst : i_i_inst_r;
assign o_i_addr = o_i_addr_r;
assign o_d_we_w = (opcode == `OP_SW && state == 4) ? 1 : 0;
assign o_d_addr_w = alu_dout_r[7:0];
assign o_d_wdata_w = reg_r[s3];
assign o_status_valid_w = (state == 6 || state == 7);
assign o_d_we = o_d_we_w;
assign o_d_addr = o_d_addr_w;
assign o_d_wdata = o_d_wdata_w;
assign o_status_valid = o_status_valid_w;
assign o_status = o_status_w;

always @(*) begin
    expo_S_w = 0;
    if(state == 2)begin
        expo_S_w = (EXPO_A > EXPO_B) ? {1'b0, EXPO_A} : {1'b0, EXPO_B};
    end
    else if(state == 3)begin
        expo_S_w = (carry) ? expo_S_r+1 : ((mant_S_r[278])?expo_S_r:expo_S_r-1);
    end
end

always @(*) begin
    mant_S_w = 0;
    if(state == 2)begin
        mant_S_w = (borrow) ? ~(mant_S_temp)+1 : mant_S_temp;
    end
    else if(state == 3)begin
        mant_S_w = (carry) ? mant_S_r>>1 : ((mant_S_r[278])?mant_S_r:mant_S_r<<1);
    end
end

always @(*) begin
    if(eof_r || overflow_r)begin
        o_status_w = (overflow_r) ? 2 : 3;
    end
    else begin
        o_status_w = (R_I_flag) ? 1 : 0;
    end
end

always @(*) begin
    eof_w = eof_r;
    alu_pc_sel = 0;
    alu_overflow_w = 0;
    alu_dout_w = alu_dout_r;
    // if(state == 2)begin
        case (opcode)
            `OP_ADD: begin
                alu_dout_temp = alu_din1_w + alu_din2_w;
                alu_overflow_w = (alu_dout_temp > 32'sh7FFF_FFFF) || (alu_dout_temp < 32'sh8000_0000);
                alu_dout_w = alu_dout_temp[31:0];
            end 
            `OP_SUB: begin
                alu_dout_temp = alu_din1_w - alu_din2_w;
                alu_overflow_w = (alu_dout_temp > 32'sh7FFF_FFFF) || (alu_dout_temp < 32'sh8000_0000);
                alu_dout_w = alu_dout_temp[31:0];
            end
            `OP_MUL: begin
                alu_dout_mul_temp = alu_din1_w * alu_din2_w;
                alu_overflow_w = (alu_dout_mul_temp > 32'sh7FFF_FFFF) || (alu_dout_mul_temp < 32'sh8000_0000);
                // alu_overflow_w = alu_dout_mul_temp[63] ^ alu_dout_mul_temp[62];
                alu_dout_w = {alu_dout_mul_temp[63], alu_dout_mul_temp[30:0]};
            end
            `OP_FP_ADD, `OP_FP_SUB: begin
                alu_dout_w = {SIGN_S, EXPO_S, MANT_S[22:0]};
            end
            `OP_FP_MUL: begin
                alu_dout_w = {FP_MULT_SIGN_S, FP_MULT_EXPO_S, FP_MULT_MANT_S[22:0]};
            end
            `OP_ADDI: begin
                alu_dout_temp = alu_din1_w + alu_din2_w;
                alu_overflow_w = (alu_dout_temp > 32'sh7FFF_FFFF) || (alu_dout_temp < 32'sh8000_0000);
                alu_dout_w = alu_dout_temp[31:0];
            end 
            `OP_LW, `OP_SW: begin
                alu_dout_temp = alu_din1_w + alu_din2_w;
                alu_overflow_w = alu_dout_temp > 255 || alu_dout_temp < 0;
                alu_dout_w = alu_dout_temp[31:0];
            end 
            `OP_AND: begin
                alu_dout_w = alu_din1_w & alu_din2_w;
            end
            `OP_OR: begin
                alu_dout_w = alu_din1_w | alu_din2_w;
            end
            `OP_NOR: begin
                alu_dout_w = ~(alu_din1_w | alu_din2_w);
            end
            `OP_BEQ: begin
                alu_pc_sel = (alu_din1_w == alu_din2_w);
            end
            `OP_BNE: begin
                alu_pc_sel = (alu_din1_w != alu_din2_w);
            end
            `OP_SLT: begin
                alu_dout_w = alu_din1_w < alu_din2_w;
            end
            `OP_SLL: begin
                alu_dout_w = alu_din1_w << alu_din2_w;
            end
            `OP_SRL: begin
                alu_dout_w = alu_din1_w >> alu_din2_w;
            end
            `OP_EOF: begin
                eof_w = 1;
            end
            default: begin
                alu_dout_temp = 33'bx;
                alu_dout_w = 32'bx;
                alu_overflow_w = 1'bx;
            end 
        endcase
    // end
end

always @(*) begin
    case (state)
        0: begin
            n_state = 1;
        end 
        1: begin
            n_state = 2;
        end
        2: begin
            n_state = (branch_flag) ? 6 : ((lw_sw_flag) ? 4 : 5);
            if(fp_flag)begin
                n_state = 3;
            end
        end   
        3: begin    //DATA to RF
            n_state = (mant_S_r[278]) ? 5 : 3;
            if(opcode == `OP_FP_MUL)begin
                n_state = 5;
            end
        end  
        4: begin    //DATA to RF
            n_state = (opcode == `OP_SW) ? 6 : 5;
        end  
        5: begin    //WB
            n_state = 6;
        end  
        6: begin    //PC
            n_state = (eof_r || overflow_r) ? 7 : 1;
        end  
        7: begin    //END
            n_state = 7;
        end  
        default: n_state = 0;
    endcase
end

always @(*) begin
    o_i_addr_w = o_i_addr_r;
    pc_overflow_w = 0;
    if(state == 2)begin
        o_i_addr_w = (alu_pc_sel) ? o_i_addr_r+im  : o_i_addr_r+4;
        pc_overflow_w = (o_i_addr_w > 4095 || o_i_addr_w < 0);
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        state <= 0;
        o_i_addr_r <= 0;
        i_i_inst_r <= 0;
        alu_dout_r <= 0;
        overflow_r <= 0;
        eof_r <= 0;
        expo_S_r <= 0;
        mant_S_r <= 0;
        fp_mult_sign_S_r <= 0;
        fp_mult_expo_S_r <= 0;
        fp_mult_mant_S_r <= 0;
        for(i=0; i<32; i=i+1)begin
            reg_r[i] <= 0;
        end
    end
    else begin
        state <= n_state;
        o_i_addr_r <= o_i_addr_w;
        i_i_inst_r <= i_i_inst_w;
        alu_dout_r <= alu_dout_w;
        overflow_r <= overflow_w;
        eof_r <= eof_w;
        expo_S_r <= expo_S_w;
        mant_S_r <= mant_S_w;
        fp_mult_sign_S_r <= fp_mult_sign_S_w;
        fp_mult_expo_S_r <= fp_mult_expo_S_w;
        fp_mult_mant_S_r <= fp_mult_mant_S_w;
        reg_r[wb_addr] <= reg_w;
    end
end



endmodule