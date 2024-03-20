module S7_BOX (
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
                0: data = 4; 
                1: data = 11;                
                2: data = 2;                
                3: data = 14;
                4: data = 15; 
                5: data = 0;                
                6: data = 8;                
                7: data = 13;
                8: data = 3; 
                9: data = 12;                
                10: data =9 ;            
                11: data =7 ;
                12: data =5 ;
                13: data =10 ;               
                14: data =6 ;               
                15: data =1 ;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 13; 
                1: data = 0;                
                2: data = 11;                
                3: data = 7;
                4: data = 4; 
                5: data = 9;                
                6: data = 1;                
                7: data = 10;
                8: data = 14; 
                9: data = 3;                
                10: data =5 ;               
                11: data =12 ;
                12: data =2 ;
                13: data =15 ;            
                14: data =8 ;             
                15: data =6 ; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 1; 
                1: data = 4;                
                2: data = 11;                
                3: data = 13;
                4: data = 12; 
                5: data = 3;                
                6: data = 7;                
                7: data = 14;
                8: data = 10; 
                9: data = 15;                
                10: data =6 ;               
                11: data =8 ;
                12: data =0 ;
                13: data =5 ;            
                14: data =9 ;             
                15: data =2 ;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 6; 
                1: data = 11;                
                2: data = 13;                
                3: data = 8;
                4: data = 1; 
                5: data = 4;                
                6: data = 10;                
                7: data = 7;
                8: data = 9; 
                9: data = 5;                
                10: data =0 ;               
                11: data =15 ;
                12: data =14 ;
                13: data =2 ;            
                14: data =3 ;             
                15: data =12 ;  
            endcase
        end
    endcase
end
    
endmodule