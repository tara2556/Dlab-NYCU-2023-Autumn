`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/20 15:34:47
// Design Name: 
// Module Name: t_fulladder1
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


module t_fulladder1;
reg [3:0] A, B;
reg Cin;
// outputs
wire [3:0] S;
wire Cout;
// Instantiate the Unit // Under Test (UUT)
fulladder1 uut(
.A(A),
.B(B),
.Cin(Cin), .S(S),
.Cout(Cout));
initial begin
// Initialize Inputs
A = 0; B = 0; Cin = 0;
// Wait 100 ns for global // reset to finish
#100;
// Add stimulus here
A = 4'b0101; B = 4'b1010; #50;
A = 4'b1111; B = 4'b0001; #50;
A = 4'b0000; B = 4'b1111; Cin = 1'b1;
#50;
A = 4'b0110; B = 4'b0001;
end 
endmodule
