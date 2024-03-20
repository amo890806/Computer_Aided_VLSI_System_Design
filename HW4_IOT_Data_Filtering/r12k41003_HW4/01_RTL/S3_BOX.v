module S3_BOX (
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
                0: data = 10; 
                1: data = 0;                
                2: data = 9;                
                3: data = 14;
                4: data = 6; 
                5: data = 3;                
                6: data = 15;                
                7: data = 5;
                8: data = 1; 
                9: data = 13;                
                10: data =12 ;            
                11: data =7 ;
                12: data =11 ;
                13: data =4 ;               
                14: data =2 ;               
                15: data =8 ;   
            endcase
        end
        1: begin
            case (col_sel)
                0: data = 13; 
                1: data = 7;                
                2: data = 0;                
                3: data = 9;
                4: data = 3; 
                5: data = 4;                
                6: data = 6;                
                7: data = 10;
                8: data = 2; 
                9: data = 8;                
                10: data =5 ;               
                11: data =14 ;
                12: data =12 ;
                13: data =11 ;            
                14: data =15 ;             
                15: data =1 ; 
            endcase
        end
        2: begin
            case (col_sel)
                0: data = 13; 
                1: data = 6;                
                2: data = 4;                
                3: data = 9;
                4: data = 8; 
                5: data = 15;                
                6: data = 3;                
                7: data = 0;
                8: data = 11; 
                9: data = 1;                
                10: data =2 ;               
                11: data =12 ;
                12: data =5 ;
                13: data =10 ;            
                14: data =14 ;             
                15: data =7 ;  
            endcase
        end
        3: begin
            case (col_sel)
                0: data = 1; 
                1: data = 10;                
                2: data = 13;                
                3: data = 0;
                4: data = 6; 
                5: data = 9;                
                6: data = 8;                
                7: data = 7;
                8: data = 4; 
                9: data = 15;                
                10: data =14 ;               
                11: data =3 ;
                12: data =11 ;
                13: data =5 ;            
                14: data =2 ;             
                15: data =12 ;  
            endcase
        end
    endcase
end
    
endmodule