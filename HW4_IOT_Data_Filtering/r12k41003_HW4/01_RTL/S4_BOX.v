module S4_BOX (
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
                0: data = 7; 
                1: data = 13;                
                2: data = 14;                
                3: data = 3;
                4: data = 0; 
                5: data = 6;                
                6: data = 9;                
                7: data = 10;
                8: data = 1; 
                9: data = 2;                
                10: data =8 ;            
                11: data =5 ;
                12: data =11 ;
                13: data =12 ;               
                14: data =4 ;               
                15: data =15 ;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 13; 
                1: data = 8;                
                2: data = 11;                
                3: data = 5;
                4: data = 6; 
                5: data = 15;                
                6: data = 0;                
                7: data = 3;
                8: data = 4; 
                9: data = 7;                
                10: data =2 ;               
                11: data =12 ;
                12: data =1 ;
                13: data =10 ;            
                14: data =14 ;             
                15: data =9 ; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 10; 
                1: data = 6;                
                2: data = 9;                
                3: data = 0;
                4: data = 12; 
                5: data = 11;                
                6: data = 7;                
                7: data = 13;
                8: data = 15; 
                9: data = 1;                
                10: data =3 ;               
                11: data =14 ;
                12: data =5 ;
                13: data =2 ;            
                14: data =8 ;             
                15: data =4 ;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 3; 
                1: data = 15;                
                2: data = 0;                
                3: data = 6;
                4: data = 10; 
                5: data = 1;                
                6: data = 13;                
                7: data = 8;
                8: data = 9; 
                9: data = 4;                
                10: data =5 ;               
                11: data =11 ;
                12: data =12 ;
                13: data =7 ;            
                14: data =2 ;             
                15: data =14 ;  
            endcase
        end
    endcase
end
    
endmodule