module S1_BOX (
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
                0: data = 14; 
                1: data = 4;                
                2: data = 13;                
                3: data = 1;
                4: data = 2; 
                5: data = 15;                
                6: data = 11;                
                7: data = 8;
                8: data = 3; 
                9: data = 10;                
                10: data = 6;            
                11: data = 12;
                12: data = 5;
                13: data = 9;               
                14: data = 0;               
                15: data = 7;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 0; 
                1: data = 15;                
                2: data = 7;                
                3: data = 4;
                4: data = 14; 
                5: data = 2;                
                6: data = 13;                
                7: data = 1;
                8: data = 10; 
                9: data = 6;                
                10: data = 12;               
                11: data = 11;
                12: data = 9;
                13: data = 5;            
                14: data = 3;             
                15: data = 8; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 4; 
                1: data = 1;                
                2: data = 14;                
                3: data = 8;
                4: data = 13; 
                5: data = 6;                
                6: data = 2;                
                7: data = 11;
                8: data = 15; 
                9: data = 12;                
                10: data = 9;               
                11: data = 7;
                12: data = 3;
                13: data = 10;            
                14: data = 5;             
                15: data = 0;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 15; 
                1: data = 12;                
                2: data = 8;                
                3: data = 2;
                4: data = 4; 
                5: data = 9;                
                6: data = 1;                
                7: data = 7;
                8: data = 5; 
                9: data = 11;                
                10: data = 3;               
                11: data = 14;
                12: data = 10;
                13: data = 0;            
                14: data = 6;             
                15: data = 13;  
            endcase
        end
    endcase
end
    
endmodule