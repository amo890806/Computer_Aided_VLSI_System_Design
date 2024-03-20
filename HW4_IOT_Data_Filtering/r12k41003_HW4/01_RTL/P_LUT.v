module P_LUT (
    input [31:0] din,
    output [31:0] dout
);
assign dout[31] = din[16];
assign dout[30] = din[25];
assign dout[29] = din[12];
assign dout[28] = din[11];
assign dout[27] = din[3];
assign dout[26] = din[20];
assign dout[25] = din[4];
assign dout[24] = din[15];
assign dout[23] = din[31];
assign dout[22] = din[17];
assign dout[21] = din[9];
assign dout[20] = din[6];
assign dout[19] = din[27];
assign dout[18] = din[14];
assign dout[17] = din[1];
assign dout[16] = din[22];
assign dout[15] = din[30];
assign dout[14] = din[24];
assign dout[13] = din[8];
assign dout[12] = din[18];
assign dout[11] = din[0];
assign dout[10] = din[5];
assign dout [9] = din[29];
assign dout [8] = din[23];
assign dout [7] = din[13];
assign dout [6] = din[19];
assign dout [5] = din[2];
assign dout [4] = din[26];
assign dout [3] = din[10];
assign dout [2] = din[21];
assign dout [1] = din[28];
assign dout [0] = din[7];
endmodule