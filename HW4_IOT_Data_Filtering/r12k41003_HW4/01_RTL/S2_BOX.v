module S2_BOX (
    input [5:0] din,
    output [3:0] dout
);

wire [1:0] row_sel;
wire [3:0] col_sel;
reg [3:0] data;

assign row_sel = {din[5], din[0]};
assign col_sel = din[4:1];
assign dout = data;

always @(*) begin
    case (row_sel)
        0: begin
            case (col_sel)
                0: data = 15; 
                1: data = 1;                
                2: data = 8;                
                3: data = 14;
                4: data = 6; 
                5: data = 11;                
                6: data = 3;                
                7: data = 4;
                8: data = 9; 
                9: data = 7;                
                10: data = 2;            
                11: data = 13;
                12: data = 12;
                13: data = 0;               
                14: data = 5;               
                15: data = 10;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 3; 
                1: data = 13;                
                2: data = 4;                
                3: data = 7;
                4: data = 15; 
                5: data = 2;                
                6: data = 8;                
                7: data = 14;
                8: data = 12; 
                9: data = 0;                
                10: data = 1;               
                11: data = 10;
                12: data = 6;
                13: data = 9;            
                14: data = 11;             
                15: data = 5; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 0; 
                1: data = 14;                
                2: data = 7;                
                3: data = 11;
                4: data = 10; 
                5: data = 4;                
                6: data = 13;                
                7: data = 1;
                8: data = 5; 
                9: data = 8;                
                10: data = 12;               
                11: data = 6;
                12: data = 9;
                13: data = 3;            
                14: data = 2;             
                15: data = 15;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 13; 
                1: data = 8;                
                2: data = 10;                
                3: data = 1;
                4: data = 3; 
                5: data = 15;                
                6: data = 4;                
                7: data = 2;
                8: data = 11; 
                9: data = 6;                
                10: data = 7;               
                11: data = 12;
                12: data = 0;
                13: data = 5;            
                14: data = 14;             
                15: data = 9;  
            endcase
        end
    endcase
end
    
endmodule