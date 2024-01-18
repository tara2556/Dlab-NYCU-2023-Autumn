`timescale 1ns / 1ps
module lab4(
           input  clk,            // System clock at 100 MHz
           input  reset_n,        // System reset signal, in negative logic
           input  [3:0] usr_btn,  // Four user pushbuttons
           output [3:0] usr_led   // Four yellow LEDs
       );
reg signed [3:0] temp_led;
wire mask_led;
wire [3:0] de_btn;
debouncing DB0(.button(usr_btn[0]), .clk(clk), .reset_n(reset_n), .db_button(de_btn[0]));
debouncing DB1(.button(usr_btn[1]), .clk(clk), .reset_n(reset_n), .db_button(de_btn[1]));
debouncing DB2(.button(usr_btn[2]), .clk(clk), .reset_n(reset_n), .db_button(de_btn[2]));
debouncing DB3(.button(usr_btn[3]), .clk(clk), .reset_n(reset_n), .db_button(de_btn[3]));

PWM_generator P0(.clk(clk), .increasing(de_btn[2]), .decreasing(de_btn[3]), .PWM_out(mask_led));
assign usr_led = temp_led & {4{mask_led}};
always @(posedge clk)
begin
    if(~reset_n)
    begin
        temp_led <= 0;

    end
    else
    begin
        if(de_btn[1] && temp_led<7)
        begin
            temp_led <= temp_led+1;

        end
        else if(de_btn[0] && temp_led>-8)
        begin
            temp_led <= temp_led-1;
        end
        else temp_led <= temp_led;
    end
end
endmodule

    module PWM_generator(input clk, increasing, decreasing, output PWM_out);
reg [2:0] PWM_counter = 0;
reg [4:0] sl_cycle = 0;
reg [4:0] DUTY [5:0];
initial
begin
    DUTY[0] = 5'd0;
    DUTY[1] = 5'd1;
    DUTY[2] = 5'd5;
    DUTY[3] = 5'd10;
    DUTY[4] = 5'd15;
    DUTY[5] = 5'd20;
end

always@(posedge clk)
begin
    sl_cycle <= (sl_cycle>=20)?0:sl_cycle + 1;
end

always@(posedge clk)
begin
    if(increasing && PWM_counter < 6)
    begin
        PWM_counter <= PWM_counter + 1;
    end
    else if(decreasing && PWM_counter > 0)
    begin
        PWM_counter <= PWM_counter - 1;
    end
end
assign PWM_out = (DUTY[PWM_counter] < sl_cycle)?1'b1:1'b0;
endmodule

    module debouncing(input button, clk, reset_n, output db_button);
wire sl_clk;
reg db;
slow_clk s0(.clk(clk), .sl_clk(sl_clk));
always@(posedge clk)
begin
    if(~reset_n) db <= 0;
    else
    begin
        if(db==1) db <= 0;
        else if(sl_clk && button) db <= 1;
    end
end
assign db_button = db;
endmodule

    module slow_clk(input clk, output sl_clk);
reg[27:0] counter = 249999;
always@(posedge clk)
begin
    counter <= (counter>=24999999)?0:counter+1;
end
assign sl_clk = (counter==24999999)?1'b1:1'b0;
endmodule

    module D_FF(input clk, sl_clk, D, output reg Q);
always@(posedge clk)
begin
    if(sl_clk == 1) Q <= D;
end
endmodule
