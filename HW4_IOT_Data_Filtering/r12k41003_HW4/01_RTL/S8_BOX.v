module S8_BOX (
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
                0: data = 13; 
                1: data = 2;                
                2: data = 8;                
                3: data = 4;
                4: data = 6; 
                5: data = 15;                
                6: data = 11;                
                7: data = 1;
                8: data = 10; 
                9: data = 9;                
                10: data =3 ;            
                11: data =14 ;
                12: data =5 ;
                13: data =0 ;               
                14: data =12 ;               
                15: data =7 ;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 1; 
                1: data = 15;                
                2: data = 13;                
                3: data = 8;
                4: data = 10; 
                5: data = 3;                
                6: data = 7;                
                7: data = 4;
                8: data = 12; 
                9: data = 5;                
                10: data =6 ;               
                11: data =11 ;
                12: data =0 ;
                13: data =14 ;            
                14: data =9 ;             
                15: data =2 ; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 7; 
                1: data = 11;                
                2: data = 4;                
                3: data = 1;
                4: data = 9; 
                5: data = 12;                
                6: data = 14;                
                7: data = 2;
                8: data = 0; 
                9: data = 6;                
                10: data =10 ;               
                11: data =13 ;
                12: data =15 ;
                13: data =3 ;            
                14: data =5 ;             
                15: data =8 ;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 2; 
                1: data = 1;                
                2: data = 14;                
                3: data = 7;
                4: data = 4; 
                5: data = 10;                
                6: data = 8;                
                7: data = 13;
                8: data = 15; 
                9: data = 12;                
                10: data =9 ;               
                11: data =0 ;
                12: data =3 ;
                13: data =5 ;            
                14: data =6 ;             
                15: data =11 ;  
            endcase
        end
    endcase
end
    
endmodule