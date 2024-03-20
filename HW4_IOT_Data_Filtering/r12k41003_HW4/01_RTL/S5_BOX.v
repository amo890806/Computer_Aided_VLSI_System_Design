module S5_BOX (
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
                0: data = 2; 
                1: data = 12;                
                2: data = 4;                
                3: data = 1;
                4: data = 7; 
                5: data = 10;                
                6: data = 11;                
                7: data = 6;
                8: data = 8; 
                9: data = 5;                
                10: data =3 ;            
                11: data =15 ;
                12: data =13 ;
                13: data =0 ;               
                14: data =14 ;               
                15: data =9 ;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 14; 
                1: data = 11;                
                2: data = 2;                
                3: data = 12;
                4: data = 4; 
                5: data = 7;                
                6: data = 13;                
                7: data = 1;
                8: data = 5; 
                9: data = 0;                
                10: data =15 ;               
                11: data =10 ;
                12: data =3 ;
                13: data =9 ;            
                14: data =8 ;             
                15: data =6 ; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 4; 
                1: data = 2;                
                2: data = 1;                
                3: data = 11;
                4: data = 10; 
                5: data = 13;                
                6: data = 7;                
                7: data = 8;
                8: data = 15; 
                9: data = 9;                
                10: data =12 ;               
                11: data =5 ;
                12: data =6 ;
                13: data =3 ;            
                14: data =0 ;             
                15: data =14 ;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 11; 
                1: data = 8;                
                2: data = 12;                
                3: data = 7;
                4: data = 1; 
                5: data = 14;                
                6: data = 2;                
                7: data = 13;
                8: data = 6; 
                9: data = 15;                
                10: data =0 ;               
                11: data =9 ;
                12: data =10 ;
                13: data =4 ;            
                14: data =5 ;             
                15: data =3 ;  
            endcase
        end
    endcase
end
    
endmodule