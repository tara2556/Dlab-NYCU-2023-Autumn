`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/13 14:34:12
// Design Name: 
// Module Name: alu
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


module alu(
        input opcode, data, accum, clk, reset,
        output alu_out, zero
    );
    
  wire [7:0] alu_out;
  wire  [7:0] data, accum;
  wire  [2:0] opcode;
  wire zero;
  wire [7:0] mask;
  wire clk, reset;
  
  //reg
  
  reg [7:0] alu_o;
 
  //parameter
  
  parameter PASSA = 3'b000;
  parameter ADD = 3'b001;
  parameter SUB = 3'b010;
  parameter AND = 3'b011;
  parameter XOR = 3'b100;
  parameter ABS = 3'b101;
  parameter MUL = 3'b110;
  parameter PASSD = 3'b111;
  
  
  //assign
  
  assign alu_out = alu_o;
  assign zero = ~|(accum);
  
  always @(posedge clk) begin
    if(reset) begin
        alu_o <= 0;
    end
    else begin
        case(opcode)
             PASSA:
                alu_o <= accum;
             ADD:
                alu_o <= $signed(accum) + $signed(data);
             SUB:
                alu_o <= $signed(accum) - $signed(data);
             AND:
                alu_o <= accum & data;
             XOR:
                alu_o <= accum ^ data;
             ABS:
                alu_o <= (accum[7])?~(accum) + 1'b1:accum;
             MUL:
                alu_o <= $signed(accum) * $signed(data);
             PASSD:         
                alu_o <= data;
             default:
                alu_o <= 0;    
        endcase
    end
  end
   
  
endmodule
