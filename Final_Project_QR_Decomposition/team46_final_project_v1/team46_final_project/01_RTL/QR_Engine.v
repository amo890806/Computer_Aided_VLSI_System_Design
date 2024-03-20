`timescale 1ns/1ps
module QR_Engine(
        input i_clk,
        input i_rst,
        input i_trig,
        input [47:0] i_data,
        output o_rd_vld,
        output o_last_data,
        output [159:0] o_y_hat,
        output [319:0] o_r    
);

// parameter
integer i,j;

// accuracy
parameter acc_wide = 16;
parameter acc_int = 4; // min: 4
parameter acc_int_comp = acc_int - 2;
parameter acc_frac_comp = 16 - (acc_wide - acc_int);

// main fsm
parameter s_START = 0;
parameter s_INPUT = 1;
parameter s_COMP = 2;
parameter s_PREREAD = 3;

// load fsm
parameter s_LOAD_H = 0;
parameter s_LOAD_S = 1;
parameter s_WAIT = 2;

// comp fsm
parameter s_IDLE = 0;
parameter s_LEN = 1;
parameter s_NORM = 2;
parameter s_DOT = 3;
parameter s_YHEAD = 4;
parameter s_FINISH = 5;

////////// reg and wire //////////

// fsm
reg [1:0] state_r, state_w;
reg [1:0] state_load_r, state_load_w;
reg [2:0] state_comp_r, state_comp_w;

// sram
reg [7:0] sram_addr  [0:2];
reg [7:0] sram_wdata [0:2];
wire [7:0] sram_rdata [0:2];
reg sram_read [0:2]; //1: read, 0: write
wire [acc_wide - 1:0] sram_data_real,sram_data_imag;

// counter
reg [7:0] cnt_addr_r, cnt_addr_w;
reg [7:0] read_addr; // delay 1 cycle form cnt_addr_r: the real addr of current sram_r_data
reg [3:0] cnt_data_r, cnt_data_w;
reg [1:0] cnt_iter_r, cnt_iter_w;
reg [2:0] cnt_dot_r, cnt_dot_w;

// data buffer //
reg [acc_wide - 1:0] H_real_buffer_r [0:3][0:3];
reg [acc_wide - 1:0] H_imag_buffer_r [0:3][0:3];
reg [acc_wide - 1:0] H_real_buffer_w [0:3][0:3];
reg [acc_wide - 1:0] H_imag_buffer_w [0:3][0:3];
reg [acc_wide - 1:0] Y_real_buffer_r [0:3];
reg [acc_wide - 1:0] Y_imag_buffer_r [0:3];
reg [acc_wide - 1:0] Y_real_buffer_w [0:3];
reg [acc_wide - 1:0] Y_imag_buffer_w [0:3];
reg [19:0] Y_hat_real_buffer_r [0:3];
reg [19:0] Y_hat_imag_buffer_r [0:3];
reg [19:0] Y_hat_real_buffer_w [0:3];
reg [19:0] Y_hat_imag_buffer_w [0:3];

reg [19:0] R_ii_buffer_r [0:3];
reg [19:0] R_ii_buffer_w [0:3];
reg [19:0] R_ij_real_buffer_r [0:5];
reg [19:0] R_ij_real_buffer_w [0:5];
reg [19:0] R_ij_imag_buffer_r [0:5];
reg [19:0] R_ij_imag_buffer_w [0:5];

reg [acc_wide + 1:0] vec_length_r, vec_length_w;

// other
reg if_input_y_r, if_input_y_w, comp_finish;

////////// sram //////////
genvar k;
generate
	for (k=0 ; k<3 ; k=k+1) begin: sram
	sram_256x8 s0 (
		.A(sram_addr[k]),
		.D(sram_wdata[k]),
		.CLK(i_clk),
		.CEN(1'b0), // TODO: clock gating
		.WEN(sram_read[k]),
		.Q(sram_rdata[k])
	);
	end
endgenerate

////////// comb logic //////////
// aram reading 
assign sram_data_imag = {{acc_int_comp{sram_rdata[2][7]}},sram_rdata[2],sram_rdata[1][7:4],2'b0}; // 
assign sram_data_real = {{acc_int_comp{sram_rdata[1][3]}},sram_rdata[1][3:0],sram_rdata[0],2'b0}; // 

// output
assign o_rd_vld = comp_finish;
assign o_last_data = (cnt_data_r == 9 && comp_finish);
assign o_y_hat = {Y_hat_imag_buffer_r[3],Y_hat_real_buffer_r[3],Y_hat_imag_buffer_r[2],Y_hat_real_buffer_r[2],Y_hat_imag_buffer_r[1],Y_hat_real_buffer_r[1],Y_hat_imag_buffer_r[0],Y_hat_real_buffer_r[0]};
assign o_r = {R_ii_buffer_r[3],R_ij_imag_buffer_r[5],R_ij_real_buffer_r[5],R_ij_imag_buffer_r[4],R_ij_real_buffer_r[4],R_ij_imag_buffer_r[2],R_ij_real_buffer_r[2],R_ii_buffer_r[2],R_ij_imag_buffer_r[3],R_ij_real_buffer_r[3],R_ij_imag_buffer_r[1],R_ij_real_buffer_r[1],R_ii_buffer_r[1],R_ij_imag_buffer_r[0],R_ij_real_buffer_r[0],R_ii_buffer_r[0]};

/*
R=[11 12 13 14
   21 22 23 24
   31 32 33 34
   41 42 43 44]
R_ii=[11 22 33 44]
R_ij=[12 13 14 23 24 34]
*/

///// modules /////
// normalizer
reg norm_start;
wire norm_finish;
wire [acc_wide - 1:0] Q_real [0:3];
wire [acc_wide - 1:0] Q_imag [0:3];
wire [19:0] norm_Rii;
normalizer 
#(
    .i_int (acc_int), // bits of integer part of input
    .i_wide (acc_wide),
    .i_length_int (acc_int + 2),
    .i_length_wide (acc_wide + 2),
    .o_int (acc_int), // bits of integer part of output
    .o_wide (acc_wide)
)
norm0
(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_length(vec_length_r),
    .i_real({H_real_buffer_r[0][cnt_iter_r],H_real_buffer_r[1][cnt_iter_r],H_real_buffer_r[2][cnt_iter_r],H_real_buffer_r[3][cnt_iter_r]}),
    .i_imag({H_imag_buffer_r[0][cnt_iter_r],H_imag_buffer_r[1][cnt_iter_r],H_imag_buffer_r[2][cnt_iter_r],H_imag_buffer_r[3][cnt_iter_r]}),
    .i_valid(norm_start),
    .o_real({Q_real[0],Q_real[1],Q_real[2],Q_real[3]}),
    .o_imag({Q_imag[0],Q_imag[1],Q_imag[2],Q_imag[3]}),
    .o_Rii(norm_Rii),
    .o_valid(norm_finish)
);
// dot and sub
reg dot_start;
wire dot_finish;
wire [(acc_wide << 2) - 1:0] dot_input_real1;
wire [(acc_wide << 2) - 1:0] dot_input_imag1;
wire [(acc_wide << 2) - 1:0] dot_input_real2;
wire [(acc_wide << 2) - 1:0] dot_input_imag2;
wire [acc_wide - 1:0] H_real [0:3];
wire [acc_wide - 1:0] H_imag [0:3];
wire [acc_wide + 1:0] dot_real;
wire [acc_wide + 1:0] dot_imag;

// assign input
assign dot_input_real1 =    (state_comp_r == s_NORM) ? {H_real_buffer_r[0][cnt_iter_r - 1],H_real_buffer_r[1][cnt_iter_r - 1],H_real_buffer_r[2][cnt_iter_r - 1],H_real_buffer_r[3][cnt_iter_r - 1]} :
                            {H_real_buffer_r[0][cnt_iter_r],H_real_buffer_r[1][cnt_iter_r],H_real_buffer_r[2][cnt_iter_r],H_real_buffer_r[3][cnt_iter_r]};
assign dot_input_imag1 =    (state_comp_r == s_NORM) ? {H_imag_buffer_r[0][cnt_iter_r - 1],H_imag_buffer_r[1][cnt_iter_r - 1],H_imag_buffer_r[2][cnt_iter_r - 1],H_imag_buffer_r[3][cnt_iter_r - 1]} :
                            {H_imag_buffer_r[0][cnt_iter_r],H_imag_buffer_r[1][cnt_iter_r],H_imag_buffer_r[2][cnt_iter_r],H_imag_buffer_r[3][cnt_iter_r]};

assign dot_input_real2 =    (state_comp_r == s_YHEAD) ? {Y_real_buffer_r[0],Y_real_buffer_r[1],Y_real_buffer_r[2],Y_real_buffer_r[3]} :
                            (state_comp_r == s_DOT || state_comp_r == s_NORM) ?   {H_real_buffer_r[0][cnt_dot_r[1:0]],H_real_buffer_r[1][cnt_dot_r[1:0]],H_real_buffer_r[2][cnt_dot_r[1:0]],H_real_buffer_r[3][cnt_dot_r[1:0]]} :
                                                        {H_real_buffer_r[0][cnt_iter_r],H_real_buffer_r[1][cnt_iter_r],H_real_buffer_r[2][cnt_iter_r],H_real_buffer_r[3][cnt_iter_r]};
assign dot_input_imag2 =    (state_comp_r == s_YHEAD) ? {Y_imag_buffer_r[0],Y_imag_buffer_r[1],Y_imag_buffer_r[2],Y_imag_buffer_r[3]} :
                            (state_comp_r == s_DOT || state_comp_r == s_NORM) ?   {H_imag_buffer_r[0][cnt_dot_r[1:0]],H_imag_buffer_r[1][cnt_dot_r[1:0]],H_imag_buffer_r[2][cnt_dot_r[1:0]],H_imag_buffer_r[3][cnt_dot_r[1:0]]} :
                                                        {H_imag_buffer_r[0][cnt_iter_r],H_imag_buffer_r[1][cnt_iter_r],H_imag_buffer_r[2][cnt_iter_r],H_imag_buffer_r[3][cnt_iter_r]};
dot_and_sub 
#(
    .i_int (acc_int), // bits of integer part of input
    .i_wide (acc_wide),
    .o_int (acc_int), // bits of integer part of output
    .o_wide (acc_wide),
    .o_dot_wide (acc_wide + 2)
)
dot0
(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_only_dot((state_comp_r != s_DOT) && (state_comp_r != s_NORM)),
    .i_real1(dot_input_real1),
    .i_imag1(dot_input_imag1),
    .i_real2(dot_input_real2),
    .i_imag2(dot_input_imag2),
    .i_valid(dot_start),
    .o_H_real({H_real[0],H_real[1],H_real[2],H_real[3]}),
    .o_H_imag({H_imag[0],H_imag[1],H_imag[2],H_imag[3]}),
    .o_dot_real(dot_real),
    .o_dot_imag(dot_imag),
    .o_valid(dot_finish)
);

//CG Condition
// // wire H_buffer_flag = (state_r == s_INPUT || state_r == s_COMP) || (state_comp_r == s_NORM || state_comp_r == s_DOT);
// // wire Y_buffer_flag = state_r == s_INPUT || state_load_r == s_LOAD_S;
// wire Y_hat_buffer_flag = (state_comp_r == s_YHEAD && dot_finish);
// wire R_ii_buffer_flag = (state_comp_r == s_NORM && norm_finish);
// wire R_ij_buffer_flag = (state_comp_r == s_NORM && !norm_finish && dot_finish) || (state_comp_r == s_DOT && dot_finish);
// wire cnt_addr_flag = state_r == s_INPUT || state_r == s_COMP;
// wire vec_length_flag = state_comp_r == s_LEN && dot_finish;
// // wire read_addr_flag_w = cnt_addr_flag;
// // reg read_addr_flag_r;

// reg H_buffer_flag;
// reg Y_buffer_flag;
// always @(*) begin
//     H_buffer_flag = 0;
//     if(state_r == s_INPUT && cnt_addr_r <= 15)begin
//         if (!if_input_y_r) begin
//             H_buffer_flag = 1;
//         end
//     end
//     else if(state_r == s_COMP)begin
//         if(state_load_r == s_LOAD_H)begin
//             H_buffer_flag = 1;
//         end
//     end

//     if(state_comp_r == s_NORM)begin
//         if (norm_finish) begin
//             H_buffer_flag = 1;
//         end else begin
//             if (dot_finish) begin
//                 H_buffer_flag = 1;
//             end
//         end
//     end
//     else if(state_comp_r == s_DOT)begin
//         if (dot_finish) begin
//             H_buffer_flag = 1;
//         end
//     end
// end

// always @(*) begin
//     Y_buffer_flag = 0;
//     if(state_r == s_INPUT && cnt_addr_r <= 15)begin
//         if (if_input_y_r) begin
//             Y_buffer_flag = 1;
//         end
//     end
//     else if(state_r == s_COMP)begin
//         if(state_load_r == s_LOAD_S)begin
//             Y_buffer_flag = 1;
//         end
//     end
// end

// wire gclk_H_buffer = i_clk & H_buffer_flag;
// wire gclk_Y_buffer = i_clk & Y_buffer_flag;
// wire gclk_Y_hat_buffer = i_clk & Y_hat_buffer_flag;
// wire gclk_Rii_buffer = i_clk & R_ii_buffer_flag;
// wire gclk_Rij_buffer = i_clk & R_ij_buffer_flag;
// wire gclk_cnt_addr = i_clk & cnt_addr_flag;
// wire gclk_vec_length = i_clk & vec_length_flag;
// // wire gclk_read_addr = i_clk & read_addr_flag_r;

///// main logic /////
always @(*) begin
    // default
    if_input_y_w = 0;
    sram_wdata[2] = i_data[47:40];
    sram_wdata[1] = {i_data[39:36],i_data[23:20]};
    sram_wdata[0] = i_data[19:12];
    for (i=0 ; i<3 ; i=i+1) begin
        sram_addr[i]  = cnt_addr_r;
        sram_read[i] = 1; // default: read
    end
    cnt_addr_w = cnt_addr_r;
    cnt_data_w = cnt_data_r;
    cnt_iter_w = cnt_iter_r;
    cnt_dot_w = cnt_dot_r;

    // data buffer default
    for (i=0 ; i<4 ; i=i+1) begin
        for (j=0 ; j<4 ; j=j+1) begin
            H_real_buffer_w[i][j] = H_real_buffer_r[i][j];
            H_imag_buffer_w[i][j] = H_imag_buffer_r[i][j];
        end
        Y_real_buffer_w[i] = Y_real_buffer_r[i];
        Y_imag_buffer_w[i] = Y_imag_buffer_r[i];
        Y_hat_real_buffer_w[i] = Y_hat_real_buffer_r[i];
        Y_hat_imag_buffer_w[i] = Y_hat_imag_buffer_r[i];
    end
    for (i=0 ; i<4 ; i=i+1) begin
        R_ii_buffer_w[i] = R_ii_buffer_r[i];
    end
    for (i=0 ; i<6 ; i=i+1) begin
        R_ij_real_buffer_w[i] = R_ij_real_buffer_r[i];
        R_ij_imag_buffer_w[i] = R_ij_imag_buffer_r[i];
    end

    // other
    state_load_w = state_load_r;
    state_comp_w = state_comp_r;
    norm_start = 0;
    dot_start = 0;
    comp_finish = 0;
    vec_length_w = vec_length_r;

    // FSM
    case (state_r)
        s_INPUT: begin
            if (i_trig) begin
                for (i=0 ; i<3 ; i=i+1) begin               
                    sram_read[i]  = 0; // write
                end
                if (cnt_addr_r[1:0] == 2'b11) begin
                    if (if_input_y_r) begin
                        if_input_y_w = 0;
                        for (i=0 ; i<3 ; i=i+1) begin
                            sram_addr[i]  = cnt_addr_r[7:2] + 160; // store y
                        end
                    end else begin
                        if_input_y_w = 1;
                    end
                end

                // pre-fetch
                if (cnt_addr_r <= 15) begin
                    if (!if_input_y_r) begin
                        H_imag_buffer_w[cnt_addr_r[3:2]][cnt_addr_r[1:0]] = {{acc_int_comp{i_data[47]}},i_data[47:36],2'b0};
                        H_real_buffer_w[cnt_addr_r[3:2]][cnt_addr_r[1:0]] = {{acc_int_comp{i_data[23]}},i_data[23:12],2'b0};
                    end else begin
                        Y_imag_buffer_w[cnt_addr_r[3:2]] = {{acc_int_comp{i_data[47]}},i_data[47:36],2'b0};
                        Y_real_buffer_w[cnt_addr_r[3:2]] = {{acc_int_comp{i_data[23]}},i_data[23:12],2'b0};
                    end
                end

                // counter

                if (cnt_addr_r[1:0] == 2'b11 && !if_input_y_r) begin
                    cnt_addr_w = cnt_addr_r;
                end else if (cnt_addr_r < 159) begin
                    cnt_addr_w = cnt_addr_r + 1;
                end else begin
                    cnt_addr_w = 0; // modifiable: which address to read first
                end
            end
        end
        s_COMP: begin
            case (state_load_r) // synopsys parallel_case
                s_LOAD_H: begin
                    // load H       
                    H_real_buffer_w[read_addr[1:0]][read_addr[3:2]] = sram_data_real;
                    H_imag_buffer_w[read_addr[1:0]][read_addr[3:2]] = sram_data_imag;

                    if (read_addr == 15) begin
                        state_load_w = s_LOAD_S;
                    end else begin
                        state_load_w = s_LOAD_H;
                    end

                    // counter
                    if (cnt_addr_r <= 15) begin
                        cnt_addr_w = cnt_addr_r + 1;
                        
                        for (i=0 ; i<3 ; i=i+1) begin
                            sram_addr[i]  = (cnt_data_r << 4) + (cnt_addr_r[1:0] << 2) + cnt_addr_r[3:2];
                        end
                    end else begin // cnt_addr_r == 16
                        cnt_addr_w = 1; 

                        for (i=0 ; i<3 ; i=i+1) begin
                            sram_addr[i]  = 160 + (cnt_data_r << 2) + (cnt_addr_r[1:0]);
                        end
                    end
                end
                s_LOAD_S: begin
                    // load Y
                    for (i=0 ; i<3 ; i=i+1) begin
                        sram_addr[i]  = 160 + (cnt_data_r << 2) + (cnt_addr_r[1:0]);
                    end
                    
                    Y_real_buffer_w[read_addr[1:0]] = sram_data_real;
                    Y_imag_buffer_w[read_addr[1:0]] = sram_data_imag;
                    if ((read_addr[2:0] == 3) && (cnt_addr_r == 3)) begin
                        state_load_w = s_WAIT;
                    end else begin // read_addr[2:0] == 4
                        state_load_w = s_LOAD_S;
                    end

                    // counter
                    if (cnt_addr_r < 3) begin
                        cnt_addr_w = cnt_addr_r + 1;
                    end else begin // cnt_addr_r == 3
                        cnt_addr_w = cnt_addr_r; // stop
                    end
                end
                s_WAIT: begin
                    // TODO
                    for (i=0 ; i<3 ; i=i+1) begin
                        sram_addr[i]  = (16 + (cnt_data_r << 4)); // pre-read
                    end
                    cnt_addr_w = 0;
                    if (o_rd_vld) begin // comp finish
                        if (cnt_data_r == 9) begin
                            cnt_data_w = 0;
                            cnt_addr_w = 0; // reload sram
                            state_load_w = s_WAIT;
                        end else begin
                            cnt_data_w = cnt_data_r + 1;
                            cnt_addr_w = 1; // pre-read
                            state_load_w = s_LOAD_H;
                        end
                        
                    end else begin
                        state_load_w = s_WAIT;
                    end
                    
                end

                default: begin
                    state_load_w = state_load_r;
                end
            endcase

            
        end
        default: begin
            cnt_addr_w = cnt_addr_r;
        end
    endcase

        /////////////////////////////////////////////////////////////////////////////////
    case (state_comp_r) // synopsys parallel_case
        s_IDLE: begin
            if ((state_load_r == s_LOAD_H && read_addr == 4) || (state_r == s_INPUT && read_addr == 12)) begin
                state_comp_w = s_LEN; // start comp
            end else begin
                state_comp_w = s_IDLE;
            end
        end
        s_LEN: begin
            // get dot of (H[iter],H*[iter])
            if (dot_finish) begin
                state_comp_w = s_NORM;
                vec_length_w = dot_real; // only take real part
            end else begin
                dot_start = 1;
                state_comp_w = s_LEN;
            end
        end
        s_NORM: begin
            // TODO: normalize and update H[iter] to q by vec_length
            
            if (norm_finish) begin
                state_comp_w = (cnt_iter_r == 3) ? s_YHEAD : s_DOT;
                cnt_iter_w = (cnt_iter_r == 3) ? 0 : cnt_iter_r;
                cnt_dot_w = cnt_iter_r + 1;
                for (i=0 ; i<4 ; i=i+1) begin
                    H_real_buffer_w[i][cnt_iter_r] = Q_real[i];
                    H_imag_buffer_w[i][cnt_iter_r] = Q_imag[i];
                end
                R_ii_buffer_w[cnt_iter_r] = norm_Rii;
            end else begin
                norm_start = 1;
                state_comp_w = s_NORM;

                if (dot_finish) begin
                    cnt_dot_w = cnt_dot_r + 1;

                    for (i=0 ; i<4 ; i=i+1) begin
                        H_real_buffer_w[i][cnt_dot_r] = H_real[i];
                        H_imag_buffer_w[i][cnt_dot_r] = H_imag[i];
                    end

                    R_ij_real_buffer_w[5] = {dot_real[(acc_wide + 1) - (acc_int + 2 - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}}; //shift new data into buffer
                    R_ij_imag_buffer_w[5] = {dot_imag[(acc_wide + 1) - (acc_int + 2 - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}}; 
                    for (i=0 ; i<5 ; i=i+1) begin
                        R_ij_real_buffer_w[i] = R_ij_real_buffer_r[i+1];
                        R_ij_imag_buffer_w[i] = R_ij_imag_buffer_r[i+1];
                    end  
                end else begin
                    if (cnt_dot_r[1]) // 2 or 3
                        dot_start = 1;
                    else
                        dot_start = 0;
                end
            end
        end
        s_DOT: begin
            // get dot of (H[iter],H*[dot]))
            if (dot_finish) begin
                /*
                if (cnt_dot_r == 3) begin
                    state_comp_w = s_LEN;
                    cnt_dot_w = cnt_iter_r + 2;
                    cnt_iter_w = cnt_iter_r + 1;
                end else begin
                    state_comp_w = s_DOT;
                    cnt_dot_w = cnt_dot_r + 1;
                end
                */
                state_comp_w = s_LEN;
                cnt_iter_w = cnt_iter_r + 1;
                cnt_dot_w = cnt_dot_r + 1;

                for (i=0 ; i<4 ; i=i+1) begin
                    H_real_buffer_w[i][cnt_dot_r] = H_real[i];
                    H_imag_buffer_w[i][cnt_dot_r] = H_imag[i];
                end

                R_ij_real_buffer_w[5] = {dot_real[(acc_wide + 1) - (acc_int + 2 - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}};  //shift new data into buffer
                R_ij_imag_buffer_w[5] = {dot_imag[(acc_wide + 1) - (acc_int + 2 - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}}; 
                for (i=0 ; i<5 ; i=i+1) begin
                    R_ij_real_buffer_w[i] = R_ij_real_buffer_r[i+1];
                    R_ij_imag_buffer_w[i] = R_ij_imag_buffer_r[i+1];
                end
                
            end else begin
                dot_start = 1;
                state_comp_w = s_DOT;
            end
        end
        s_YHEAD: begin 
            if (dot_finish) begin
                Y_hat_real_buffer_w[cnt_iter_r] = {dot_real[(acc_wide + 1) - (acc_int + 2 - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}};  // 
                Y_hat_imag_buffer_w[cnt_iter_r] = {dot_imag[(acc_wide + 1) - (acc_int + 2 - 4) -: (20 - acc_frac_comp)],{acc_frac_comp{1'b0}}}; 

                if (cnt_iter_r == 3) begin
                    state_comp_w = s_FINISH;
                    cnt_iter_w = 0;
                end else begin
                    state_comp_w = s_YHEAD;
                    cnt_iter_w = cnt_iter_r + 1;
                end
                
            end else begin
                dot_start = 1;
                state_comp_w = s_YHEAD;
            end
        end
        s_FINISH: begin
            // TODO
            comp_finish = 1;
            state_comp_w = s_IDLE;
            cnt_iter_w = 0;
            cnt_dot_w = 1;
        end
        default: begin
            state_comp_w = state_comp_r;
        end
    endcase
    
    


end

// state machine
always @(*) begin
    state_w = state_r;
    case (state_r)
        s_START: begin
            state_w = s_INPUT;
        end
        s_INPUT: begin
            if (cnt_addr_r == 159 && if_input_y_r) begin
                state_w = s_COMP;
            end else begin
                state_w = s_INPUT;
            end
        end
        s_COMP: begin
            if (cnt_data_r == 9 && comp_finish) begin // finish comp 10th data
                state_w = s_INPUT;
            end else begin
                state_w = s_COMP;
            end

        end
        default: begin
            state_w = state_r;
        end
    endcase
end

always @(posedge i_clk) begin
    for (i=0 ; i<4 ; i=i+1) begin
        for (j=0 ; j<4 ; j=j+1) begin
            H_real_buffer_r[i][j] <= H_real_buffer_w[i][j];
            H_imag_buffer_r[i][j] <= H_imag_buffer_w[i][j];
        end
    end
end

always @(posedge i_clk) begin
    for (i=0 ; i<4 ; i=i+1) begin
        Y_real_buffer_r[i] <= Y_real_buffer_w[i];
        Y_imag_buffer_r[i] <= Y_imag_buffer_w[i];
    end
end

always @(posedge i_clk) begin
    for (i=0 ; i<4 ; i=i+1) begin
        Y_hat_real_buffer_r[i] <= Y_hat_real_buffer_w[i];
        Y_hat_imag_buffer_r[i] <= Y_hat_imag_buffer_w[i];
    end
end

always @(posedge i_clk) begin
    for (i=0 ; i<4 ; i=i+1) begin
        R_ii_buffer_r[i] <= R_ii_buffer_w[i];
    end
end

always @(posedge i_clk) begin
    for (i=0 ; i<6 ; i=i+1) begin
        R_ij_real_buffer_r[i] <= R_ij_real_buffer_w[i];
        R_ij_imag_buffer_r[i] <= R_ij_imag_buffer_w[i];
    end
end

always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        cnt_addr_r <= 0;
    end
    else begin
        cnt_addr_r <= cnt_addr_w;
    end
end

always @(posedge i_clk) begin
    vec_length_r <= vec_length_w;
end

always @(posedge i_clk) begin
    read_addr <= cnt_addr_r;
end

////////// seq logic //////////
always @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        // fsm
        state_r <= s_START;
        state_load_r <= s_WAIT;
        state_comp_r <= s_IDLE;

        // counter
        // cnt_addr_r <= 0;
        cnt_data_r <= 0;
        cnt_iter_r <= 0;
        cnt_dot_r <= 1;
        // read_addr <= 0;

        // data buffer
        // for (i=0 ; i<4 ; i=i+1) begin
        //     for (j=0 ; j<4 ; j=j+1) begin
        //         H_real_buffer_r[i][j] <= 0;
        //         H_imag_buffer_r[i][j] <= 0;
        //     end
        //     Y_real_buffer_r[i] <= 0;
        //     Y_imag_buffer_r[i] <= 0;
        //     Y_hat_real_buffer_r[i] <= 0;
        //     Y_hat_imag_buffer_r[i] <= 0;
        // end
        // for (i=0 ; i<4 ; i=i+1) begin
        //     R_ii_buffer_r[i] <= 0;
        // end
        // for (i=0 ; i<6 ; i=i+1) begin
        //     R_ij_real_buffer_r[i] <= 0;
        //     R_ij_imag_buffer_r[i] <= 0;
        // end

        // other
        if_input_y_r <= 0;
        // vec_length_r <= 0;
        // read_addr_flag_r <= 0;

    end else begin
        // fsm
        state_r <= state_w;
        state_load_r <= state_load_w;
        state_comp_r <= state_comp_w;

        // counter
        // cnt_addr_r <= cnt_addr_w;
        cnt_data_r <= cnt_data_w;
        // read_addr <= cnt_addr_r;
        cnt_iter_r <= cnt_iter_w;
        cnt_dot_r <= cnt_dot_w;

        // data buffer
        // for (i=0 ; i<4 ; i=i+1) begin
        //     for (j=0 ; j<4 ; j=j+1) begin
        //         H_real_buffer_r[i][j] <= H_real_buffer_w[i][j];
        //         H_imag_buffer_r[i][j] <= H_imag_buffer_w[i][j];
        //     end
        //     Y_real_buffer_r[i] <= Y_real_buffer_w[i];
        //     Y_imag_buffer_r[i] <= Y_imag_buffer_w[i];
        //     Y_hat_real_buffer_r[i] <= Y_hat_real_buffer_w[i];
        //     Y_hat_imag_buffer_r[i] <= Y_hat_imag_buffer_w[i];
        // end
        // for (i=0 ; i<4 ; i=i+1) begin
        //     R_ii_buffer_r[i] <= R_ii_buffer_w[i];
        // end
        // for (i=0 ; i<6 ; i=i+1) begin
        //     R_ij_real_buffer_r[i] <= R_ij_real_buffer_w[i];
        //     R_ij_imag_buffer_r[i] <= R_ij_imag_buffer_w[i];
        // end

        // other
        if_input_y_r <= if_input_y_w;
        // vec_length_r <= vec_length_w;
        // read_addr_flag_r <= read_addr_flag_w;
    end
end
endmodule

/*
module normalizer (
    input i_clk,
    input i_rst,
    input [79:0] i_real, // {R0,R1,R2,R3}
    input [79:0] i_imag, // {I0,I1,I2,I3}
    input i_valid,
    output [79:0] o_real,
    output [79:0] o_imag,
    output [19:0] o_Rii,
    output o_valid
);
// input 1 vector (4 complex number)
// output 1 normalized vector (4 complex number) and Rii

endmodule

module compute_y_head (
    input i_clk,
    input i_rst,
    input [79:0] i_q1real,
    input [79:0] i_q1imag,
    input [79:0] i_q2real,
    input [79:0] i_q2imag,
    input [79:0] i_q3real,
    input [79:0] i_q3imag,
    input [79:0] i_q4real,
    input [79:0] i_q4imag,
    input [79:0] i_yreal,
    input [79:0] i_yimag,
    input i_valid,
    output [79:0] o_real,
    output [79:0] o_imag,
    output o_valid
);
// input Q matrix , 4 Q vector + y vector
// output y_head vector

endmodule
*/