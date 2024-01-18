`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/20 16:25:16
// Design Name: 
// Module Name: t_multiplexier
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module t_multiplexier(

    );
reg clk, enable;
reg [7:0] A, B;
wire [15:0] C;
SeqMultiplier sq1(.clk(clk),.enable(enable),
.A(A),.B(B),.C(C));

initial begin
    clk = 1;
    forever #5 clk = ~clk;
end
integer i;
initial begin
        for(i = 0; i < (1<<4); i= i+1) begin
        A = 0; B = 0;
        enable = 0;
        #20;
        A = (i<<2)+34;
        B = (i<<3)-i;
        
        #20;
        enable = 1;
        
        #100;
       end
end
endmodule
