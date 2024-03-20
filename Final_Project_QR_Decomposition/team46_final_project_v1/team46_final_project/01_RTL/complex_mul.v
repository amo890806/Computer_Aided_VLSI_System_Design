module complex_mul_pipe2_fast
#(
    parameter i_int = 2, // bits of integer part of input
    parameter i_wide = 20,
    parameter o_int = 2, // bits of integer part of output
    parameter o_wide = 20
)
(
    input i_clk,
    input i_rst,
    input i_conjugate,
    input i_valid,
    input [i_wide - 1:0] i_R0,
    input [i_wide - 1:0] i_I0,
    input [i_wide - 1:0] i_R1,
    input [i_wide - 1:0] i_I1,
    output [o_wide - 1:0] o_Rout,
    output [o_wide - 1:0] o_Iout
);
    // area: mul * 4, add * 2
    // critical path: mul

    // pipeline stage 0
    reg signed [i_wide - 1:0] i_R0_r,i_I0_r,i_R1_r,i_I1_r; // s2:13

    // pipeline stage 1
    reg signed [2*i_wide - 1 :0] R0R1_r,R0I1_r,I0R1_r,I0I1_r,R0R1_w,R0I1_w,I0R1_w,I0I1_w; // s4.26
    reg signed [o_wide - 1 :0] R0R1_round, R0I1_round, I0R1_round, I0I1_round; // s2.13

    // output stage
    reg [o_wide-1 :0] o_Rout_r, o_Iout_r, o_Rout_w, o_Iout_w; // s2.13

    assign o_Rout = o_Rout_r;
    assign o_Iout = o_Iout_r;

    // wire gclk = i_clk & i_valid;

    always @(*) begin
        // stage 0
        R0R1_w = i_R0_r * i_R1_r; //R0*R1
        R0I1_w = i_R0_r * i_I1_r; //R0*I1
        I0R1_w = i_I0_r * i_R1_r; //I0*R0
        I0I1_w = i_I0_r * i_I1_r; //I0*I1

        // stage 1
        R0R1_round = R0R1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  R0R1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        R0I1_round = R0I1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  R0I1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        I0R1_round = I0R1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  I0R1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        I0I1_round = I0I1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  I0I1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        o_Rout_w = (i_conjugate) ? R0R1_round + I0I1_round : R0R1_round - I0I1_round; //R0R1 + I0I1 (conjugate)
        o_Iout_w = (i_conjugate) ? R0I1_round - I0R1_round : R0I1_round + I0R1_round; //R0I1 - I0R1 (conjugate)


    end

    always @(posedge i_clk) begin
        i_R0_r <= i_R0;
        i_I0_r <= i_I0;
        i_R1_r <= i_R1;
        i_I1_r <= i_I1;
        R0R1_r <= R0R1_w;
        R0I1_r <= R0I1_w;
        I0R1_r <= I0R1_w;
        I0I1_r <= I0I1_w;
        o_Rout_r <= o_Rout_w;
        o_Iout_r <= o_Iout_w;
    end
endmodule

// module complex_mul_pipe2_dw
// #(
//     parameter i_int = 2, // bits of integer part of input
//     parameter i_wide = 20,
//     parameter o_int = 2, // bits of integer part of output
//     parameter o_wide = 20
// )
// (
//     input i_clk,
//     input i_rst_n,
//     input i_conjugate,
//     input [i_wide - 1:0] i_R0,
//     input [i_wide - 1:0] i_I0,
//     input [i_wide - 1:0] i_R1,
//     input [i_wide - 1:0] i_I1,
//     output [o_wide - 1:0] o_Rout,
//     output [o_wide - 1:0] o_Iout
// );
//     // area: mul * 4, add * 2
//     // critical path: mul

//     // pipeline stage 0
//     reg signed [i_wide - 1:0] i_R0_r,i_I0_r,i_R1_r,i_I1_r; // s2:13

//     // pipeline stage 1
//     reg signed [2*i_wide - 1 :0] R0R1_r,R0I1_r,I0R1_r,I0I1_r,R0R1_w,R0I1_w,I0R1_w,I0I1_w; // s4.26
//     reg signed [o_wide - 1 :0] R0R1_round, R0I1_round, I0R1_round, I0I1_round; // s2.13

//     // output stage
//     reg [o_wide-1 :0] o_Rout_r, o_Iout_r, o_Rout_w, o_Iout_w; // s2.13

//     assign o_Rout = o_Rout_r;
//     assign o_Iout = o_Iout_r;

//     // use dw instead of regular mul
//     DW02_mult_2_stage_inst 
//     #(
//         .A_width(i_wide),
//         .B_width(i_wide)
//     )
//     m0
//     ( 
//         .inst_A(i_R0_r), 
//         .inst_B(i_R1_r), 
//         .inst_TC(1'b1), // signed
//         .inst_CLK(i_clk), 
//         .PRODUCT_inst(R0R1_w) 
//     );
//     DW02_mult_2_stage_inst 
//     #(
//         .A_width(i_wide),
//         .B_width(i_wide)
//     )
//     m1
//     ( 
//         .inst_A(i_R0_r), 
//         .inst_B(i_I1_r), 
//         .inst_TC(1'b1), // signed
//         .inst_CLK(i_clk), 
//         .PRODUCT_inst(R0I1_w) 
//     );
//     DW02_mult_2_stage_inst 
//     #(
//         .A_width(i_wide),
//         .B_width(i_wide)
//     )
//     m2
//     ( 
//         .inst_A(i_I0_r), 
//         .inst_B(i_R1_r), 
//         .inst_TC(1'b1), // signed
//         .inst_CLK(i_clk), 
//         .PRODUCT_inst(I0R1_w) 
//     );
//     DW02_mult_2_stage_inst 
//     #(
//         .A_width(i_wide),
//         .B_width(i_wide)
//     )
//     m3
//     ( 
//         .inst_A(i_I0_r), 
//         .inst_B(i_I1_r), 
//         .inst_TC(1'b1), // signed
//         .inst_CLK(i_clk), 
//         .PRODUCT_inst(I0I1_w) 
//     );

//     always @(*) begin
//         // stage 0
//         /*
//         R0R1_w = i_R0_r * i_R1_r; //R0*R1
//         R0I1_w = i_R0_r * i_I1_r; //R0*I1
//         I0R1_w = i_I0_r * i_R1_r; //I0*R0
//         I0I1_w = i_I0_r * i_I1_r; //I0*I1
//         */

//         // stage 1
//         R0R1_round = R0R1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  R0R1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
//         R0I1_round = R0I1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  R0I1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
//         I0R1_round = I0R1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  I0R1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
//         I0I1_round = I0I1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  I0I1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
//         o_Rout_w = (i_conjugate) ? R0R1_round + I0I1_round : R0R1_round - I0I1_round; //R0R1 + I0I1 (conjugate)
//         o_Iout_w = (i_conjugate) ? R0I1_round - I0R1_round : R0I1_round + I0R1_round; //R0I1 - I0R1 (conjugate)


//     end

//     always @(posedge i_clk or negedge i_rst_n) begin
//         if (~i_rst_n) begin
//             i_R0_r <= 0;
//             i_I0_r <= 0;
//             i_R1_r <= 0;
//             i_I1_r <= 0;
//             R0R1_r <= 0;
//             R0I1_r <= 0;
//             I0R1_r <= 0;
//             I0I1_r <= 0;
//             o_Rout_r <= 0;
//             o_Iout_r <= 0;

//         end
//         else begin
//             i_R0_r <= i_R0;
//             i_I0_r <= i_I0;
//             i_R1_r <= i_R1;
//             i_I1_r <= i_I1;
//             R0R1_r <= R0R1_w;
//             R0I1_r <= R0I1_w;
//             I0R1_r <= I0R1_w;
//             I0I1_r <= I0I1_w;
//             o_Rout_r <= o_Rout_w;
//             o_Iout_r <= o_Iout_w;

//         end
//     end
// endmodule

// module DW02_mult_2_stage_inst
// #(
//     parameter A_width = 20,
//     parameter B_width = 20
// )
// ( inst_A, inst_B, inst_TC, inst_CLK, PRODUCT_inst );


//   input [A_width-1 : 0] inst_A;
//   input [B_width-1 : 0] inst_B;
//   input inst_TC;
//   input inst_CLK;
//   output [A_width+B_width-1 : 0] PRODUCT_inst;

//   // Instance of DW02_mult_2_stage
//   DW02_mult_2_stage #(A_width, B_width)
//     U1 ( .A(inst_A),   .B(inst_B),   .TC(inst_TC), 
//          .CLK(inst_CLK),   .PRODUCT(PRODUCT_inst) );

// endmodule

/*
module complex_mul_pipe2_slow
#(
    parameter i_int = 2, // bits of integer part of input
    parameter i_wide = 15,
    parameter o_int = 2, // bits of integer part of output
    parameter o_wide = 15
)
(
    input i_clk,
    input i_rst_n,
    input [i_wide - 1:0] i_R0,
    input [i_wide - 1:0] i_I0,
    input [i_wide - 1:0] i_R1,
    input [i_wide - 1:0] i_I1,
    output [o_wide - 1:0] o_Rout,
    output [o_wide - 1:0] o_Iout
);
    // area: mul * 3, add * 5
    // critical path: mul + add/sub

    // pipeline stage 0
    reg signed [i_wide - 1:0] i_R0_r,i_I0_r,i_R1_r,i_I1_r; // s1.22
    // comb stage 0
    reg signed [i_wide :0] add_r0i0,sub_r0i0,sub_i1r1; // s2.22

    // pipeline stage 1
    reg signed [i_wide :0] add_r0i0_stage1_r,add_r0i0_stage1_w,sub_i1r1_stage1_r,sub_i1r1_stage1_w; // s2.22
    reg signed [2*i_wide :0] a_stage1_r, a_stage1_w; // s3.44
    reg signed [i_wide - 1:0] R0_stage1_r, I1_stage1_r; // s1.22
    // comb stage 1
    reg signed [2*i_wide :0] b_stage1; // s3.44
    reg signed [2*i_wide :0] c_stage1; // s3.44
    reg signed [o_wide-1 :0] a_round,b_round,c_round; // s1.22
    

    // output stage
    reg [o_wide-1 :0] o_Rout_r, o_Iout_r, o_Rout_w, o_Iout_w;

    assign o_Rout = o_Rout_r;
    assign o_Iout = o_Iout_r;


    always @(*) begin
        // stage 0
        add_r0i0 = i_R0_r + i_I0_r;     //(R0+I0)
        sub_r0i0 = i_R0_r - i_I0_r;     //(R0-I0)
        sub_i1r1 = i_I1_r - i_R1_r;     //(I1-R1)
        a_stage1_w = sub_r0i0 * i_R1_r; //R1(R0-I0) = R1R0-R1I0
        add_r0i0_stage1_w = add_r0i0;
        sub_i1r1_stage1_w = sub_i1r1;

        // stage 1
        b_stage1 = sub_i1r1_stage1_r * R0_stage1_r; //(I1-R1)*R0 = R0I1 - R0R1
        c_stage1 = add_r0i0_stage1_r * I1_stage1_r; //(R0+I0)*I1 = R0I1 + I0I1

        a_round = a_stage1_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  a_stage1_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        b_round = b_stage1[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  b_stage1[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        c_round = c_stage1[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  c_stage1[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        o_Rout_w = c_round - b_round;
        o_Iout_w = a_round + b_round;


    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            R0_stage1_r <= 0;
            I1_stage1_r <= 0;
            a_stage1_r <= 0;
            i_R0_r <= 0;
            i_I0_r <= 0;
            i_R1_r <= 0;
            i_I1_r <= 0;
            add_r0i0_stage1_r <= 0;
            sub_i1r1_stage1_r <= 0;
            o_Rout_r <= 0;
            o_Iout_r <= 0;

        end
        else begin
            R0_stage1_r <= i_R0_r;
            I1_stage1_r <= i_I1_r;
            a_stage1_r <= a_stage1_w;
            i_R0_r <= i_R0;
            i_I0_r <= i_I0;
            i_R1_r <= i_R1;
            i_I1_r <= i_I1;
            add_r0i0_stage1_r <= add_r0i0_stage1_w;
            sub_i1r1_stage1_r <= sub_i1r1_stage1_w;
            o_Rout_r <= o_Rout_w;
            o_Iout_r <= o_Iout_w;

        end
    end

endmodule

module complex_mul_pipe3
#(
    parameter i_int = 2, // bits of integer part of input
    parameter i_wide = 15,
    parameter o_int = 2, // bits of integer part of output
    parameter o_wide = 15
)
(
    input i_clk,
    input i_rst_n,
    input [i_wide - 1:0] i_R0,
    input [i_wide - 1:0] i_I0,
    input [i_wide - 1:0] i_R1,
    input [i_wide - 1:0] i_I1,
    output [o_wide - 1:0] o_Rout,
    output [o_wide - 1:0] o_Iout
);
    // area: mul * 3, add * 5
    // critical path: mul
    // latency: 4 stage.
    // output at 4th posedge after input

    // pipeline stage 0
    reg signed [i_wide - 1:0] i_R0_r,i_I0_r,i_R1_r,i_I1_r; // s1.22
    // comb stage 0
    reg signed [i_wide :0] add_r0i0,sub_r0i0,sub_i1r1; // s2.22

    // pipeline stage 1
    reg signed [i_wide :0] add_r0i0_stage1_r,add_r0i0_stage1_w,sub_i1r1_stage1_r,sub_i1r1_stage1_w,sub_r0i0_stage1_r,sub_r0i0_stage1_w; // s2.22
    reg signed [i_wide - 1:0] R0_stage1_r, I1_stage1_r, R1_stage1_r; // s1.22
    // comb stage 1
    reg signed [2*i_wide :0] a_stage1; // s3.44
    reg signed [2*i_wide :0] b_stage1; // s3.44
    reg signed [2*i_wide :0] c_stage1; // s3.44

    // pipeline stage 2
    reg signed [2*i_wide :0] a_stage2_r; // s3.44
    reg signed [2*i_wide :0] b_stage2_r; // s3.44
    reg signed [2*i_wide :0] c_stage2_r; // s3.44
    reg signed [o_wide-1 :0] a_round_stage2,b_round_stage2,c_round_stage2; // s1.22
    

    // output stage
    reg [o_wide-1 :0] o_Rout_r, o_Iout_r, o_Rout_w, o_Iout_w;

    assign o_Rout = o_Rout_r;
    assign o_Iout = o_Iout_r;


    always @(*) begin
        // stage 0
        add_r0i0 = i_R0_r + i_I0_r;     //(R0+I0)
        sub_r0i0 = i_R0_r - i_I0_r;     //(R0-I0)
        sub_i1r1 = i_I1_r - i_R1_r;     //(I1-R1)
        
        add_r0i0_stage1_w = add_r0i0;
        sub_i1r1_stage1_w = sub_i1r1;
        sub_r0i0_stage1_w = sub_r0i0;

        // stage 1
        a_stage1 = sub_r0i0_stage1_r * R1_stage1_r; //(R0-I0)*R1 = R1R0 - R1I0
        b_stage1 = sub_i1r1_stage1_r * R0_stage1_r; //(I1-R1)*R0 = R0I1 - R0R1
        c_stage1 = add_r0i0_stage1_r * I1_stage1_r; //(R0+I0)*I1 = R0I1 + I0I1

        // stage 2
        a_round_stage2 = a_stage2_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  a_stage2_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        b_round_stage2 = b_stage2_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  b_stage2_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        c_round_stage2 = c_stage2_r[2*i_wide - (i_int*2 + 1 - o_int) -: o_wide] +  c_stage2_r[2*i_wide - (i_int*2 + 1 - o_int) - o_wide];
        o_Rout_w = c_round_stage2 - b_round_stage2;
        o_Iout_w = a_round_stage2 + b_round_stage2;


    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            R0_stage1_r <= 0;
            I1_stage1_r <= 0;
            R1_stage1_r <= 0;
            i_R0_r <= 0;
            i_I0_r <= 0;
            i_R1_r <= 0;
            i_I1_r <= 0;
            add_r0i0_stage1_r <= 0;
            sub_i1r1_stage1_r <= 0;
            sub_r0i0_stage1_r <= 0;
            o_Rout_r <= 0;
            o_Iout_r <= 0;
            a_stage2_r <= 0;
            b_stage2_r <= 0;
            c_stage2_r <= 0;

        end
        else begin
            R0_stage1_r <= i_R0_r;
            I1_stage1_r <= i_I1_r;
            R1_stage1_r <= i_R1_r;
            i_R0_r <= i_R0;
            i_I0_r <= i_I0;
            i_R1_r <= i_R1;
            i_I1_r <= i_I1;
            add_r0i0_stage1_r <= add_r0i0_stage1_w;
            sub_i1r1_stage1_r <= sub_i1r1_stage1_w;
            sub_r0i0_stage1_r <= sub_r0i0_stage1_w;
            o_Rout_r <= o_Rout_w;
            o_Iout_r <= o_Iout_w;
            a_stage2_r <= a_stage1;
            b_stage2_r <= b_stage1;
            c_stage2_r <= c_stage1;

        end
    end
endmodule
*/
