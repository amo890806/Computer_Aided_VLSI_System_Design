module S6_BOX (
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
                0: data = 12; 
                1: data = 1;                
                2: data = 10;                
                3: data = 15;
                4: data = 9; 
                5: data = 2;                
                6: data = 6;                
                7: data = 8;
                8: data = 0; 
                9: data = 13;                
                10: data =3 ;            
                11: data =4 ;
                12: data =14 ;
                13: data =7 ;               
                14: data =5 ;               
                15: data =11 ;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 10; 
                1: data = 15;                
                2: data = 4;                
                3: data = 2;
                4: data = 7; 
                5: data = 12;                
                6: data = 9;                
                7: data = 5;
                8: data = 6; 
                9: data = 1;                
                10: data =13 ;               
                11: data =14 ;
                12: data =0 ;
                13: data =11 ;            
                14: data =3 ;             
                15: data =8 ; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 9; 
                1: data = 14;                
                2: data = 15;                
                3: data = 5;
                4: data = 2; 
                5: data = 8;                
                6: data = 12;                
                7: data = 3;
                8: data = 7; 
                9: data = 0;                
                10: data =4 ;               
                11: data =10 ;
                12: data =1 ;
                13: data =13 ;            
                14: data =11 ;             
                15: data =6 ;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 4; 
                1: data = 3;                
                2: data = 2;                
                3: data = 12;
                4: data = 9; 
                5: data = 5;                
                6: data = 15;                
                7: data = 10;
                8: data = 11; 
                9: data = 14;                
                10: data =1 ;               
                11: data =7 ;
                12: data =6 ;
                13: data =0 ;            
                14: data =8 ;             
                15: data =13 ;  
            endcase
        end
    endcase
end
    
endmodule